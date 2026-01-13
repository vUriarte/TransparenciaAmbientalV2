import Foundation

protocol StatisticsEngineProtocol {
    // Aplica filtros de Estado/Bioma antes de agregar
    func summarize(focuses: [FireFocus]) -> StatsSummary

    // Agrupamentos (Top N) por Estado/Bioma/Município
    func group(
        focuses: [FireFocus],
        by key: StatsGroupingKey,
        topN: Int,
        orderBy: GroupOrderBy
    ) -> [GroupStat]

    // Série temporal agregada por dia/semana/mês, preenchendo lacunas no intervalo [start, end]
    func timeSeries(
        focuses: [FireFocus],
        calendar: Calendar,
        start: Date,
        end: Date
    ) -> [TimePoint]
}
