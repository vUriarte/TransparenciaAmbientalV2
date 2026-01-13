import SwiftUI
import MapKit
import CoreLocation

struct ControlPanelView: View {
    @ObservedObject var viewModel: MapContentViewModel

    @State private var activeSheet: ActiveSheet?

    // Controlar qual sheet está ativa
    private enum ActiveSheet: Identifiable {
        case state
        case biome

        var id: String {
            switch self {
            case .state: return "state"
            case .biome: return "biome"
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // 1) DatePill
            DatePill(date: $viewModel.selectedDate)
                .frame(maxWidth: .infinity)

            // 2) Filtros
            HStack(spacing: 8) {
                FilterPill(
                    title: "Estado",
                    value: viewModel.selectedState?.uf ?? "Todos",
                    systemImage: "mappin.and.ellipse",
                    action: { activeSheet = .state },
                    expandsHorizontally: true
                )

                FilterPill(
                    title: "Bioma",
                    value: viewModel.selectedBiome?.displayName ?? "Todos",
                    systemImage: "leaf",
                    action: { activeSheet = .biome },
                    expandsHorizontally: true
                )
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .state:
                    StateSelectorSheetView(
                        selected: viewModel.selectedState,
                        onSelect: { st in
                            viewModel.selectedState = st
                            viewModel.applyFiltersAndRefocus()
                            activeSheet = nil
                        },
                        onClose: { activeSheet = nil }
                    )
                case .biome:
                    BiomeSelectorSheetView(
                        selected: viewModel.selectedBiome,
                        onSelect: { biome in
                            viewModel.selectedBiome = biome
                            viewModel.applyFiltersAndRefocus()
                            activeSheet = nil
                        },
                        onClose: { activeSheet = nil }
                    )
                }
            }

            if viewModel.selectedState != nil || viewModel.selectedBiome != nil {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.secondary)
                    Text(activeFiltersSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            // 3) Reset filtros e Limpar dados
            HStack(spacing: 12) {
                Button {
                    withAnimation { viewModel.resetFilters() }
                } label: {
                    Label("Reset filtros", systemImage: "arrow.uturn.backward")
                        .labelStyle(ButtonPillLabelPStyle())
                }
                .buttonStyle(ButtonPillStyle())
                .tint(.accentColor)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.selectedState == nil && viewModel.selectedBiome == nil)

                Button {
                    withAnimation {
                        viewModel.focuses.removeAll()
                        viewModel.resetFilters()
                        viewModel.state = .idle
                        viewModel.region = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253),
                            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
                        )
                    }
                } label: {
                    Label("Limpar dados", systemImage: "trash")
                        .labelStyle(ButtonPillLabelPStyle())
                }
                .buttonStyle(ButtonPillStyle())
                .tint(.red)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.focuses.isEmpty)
            }

            // 4) Focos centralizado e Baixar dados
            VStack(alignment: .center, spacing: 8) {
                Text("Focos: \(viewModel.filteredFocuses.count)")
                    .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    Task { await viewModel.downloadData() }
                } label: {
                    Label("Baixar dados", systemImage: "arrow.down.circle")
                        .labelStyle(ButtonPillLabelPStyle())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ButtonPillStyle())
                .tint(.accentColor)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 5)
    }

    private var activeFiltersSubtitle: String {
        switch (viewModel.selectedState, viewModel.selectedBiome) {
        case (nil, nil):
            return ""
        case (let st?, nil):
            return "Filtrando: \(st.uf)"
        case (nil, let bio?):
            return "Filtrando: \(bio.displayName)"
        case (let st?, let bio?):
            return "Filtrando: \(st.uf) • \(bio.displayName)"
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ControlPanelView(viewModel: MapContentViewModel())
}
