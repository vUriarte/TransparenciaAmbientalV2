import Foundation
import CoreLocation

// Métricas agregadas de alto nível
struct StatsSummary: Equatable {
    let totalFocos: Int
    let frpSum: Double
    let frpAvg: Double?
    let frpMedian: Double?
    let frpP90: Double?
    let frpMax: Double?
}

// Métrica por grupo (Estado, Bioma, Município)
struct GroupStat: Equatable, Identifiable {
    var id: String { key }
    let key: String
    let count: Int
    let frpSum: Double
    let share: Double // participação relativa (0..1) no total do conjunto analisado
}

// Ponto de série temporal (agregado por dia/semana/mês)
struct TimePoint: Equatable, Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
    let frpSum: Double
}

// Preferências de agrupamento e ordenação
enum StatsGroupingKey {
    case state
    case biome
    case municipio
}

enum GroupOrderBy {
    case count
    case frpSum
}
