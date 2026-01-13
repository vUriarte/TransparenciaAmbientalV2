import Foundation
import CoreLocation

enum HeatmapNormalizationTransform {
    case linear
    case sqrt
    case log
}

enum HeatmapNormalizationStrategy: Equatable {
    case fixedDivisor(Double)                 // FRP / divisor
    case quantile(highPercentile: Double)     // FRP / P_high (ex.: 0.9 para P90)
}

struct HeatmapWeightNormalizer {

    static func weights(
        from focuses: [FireFocus],
        floor: CGFloat = 0.02,
        ceiling: CGFloat = 1.0,
        strategy: HeatmapNormalizationStrategy,
        transform: HeatmapNormalizationTransform = .linear
    ) -> [HeatmapPoint] {
        // Coleta FRPs válidos
        let frps = focuses.map { $0.frp ?? 0.0 }

        // Determina o normalizador base (divisor)
        let divisor: Double = {
            switch strategy {
            case .fixedDivisor(let d):
                return max(1e-9, d)
            case .quantile(let p):
                // Percentil alto da distribuição (ex.: 0.9 = P90)
                let q = max(0.5, min(0.999, p)) // evita extremos patológicos
                let val = percentile(frps, q: q)
                // Garante divisor mínimo para evitar divisão por zero
                return max(1e-9, val)
            }
        }()

        // Mapeia cada foco em HeatmapPoint com peso normalizado
        return focuses.map { f in
            let baseFRP = max(0.0, f.frp ?? 0.0)
            let transformed: Double = {
                switch transform {
                case .linear:
                    return baseFRP
                case .sqrt:
                    return sqrt(baseFRP)
                case .log:
                    // log1p para lidar bem com 0 e valores pequenos
                    return log1p(baseFRP)
                }
            }()

            let norm = transformed / transformedDivisor(divisor, transform: transform)
            let clamped = max(floor, min(ceiling, CGFloat(norm)))
            return HeatmapPoint(coordinate: f.coordinate, weight: clamped)
        }
    }

    // MARK: - Helpers

    // Ajusta o divisor conforme a transformação aplicada
    private static func transformedDivisor(_ divisor: Double, transform: HeatmapNormalizationTransform) -> Double {
        switch transform {
        case .linear:
            return divisor
        case .sqrt:
            return sqrt(divisor)
        case .log:
            return log1p(divisor)
        }
    }

    // Percentil simples (interp linear) para arrays pequenos/médios
    private static func percentile(_ values: [Double], q: Double) -> Double {
        let xs = values.sorted()
        guard !xs.isEmpty else { return 0.0 }
        let pos = (Double(xs.count) - 1.0) * q
        let lower = Int(floor(pos))
        let upper = Int(ceil(pos))
        if lower == upper { return xs[lower] }
        let weight = pos - Double(lower)
        return xs[lower] * (1.0 - weight) + xs[upper] * weight
    }
}
