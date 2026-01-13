import Foundation
import MapKit
import UIKit
import os

#if DEBUG
private let memLog = OSLog(subsystem: "br.uriarte.transparencia", category: "mem")
private let renderLog = OSLog(subsystem: "br.uriarte.transparencia", category: "render")
#endif

@inline(__always)
private func currentMemoryMB() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<natural_t>.size)
    let kerr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    guard kerr == KERN_SUCCESS else { return -1 }
    return Double(info.resident_size) / (1024.0 * 1024.0)
}

final class HeatmapRenderer: MKOverlayRenderer {
    // Raio desejado em pontos de TELA (independente do zoom)
    var pointRadiusScreenPoints: CGFloat = 10

    var minAlpha: CGFloat = 0.03
    var maxAlpha: CGFloat = 0.25

    // "Borrão" pré-computado para desempenho
    private static var cachedBrush: CGImage?

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? HeatmapOverlay else { return }
        let points = overlay.points
        #if DEBUG
        let signpostID = OSSignpostID(log: renderLog)
        os_signpost(.begin, log: renderLog, name: "heatmap.draw", signpostID: signpostID, "zoomScale=%.6f points=%d", zoomScale, points.count)
        let t0 = CFAbsoluteTimeGetCurrent()
        var attempted = 0
        var drawn = 0
        #endif
        guard !points.isEmpty else { return }
        
        // Loga uso de memória antes de desenhar
        os_log("heatmap.render start mem=%.1fMB",
               log: memLog,
               type: .info,
               currentMemoryMB())

        context.saveGState()
        defer { context.restoreGState()
            // Loga uso de memória ao terminar
            os_log("heatmap.render end   mem=%.1fMB",
                   log: memLog,
                   type: .info,
                   currentMemoryMB())
        }

        // Blend aditivo para somar “calor”
        context.setBlendMode(.plusLighter)

        // Converte o raio desejado (em pontos de tela) para o espaço do contexto
        let baseRadiusInContext = max(1.0, pointRadiusScreenPoints / zoomScale)

        // Retângulo do tile no espaço do contexto
        let tileRectInContext = rect(for: mapRect)

        // Damping por zoom para controlar saturação em zoom muito aberto
        let zoomAlphaDamp = Self.alphaDamp(for: zoomScale)

        // Thinning opcional em zoom muito aberto (desenha só 1 a cada N pontos)
        let stride = Self.strideForZoom(zoomScale)

        // Brush radial pronto
        let brush = Self.brushImage()

        // Desenha ponto a ponto (sem binning)
//        if stride <= 1 {
//            for p in points {
//                draw(point: p,
//                     baseRadiusInContext: baseRadiusInContext,
//                     tileRectInContext: tileRectInContext,
//                     brush: brush,
//                     zoomAlphaDamp: zoomAlphaDamp,
//                     in: context)
//            }
//        } else {
//            for (i, p) in points.enumerated() where i % stride == 0 {
//                draw(point: p,
//                     baseRadiusInContext: baseRadiusInContext,
//                     tileRectInContext: tileRectInContext,
//                     brush: brush,
//                     zoomAlphaDamp: zoomAlphaDamp,
//                     in: context)
//            }
//        }
        if stride <= 1 {
            for p in points {
                attempted += 1
                if draw(point: p,
                        baseRadiusInContext: baseRadiusInContext,
                        tileRectInContext: tileRectInContext,
                        brush: brush,
                        zoomAlphaDamp: zoomAlphaDamp,
                        in: context) {
                    drawn += 1
                }
            }
        } else {
            for (i, p) in points.enumerated() where i % stride == 0 {
                attempted += 1
                if draw(point: p,
                        baseRadiusInContext: baseRadiusInContext,
                        tileRectInContext: tileRectInContext,
                        brush: brush,
                        zoomAlphaDamp: zoomAlphaDamp,
                        in: context) {
                    drawn += 1
                }
            }
        }
        #if DEBUG
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        os_signpost(.end, log: renderLog, name: "heatmap.draw", signpostID: signpostID, "attempted=%d drawn=%d stride=%d elapsed=%.3fs", attempted, drawn, stride, elapsed)
        #endif
    }

    @discardableResult
    private func draw(point p: HeatmapPoint,
                      baseRadiusInContext: CGFloat,
                      tileRectInContext: CGRect,
                      brush: CGImage,
                      zoomAlphaDamp: CGFloat,
                      in context: CGContext) -> Bool  {

        let mp = MKMapPoint(p.coordinate)
        let pt = point(for: mp)

        // Leve escala do raio pelo peso (pontos mais fortes, um pouco maiores)
        let radiusScale: CGFloat = 0.7 + 0.8 * max(0.0, min(1.0, p.weight))
        let radius = baseRadiusInContext * radiusScale
        let diameter = radius * 2.0

        let drawRect = CGRect(x: pt.x - radius, y: pt.y - radius, width: diameter, height: diameter)

        // Só desenha se houver interseção com o tile atual
        guard drawRect.intersects(tileRectInContext) else { return false}

        // Alpha final: mapeia peso -> intervalo e aplica damping por zoom
        let baseAlpha = minAlpha + (maxAlpha - minAlpha) * max(0.0, min(1.0, p.weight))
        let finalAlpha = max(0.0, min(1.0, baseAlpha * zoomAlphaDamp))

        // Cor pelo peso (rampa fria->quente)
        let color = Self.color(for: p.weight)

        drawBrush(brush, in: drawRect, color: color, alpha: finalAlpha, in: context)
        return true
    }

    // MARK: - Brush generation and drawing

    // Cria (e cacheia) um brush radial suave (centro forte -> borda transparente)
    private static func brushImage() -> CGImage {
        if let img = cachedBrush { return img }

        // Tamanho base do brush em pixels; será escalado conforme o drawRect
        let size = 256
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            fatalError("Não foi possível criar CGContext para o brush.")
        }

        // Gradiente radial branco -> transparente
        let colors: [CGColor] = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
            fatalError("Não foi possível criar CGGradient para o brush.")
        }

        let center = CGPoint(x: CGFloat(size) / 2.0, y: CGFloat(size) / 2.0)
        let radius = CGFloat(size) / 2.0

        ctx.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )

        guard let image = ctx.makeImage() else {
            fatalError("Não foi possível gerar imagem do brush.")
        }

        cachedBrush = image
        return image
    }

    // Desenha o brush no retângulo desejado, aplicando cor e alpha
    private func drawBrush(_ brush: CGImage, in rect: CGRect, color: UIColor, alpha: CGFloat, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        context.clip(to: rect, mask: brush)

        context.setFillColor(color.withAlphaComponent(alpha).cgColor)
        context.fill(rect)
    }

    // MARK: - Visual helpers

    // Mapeia peso (0..1) para uma rampa de cores fria->quente
    // 0.0 azul, 0.25 verde, 0.5 amarelo, 0.75 laranja, 1.0 vermelho
    private static func color(for weight: CGFloat) -> UIColor {
        let w = max(0.0, min(1.0, weight))

        switch w {
        case ..<0.25:
            // azul -> verde
            let t = w / 0.25
            return UIColor(
                red: 0.0 * (1 - t) + 0.0 * t,
                green: 0.2 * (1 - t) + 1.0 * t,
                blue: 1.0 * (1 - t) + 0.0 * t,
                alpha: 1.0
            )

        case ..<0.5:
            // verde -> amarelo
            let t = (w - 0.25) / 0.25
            return UIColor(
                red: 0.0 * (1 - t) + 1.0 * t,
                green: 1.0,
                blue: 0.0,
                alpha: 1.0
            )

        case ..<0.75:
            // amarelo -> laranja
            let t = (w - 0.5) / 0.25
            return UIColor(
                red: 1.0,
                green: 1.0 * (1 - t) + 0.55 * t,
                blue: 0.0,
                alpha: 1.0
            )

        default:
            // laranja -> vermelho
            let t = (w - 0.75) / 0.25
            return UIColor(
                red: 1.0,
                green: 0.55 * (1 - t) + 0.0 * t,
                blue: 0.0,
                alpha: 1.0
            )
        }
    }

    // Reduz alpha quando o zoom está muito aberto (zoomScale pequeno)
    private static func alphaDamp(for zoomScale: MKZoomScale) -> CGFloat {
        let scaled = zoomScale * 80_000.0
        // Mantém pelo menos 25% para ainda haver indicação em zoom muito aberto
        return max(0.25, min(1.0, scaled))
    }

    // Thinning opcional para desempenho em zoom muito aberto
    private static func strideForZoom(_ zoomScale: MKZoomScale) -> Int {
        switch zoomScale {
        case ..<2e-5:   return 3   // desenha 1 a cada 3 pontos
        case ..<5e-5:   return 2   // desenha 1 a cada 2 pontos
        default:        return 1
        }
    }
}
