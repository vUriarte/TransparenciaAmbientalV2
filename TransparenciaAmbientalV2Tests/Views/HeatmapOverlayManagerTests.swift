import Testing
import MapKit
@testable import TransparenciaAmbientalV2

@Suite("HeatmapOverlayManager overlay and renderer")
struct HeatmapOverlayManagerTests {

    @Test("Cria overlay e atualiza pontos")
    @MainActor
    func createsOverlayAndUpdates() throws {
        let map = MKMapView()
        let cfg = HeatmapConfig(pointRadiusScreenPoints: 10, minAlpha: 0.05, maxAlpha: 0.5)
        let manager = HeatmapOverlayManager(config: cfg)

        let points: [HeatmapPoint] = [
            .init(coordinate: .init(latitude: -10, longitude: -50), weight: 0.5),
            .init(coordinate: .init(latitude: -11, longitude: -51), weight: 1.0)
        ]

        // Ensure overlay
        manager.ensureOverlay(on: map, with: points)
        #expect(map.overlays.contains { $0 is HeatmapOverlay })

        // Update points should keep overlay present
        manager.updatePoints(on: map, points: points)
        #expect(map.overlays.contains { $0 is HeatmapOverlay })

        // Renderer should be HeatmapRenderer with config when requested
        guard let overlay = map.overlays.first else {
            Issue.record("Expected overlay")
            return
        }
        let renderer = manager.makeRenderer(for: overlay)
        #expect(renderer is HeatmapRenderer)
    }
}
