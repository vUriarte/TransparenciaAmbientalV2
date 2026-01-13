import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("HeatmapWeightNormalizer strategies and transforms")
struct HeatmapWeightNormalizerTests {

    // Constrói focos sintéticos com FRPs dados
    private func focuses(_ frps: [Double]) -> [FireFocus] {
        frps.enumerated().map { idx, v in
            FireFocus(
                id: "f\(idx)",
                coordinate: CLLocationCoordinate2D(latitude: -10.0 + Double(idx) * 0.01, longitude: -50.0),
                satelite: nil,
                municipio: nil,
                estado: nil,
                numeroDiasSemChuva: nil,
                riscoFogo: nil,
                bioma: nil,
                frp: v
            )
        }
    }

    @Test("Fixed divisor + linear")
    func fixedDivisorLinear() throws {
        let fs = focuses([0, 50, 100, 200])
        let points = HeatmapWeightNormalizer.weights(
            from: fs,
            floor: 0.02,
            ceiling: 1.0,
            strategy: .fixedDivisor(200),
            transform: .linear
        )
        // Esperado: [0/200, 50/200, 100/200, 200/200] com piso 0.02
        let ws = points.map { Double($0.weight) }
        #expect(ws[0] == 0.02)            // piso aplicado
        #expect(abs(ws[1] - 0.25) < 1e-6)
        #expect(abs(ws[2] - 0.5) < 1e-6)
        #expect(abs(ws[3] - 1.0) < 1e-6)
    }

    @Test("Fixed divisor + sqrt")
    func fixedDivisorSqrt() throws {
        let fs = focuses([0, 25, 100, 400])
        let points = HeatmapWeightNormalizer.weights(
            from: fs,
            floor: 0.02,
            ceiling: 1.0,
            strategy: .fixedDivisor(400),
            transform: .sqrt
        )
        // sqrt(FRP)/sqrt(400) => [0, 5/20, 10/20, 20/20] => [0, 0.25, 0.5, 1]
        let ws = points.map { Double($0.weight) }
        #expect(ws[0] == 0.02)            // piso aplicado
        #expect(abs(ws[1] - 0.25) < 1e-6)
        #expect(abs(ws[2] - 0.5) < 1e-6)
        #expect(abs(ws[3] - 1.0) < 1e-6)
    }

    @Test("Fixed divisor + log")
    func fixedDivisorLog() throws {
        let fs = focuses([0, 10, 100, 1000])
        let points = HeatmapWeightNormalizer.weights(
            from: fs,
            floor: 0.02,
            ceiling: 1.0,
            strategy: .fixedDivisor(1000),
            transform: .log
        )
        // log1p(FRP)/log1p(1000)
        let ws = points.map { Double($0.weight) }
        #expect(ws[0] == 0.02)                                // piso aplicado
        #expect(ws[3] <= 1.0)                                 // teto respeitado
        #expect(ws[2] < ws[3] && ws[1] < ws[2])               // ordem crescente
    }

    @Test("Quantile P90 + linear")
    func quantileLinear() throws {
        let fs = focuses([1, 2, 3, 4, 5, 100]) // outlier alto
        let points = HeatmapWeightNormalizer.weights(
            from: fs,
            floor: 0.02,
            ceiling: 1.0,
            strategy: .quantile(highPercentile: 0.9),
            transform: .linear
        )
        let ws = points.map { Double($0.weight) }

        // P90 deve ficar perto do maior valor não-outlier (aqui entre 5 e 100, mas como 100 é outlier,
        // o percentil 0.9 tende a algo alto; de todo modo, o último deve saturar em 1.0)
        let last = try #require(ws.last)
        #expect(last == 1.0)
        #expect(ws.first! >= 0.02)
        #expect(ws[0] < ws[1] && ws[1] < ws[2])
    }

    @Test("FRP ausente/zero respeita piso")
    func missingFRPUsesFloor() throws {
        let fs = [
            FireFocus(id: "a", coordinate: .init(latitude: 0, longitude: 0), frp: nil),
            FireFocus(id: "b", coordinate: .init(latitude: 0, longitude: 0), frp: 0)
        ]
        let points = HeatmapWeightNormalizer.weights(
            from: fs,
            floor: 0.03,
            ceiling: 1.0,
            strategy: .fixedDivisor(100),
            transform: .linear
        )
        let ws = points.map { Double($0.weight) }
        #expect(ws[0] == 0.03)
        #expect(ws[1] == 0.03)
    }
}
