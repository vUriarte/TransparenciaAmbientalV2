import Testing
import MapKit
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("MapRegionCalculator region fitting and clamping")
struct MapRegionCalculatorTests {

    @Test("Retorna fallback quando não há coordenadas")
    func returnsFallbackOnEmpty() throws {
        let fallback = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
        let emptyCoords: [CLLocationCoordinate2D] = []
        let regionOpt = MapRegionCalculator.region(fitting: emptyCoords, fallback: fallback)
        let region = try #require(regionOpt)

        #expect(region.center.latitude == fallback.center.latitude)
        #expect(region.center.longitude == fallback.center.longitude)
        #expect(region.span.latitudeDelta == fallback.span.latitudeDelta)
        #expect(region.span.longitudeDelta == fallback.span.longitudeDelta)
    }

    @Test("Calcula bounding box simples com padding")
    func computesBoundingBox() throws {
        let coords = [
            CLLocationCoordinate2D(latitude: -10, longitude: -50),
            CLLocationCoordinate2D(latitude: -9, longitude: -49.5)
        ]
        let r = try #require(MapRegionCalculator.region(
            fitting: coords,
            paddingFactor: 1.0, // sem padding para facilitar a asserção
            minDelta: 0.0,
            maxDelta: 100.0
        ))
        // Centro é a média
        #expect(abs(r.center.latitude - (-9.5)) < 1e-9)
        #expect(abs(r.center.longitude - (-49.75)) < 1e-9)
        // Span é a diferença (sem padding)
        #expect(abs(r.span.latitudeDelta - 1.0) < 1e-9)
        #expect(abs(r.span.longitudeDelta - 0.5) < 1e-9)
    }

    @Test("Respeita minDelta e maxDelta")
    func clampsDeltas() throws {
        let tiny = [
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            CLLocationCoordinate2D(latitude: 0.0001, longitude: 0.0001)
        ]
        let rMin = try #require(MapRegionCalculator.region(
            fitting: tiny,
            paddingFactor: 1.0,
            minDelta: 0.5,
            maxDelta: 60.0
        ))
        #expect(rMin.span.latitudeDelta >= 0.5)
        #expect(rMin.span.longitudeDelta >= 0.5)

        let huge = [
            CLLocationCoordinate2D(latitude: -80, longitude: -170),
            CLLocationCoordinate2D(latitude: 80, longitude: 170)
        ]
        let rMax = try #require(MapRegionCalculator.region(
            fitting: huge,
            paddingFactor: 2.0,
            minDelta: 0.0,
            maxDelta: 10.0
        ))
        #expect(rMax.span.latitudeDelta <= 10.0)
        #expect(rMax.span.longitudeDelta <= 10.0)
    }
}
