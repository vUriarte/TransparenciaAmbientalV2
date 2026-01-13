import SwiftUI
import Combine

#if canImport(Charts)
import Charts
#endif

struct StatisticsView: View {
    @StateObject var viewModel: StatisticsViewModel
    @EnvironmentObject private var mapVM: MapContentViewModel

    @State private var selectedGroupTab: GroupTab = .state
    @State private var groupMetric: GroupMetric = .count
    @State private var seriesMetric: SeriesMetric = .count

    // Estados para apresentar seletores em sheet (sem indicador do dialog)
    @State private var showStateSheet = false
    @State private var showBiomeSheet = false
    @State private var showHelp = false

    enum GroupTab: String, CaseIterable, Identifiable {
        case state = "Estados"
        case biome = "Biomas"
        case municipio = "Municípios"
        var id: String { rawValue }
    }

    enum GroupMetric: String, CaseIterable, Identifiable {
        case count = "Qtde"
        case frp = "FRP"
        var id: String { rawValue }
    }

    enum SeriesMetric: String, CaseIterable, Identifiable {
        case count = "Qtde"
        case frp = "FRP Σ"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                StatisticsControlsView(
                    preset: $viewModel.preset,
                    stateLabel: viewModel.selectedState?.displayName ?? "Todos",
                    biomeLabel: viewModel.selectedBiome?.displayName ?? "Todos",
                    onTapState: { showStateSheet = true },
                    onTapBiome: { showBiomeSheet = true },
                    topN: $viewModel.topN,
                    orderBy: $viewModel.orderBy
                )

                if viewModel.isLoading {
                    ProgressView("Carregando…")
                        .padding()
                } else if let msg = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text(msg).foregroundColor(.red)
                        Button("Tentar novamente") {
                            Task { await viewModel.load() }
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        SummaryCardsView(summary: viewModel.summary)

                        GroupSectionView(
                            selectedGroupTab: $selectedGroupTab,
                            groupMetric: $groupMetric,
                            byState: viewModel.byState,
                            byBiome: viewModel.byBiome,
                            byMunicipio: viewModel.byMunicipio,
                            topN: viewModel.topN,
                            emptyTextProvider: emptyText
                        )

                        SeriesSectionView(
                            seriesMetric: $seriesMetric,
                            points: viewModel.series,
                            emptyTextProvider: emptyText,
                            startDate: viewModel.selectedStartDate,
                            endDate: viewModel.selectedEndDate
                        )
                    }
                }
            }
            .padding()
            .navigationTitle("Estatísticas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Ajuda")
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .onAppear {
            // Garante que os filtros iniciais espelham o mapa
            syncFromMap()
        }
        // Observa mudanças do mapa e replica localmente (sincronização contínua)
        .onReceive(mapVM.$selectedState.removeDuplicates()) { _ in
            syncFromMap()
        }
        .onReceive(mapVM.$selectedBiome.removeDuplicates()) { _ in
            syncFromMap()
        }
        // Sheets de seleção
        .sheet(isPresented: $showStateSheet) {
            StateSelectorSheetView(
                selected: viewModel.selectedState,
                onSelect: { st in
                    viewModel.selectedState = st
                    mapVM.selectedState = st
                    showStateSheet = false
                },
                onClose: { showStateSheet = false }
            )
        }
        .sheet(isPresented: $showBiomeSheet) {
            BiomeSelectorSheetView(
                selected: viewModel.selectedBiome,
                onSelect: { b in
                    viewModel.selectedBiome = b
                    mapVM.selectedBiome = b
                    showBiomeSheet = false
                },
                onClose: { showBiomeSheet = false }
            )
        }
        // Sheet de ajuda
        .sheet(isPresented: $showHelp) {
            NavigationView {
                StatisticsHelpView()
                    .navigationTitle("Ajuda")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fechar") { showHelp = false }
                        }
                    }
            }
        }
    }

    // MARK: - Sync helpers

    private func syncFromMap() {
        if viewModel.selectedState?.rawValue != mapVM.selectedState?.rawValue {
            viewModel.selectedState = mapVM.selectedState
        }
        if viewModel.selectedBiome?.rawValue != mapVM.selectedBiome?.rawValue {
            viewModel.selectedBiome = mapVM.selectedBiome
        }
    }

    // MARK: - UI helpers

    private func emptyText(_ s: String) -> some View {
        Text(s)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }
}

// Repositório simples para previews (evita await em init)
private struct PreviewRepository: StatisticsRepositoryProtocol {
    func focuses(for dates: [Date]) async throws -> [Date : [FireFocus]] { [:] }
    func storeFocuses(_ focuses: [FireFocus], for date: Date) async throws { }
    func purge(dates: [Date]) async throws { }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        // Usa PreviewRepository para evitar 'async' em criação
        let repo = PreviewRepository()
        let vm = StatisticsViewModel(
            repository: repo,
            engine: StatisticsEngine(),
            initialStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
            initialEndDate: Date()
        )
        vm.selectedState = .tocantins
        vm.selectedBiome = .cerrado
        return StatisticsView(viewModel: vm)
            .environmentObject(MapContentViewModel())
    }
}
