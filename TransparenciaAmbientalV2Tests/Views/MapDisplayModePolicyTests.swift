import Testing
import MapKit
@testable import TransparenciaAmbientalV2

@Suite("MapDisplayModePolicy decision")
struct MapDisplayModePolicyTests {

    @Test("Usa heatmap quando latitudeDelta > threshold")
    func usesHeatmap() throws {
        let policy = MapDisplayModePolicy()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
        let mode = policy.mode(for: region, threshold: 8.0)
        #expect(mode == .heatmap)
    }

    @Test("Usa pins quando latitudeDelta <= threshold")
    func usesPins() throws {
        let policy = MapDisplayModePolicy()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
        let mode = policy.mode(for: region, threshold: 8.0)
        #expect(mode == .pins)
    }
}
