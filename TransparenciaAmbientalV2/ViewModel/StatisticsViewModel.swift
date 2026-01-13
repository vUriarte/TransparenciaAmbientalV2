import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI
import os

@MainActor
final class StatisticsViewModel: ObservableObject {
    // Presets de período
    enum PeriodPreset: Int, CaseIterable, Identifiable {
        case d7 = 7, d15 = 15, d30 = 30
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .d7: return "7 dias"
            case .d15: return "15 dias"
            case .d30: return "30 dias"
            }
        }
    }

    // Entradas/estado da aba
    @Published var selectedStartDate: Date
    @Published var selectedEndDate: Date
    @Published var selectedState: BrazilianState?
    @Published var selectedBiome: Biome?
    @Published var topN: Int = 5
    @Published var orderBy: GroupOrderBy = .count
    @Published var preset: PeriodPreset = .d7 {
        didSet { applyPreset(preset) }
    }

    // Saídas agregadas
    @Published private(set) var summary: StatsSummary = StatsSummary(
        totalFocos: 0, frpSum: 0, frpAvg: nil, frpMedian: nil, frpP90: nil, frpMax: nil
    )
    @Published private(set) var byState: [GroupStat] = []
    @Published private(set) var byBiome: [GroupStat] = []
    @Published private(set) var byMunicipio: [GroupStat] = []
    @Published private(set) var series: [TimePoint] = []

    // Estado de carregamento básico
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // Dependências
    private let repository: StatisticsRepositoryProtocol
    private let engine: StatisticsEngineProtocol

    // Cache interno do último fetch por data
    private var lastFocusesByDate: [Date: [FireFocus]] = [:]

    // Combine
    private var cancellables = Set<AnyCancellable>()

    // Calendário UTC para normalização/bucketing
    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    #if DEBUG
    // Logger para benchmarks (prazos 7/15/30 e p95 de tempo de fetch/consulta)
    private let benchLogger = Logger(subsystem: "br.uriarte.transparencia", category: "bench")
    /// Executa mini-benchmarks para 7, 15 e 30 dias (N vezes cada) e imprime p50/p95 no console.
    /// DEBUG para coletar métricas para a seção de Resultados do TCC.
    func runPerfBenchmarks(runs: Int = 5) async {
        let presets: [PeriodPreset] = [.d7, .d15, .d30]
        for preset in presets {
            // Define janela [start, end] em UTC, alinhada à lógica já usada pelo ViewModel
            let end = utcCalendar.startOfDay(for: Date())
            let start = utcCalendar.date(byAdding: .day, value: -preset.rawValue + 1, to: end) ?? end
            let days = datesBetween(start: start, end: end, calendar: utcCalendar)

            // --- COLD: invalida cache (purge) e mede tempo com download necessário ---
            try? await repository.purge(dates: days)
            var cold: [Double] = []
            cold.reserveCapacity(max(1, runs))
            for i in 0..<max(1, runs) {
                let t0 = CFAbsoluteTimeGetCurrent()
                _ = try? await repository.focuses(for: days) // deverá fazer sync remoto
                let t1 = CFAbsoluteTimeGetCurrent()
                let elapsed = t1 - t0
                cold.append(t1 - t0)
                // Log de cada execução individual
                   benchLogger.info("bench.cold run=\(i+1) period=\(preset.rawValue) days=\(days.count) time=\(String(format: "%.3f", elapsed))s")

                try? await repository.purge(dates: days) // força "cold" a cada rodada
            }
            let coldSorted = cold.sorted()
            let coldCount = coldSorted.count
            let coldP50 = coldCount > 0 ? coldSorted[coldCount/2] : 0
            let coldP95Index = max(0, Int(round(0.95 * Double(max(1, coldCount - 1)))))
            let coldP95 = coldSorted.indices.contains(coldP95Index) ? coldSorted[coldP95Index] : (coldSorted.last ?? 0)
            benchLogger.info("bench.cold period=\(preset.rawValue) days=\(days.count) runs=\(runs) p50=\(String(format: "%.3f", coldP50))s p95=\(String(format: "%.3f", coldP95))s")

            // --- WARM: pré-carrega e mede tempo com cache preenchido ---
            // Primeiro, popula cache uma vez
            _ = try? await repository.focuses(for: days)
            var warm: [Double] = []
            warm.reserveCapacity(max(1, runs))
            for i in 0..<max(1, runs) {
                let t0 = CFAbsoluteTimeGetCurrent()
                _ = try? await repository.focuses(for: days) // cache Core Data
                let t1 = CFAbsoluteTimeGetCurrent()
                let elapsed = t1 - t0
                warm.append(t1 - t0)
                
                // Log de cada execução individual
                benchLogger.info("bench.warm run=\(i+1) period=\(preset.rawValue) days=\(days.count) time=\(String(format: "%.3f", elapsed))s")
            }
            let warmSorted = warm.sorted()
            let warmCount = warmSorted.count
            let warmP50 = warmCount > 0 ? warmSorted[warmCount/2] : 0
            let warmP95Index = max(0, Int(round(0.95 * Double(max(1, warmCount - 1)))))
            let warmP95 = warmSorted.indices.contains(warmP95Index) ? warmSorted[warmP95Index] : (warmSorted.last ?? 0)
            benchLogger.info("bench.warm period=\(preset.rawValue) days=\(days.count) runs=\(runs) p50=\(String(format: "%.3f", warmP50))s p95=\(String(format: "%.3f", warmP95))s")
        }
    }
    #endif

    
    
    init(
        repository: StatisticsRepositoryProtocol,
        engine: StatisticsEngineProtocol,
        initialStartDate: Date,
        initialEndDate: Date
    ) {
        self.repository = repository
        self.engine = engine
        self.selectedStartDate = initialStartDate
        self.selectedEndDate = initialEndDate

#if DEBUG
        // Para coletar métricas, descomentar a linha abaixo e rode o app em DEBUG.
         Task { await self.runPerfBenchmarks(runs: 10) }
#endif
        setupBindings()
    }

    // Carrega dados do repositório para o range atual e recomputa as saídas
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let (start, end) = normalizedDateRange(selectedStartDate, selectedEndDate)
            let days = datesBetween(start: start, end: end, calendar: utcCalendar)
            let data = try await repository.focuses(for: days)
            lastFocusesByDate = data
            recomputeOutputs()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            // Em caso de erro, mantém resultados anteriores (se houver)
        }
    }

    // Recalcula as métricas a partir do cache local e dos filtros/parâmetros atuais (sem refetch)
    func recomputeOutputs() {
        let all = lastFocusesByDate.values.flatMap { $0 }
        let filtered = FireFocusFilter.filter(all, state: selectedState, biome: selectedBiome)

        summary = engine.summarize(focuses: filtered)
        byState = engine.group(focuses: filtered, by: .state, topN: max(1, topN), orderBy: orderBy)
        byBiome = engine.group(focuses: filtered, by: .biome, topN: max(1, topN), orderBy: orderBy)
        byMunicipio = engine.group(focuses: filtered, by: .municipio, topN: max(1, topN), orderBy: orderBy)

        // Gera série contínua do início ao fim selecionados, garantindo que o dia atual esteja presente
        let (start, end) = normalizedDateRange(selectedStartDate, selectedEndDate)
        series = engine.timeSeries(
            focuses: filtered,
            calendar: utcCalendar,
            start: start,
            end: end
        )
    }

    // MARK: - Private

    private func setupBindings() {
        // Mudanças no período disparam novo fetch com debounce
        Publishers.CombineLatest($selectedStartDate, $selectedEndDate)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                guard let self else { return }
                Task { await self.load() }
            }
            .store(in: &cancellables)

        // Mudanças de filtros e parâmetros (sem refetch): recomputa
        let filterAndParamsPublishers: [AnyPublisher<Void, Never>] = [
            $selectedState.map { _ in () }.eraseToAnyPublisher(),
            $selectedBiome.map { _ in () }.eraseToAnyPublisher(),
            $topN.map { _ in () }.eraseToAnyPublisher(),
            $orderBy.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(filterAndParamsPublishers)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.recomputeOutputs()
            }
            .store(in: &cancellables)
    }

    private func normalizedDateRange(_ a: Date, _ b: Date) -> (Date, Date) {
        let start = utcCalendar.startOfDay(for: a)
        let end = utcCalendar.startOfDay(for: b)
        return start <= end ? (start, end) : (end, start)
    }

    private func datesBetween(start: Date, end: Date, calendar: Calendar) -> [Date] {
        guard start <= end else { return [] }
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = calendar.startOfDay(for: next)
        }
        return dates
    }

    // Aplica o preset ajustando selectedStartDate/selectedEndDate em UTC (startOfDay)
    private func applyPreset(_ p: PeriodPreset) {
        let end = utcCalendar.startOfDay(for: Date())
        let start = utcCalendar.date(byAdding: .day, value: -p.rawValue + 1, to: end) ?? end
        selectedStartDate = start
        selectedEndDate = end
    }
}
