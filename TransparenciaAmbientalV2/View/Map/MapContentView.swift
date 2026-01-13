import SwiftUI
import MapKit
import CoreLocation

struct MapContentView: View {
    @StateObject private var viewModel: MapContentViewModel
    @State private var showHelp = false

    // Injeta a instância de ViewModel (compartilhada com o TabView)
    init(viewModel: MapContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // Mapa (UIKit + clustering + heatmap)
        ClusteredMapView(
            region: $viewModel.region,
            annotations: viewModel.annotations,
            heatmapPoints: viewModel.heatmapPoints
        )
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .overlay(alignment: .top) {
            StatusOverlay(state: $viewModel.state)
                .padding(.top, 8)
                .padding(.horizontal)
                .zIndex(1)
                .allowsHitTesting(true)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showHelp = true
            } label: {
                Label("Ajuda", systemImage: "questionmark.circle")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .padding(10)
                    .background(.bar, in: Circle())
                    .shadow(radius: 3)
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
            .accessibilityLabel("Ajuda do mapa")
        }
        // Painel de controles acima da Tab Bar
        .safeAreaInset(edge: .bottom) {
            ControlPanelView(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
        // Sheet de ajuda
        .sheet(isPresented: $showHelp) {
            NavigationView {
                MapHelpView()
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
}

#Preview {
    MapContentView(viewModel: MapContentViewModel())
}
