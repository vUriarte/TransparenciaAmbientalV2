import SwiftUI

struct MainTabView: View {
    @StateObject private var mapVM = MapContentViewModel()
    @State private var statisticsVM: StatisticsViewModel? = nil

    var body: some View {
        TabView {
            MapContentView(viewModel: mapVM)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }

            if let vm = statisticsVM {
                StatisticsView(viewModel: vm)
                    .tabItem {
                        Label("Estatísticas", systemImage: "chart.bar")
                    }
            } else {
                // Placeholder enquanto a factory async monta a ViewModel
                ProgressView("Carregando…")
                    .tabItem {
                        Label("Estatísticas", systemImage: "chart.bar")
                    }
            }
        }
        .task {
            if statisticsVM == nil {
                statisticsVM = await StatisticsModuleFactory.makeViewModel(
                    initialStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
                    initialEndDate: Date(),
                    inheritedState: mapVM.selectedState,
                    inheritedBiome: mapVM.selectedBiome
                )
            }
        }
        .environmentObject(mapVM)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
