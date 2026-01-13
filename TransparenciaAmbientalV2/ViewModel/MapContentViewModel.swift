import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class MapContentViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @Published var focuses: [FireFocus] = []

    // MKCoordinateRegion para o MKMapView
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253),
        span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
    )

    @Published var state: LoadState = .idle

    // Filtros fixos
    @Published var selectedState: BrazilianState? = nil
    @Published var selectedBiome: Biome? = nil

    // Configuração do Heatmap (exposta para permitir ajustes futuros pela UI)
    @Published var heatmapStrategy: HeatmapNormalizationStrategy = .quantile(highPercentile: 0.9)
    @Published var heatmapTransform: HeatmapNormalizationTransform = .sqrt
    @Published var heatmapFloor: CGFloat = 0.02
    @Published var heatmapCeiling: CGFloat = 1.0

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    private let service: FireDataServiceProtocol

    init(service: FireDataServiceProtocol = FireDataService()) {
        self.service = service
    }

    // Focos filtrados por estado e bioma selecionados (quando houver)
    var filteredFocuses: [FireFocus] {
        FireFocusFilter.filter(focuses, state: selectedState, biome: selectedBiome)
    }

    // Anotações para o MKMapView (derivadas dos focos filtrados)
    var annotations: [FireAnnotation] {
        FireAnnotationFactory.makeAll(from: filteredFocuses)
    }

    // Pontos do Heatmap (derivados dos focos filtrados)
    var heatmapPoints: [HeatmapPoint] {
        HeatmapWeightNormalizer.weights(
            from: filteredFocuses,
            floor: heatmapFloor,
            ceiling: heatmapCeiling,
            strategy: heatmapStrategy,
            transform: heatmapTransform
        )
    }

    func downloadData() async {
        // Limpa dados antigos imediatamente para “limpar a tela”
        focuses.removeAll()

        state = .loading
        do {
            let csv = try await service.fetchCSV(for: selectedDate)
            let parsed = CSVParser.parseCSV(csv)

            // Usa o mapper para transformar todas as linhas em FireFocus
            let items = FireFocusRowMapper.mapAll(headers: parsed.headers, rows: parsed.rows)

            self.focuses = items

            // Ajusta câmera com base nos focos filtrados (respeita filtros)
            updateRegionToFitAll(using: filteredFocuses)

            let total = filteredFocuses.count
            let message = items.isEmpty
                ? FocusStatusFormatter.emptyMessage
                : FocusStatusFormatter.exhibitMessage(total: total, state: selectedState, biome: selectedBiome)
            state = .success(message)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func updateRegionToFitAll(using focuses: [FireFocus]? = nil) {
        let points = focuses ?? self.focuses

        // Região padrão (Brasil) quando não há pontos
        let fallback = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )

        let coords = points.map { $0.coordinate }
        let computed = MapRegionCalculator.region(
            fitting: coords,
            paddingFactor: 1.3,
            minDelta: 0.5,
            maxDelta: 60,
            fallback: fallback
        )
        if let computed {
            region = computed
        } else {
            region = fallback
        }
    }

    func applyFiltersAndRefocus() {
        withAnimation {
            updateRegionToFitAll(using: filteredFocuses)
        }
        let total = filteredFocuses.count
        let message = FocusStatusFormatter.exhibitMessage(total: total, state: selectedState, biome: selectedBiome)
        state = .success(message)
    }

    // Reset dos filtros (Estado e Bioma) e reenquadramento
    func resetFilters() {
        selectedState = nil
        selectedBiome = nil
        applyFiltersAndRefocus()
    }
}
