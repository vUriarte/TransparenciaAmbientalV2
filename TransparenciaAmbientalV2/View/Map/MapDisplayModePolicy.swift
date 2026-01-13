import Foundation
import MapKit

enum MapDisplayMode {
    case heatmap
    case pins
}

struct MapDisplayModePolicy {
    // Política simples baseada no latitudeDelta
    func mode(for region: MKCoordinateRegion, threshold: CLLocationDegrees) -> MapDisplayMode {
        region.span.latitudeDelta > threshold ? .heatmap : .pins
    }
}
