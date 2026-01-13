import Foundation
import MapKit

struct MapConfig {
    var mapType: MKMapType = .standard
    var showsCompass: Bool = false
    var pointOfInterestFilter: MKPointOfInterestFilter = .excludingAll
    var cameraMaxCenterCoordinateDistance: CLLocationDistance = 15_000_000

    // Threshold para alternar entre heatmap e pins (latitudeDelta)
    var heatmapLatitudeDeltaThreshold: CLLocationDegrees = 8.0

    // Epsilon para comparação aproximada de regiões
    var regionApproxEpsilon: CLLocationDegrees = 0.0001
}
