import Foundation
import MapKit

struct HeatmapPoint {
    let coordinate: CLLocationCoordinate2D
    let weight: CGFloat // 0...1 
}

final class HeatmapOverlay: NSObject, MKOverlay {
    // Dados do heatmap (coordenadas + peso)
    var points: [HeatmapPoint]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    var boundingMapRect: MKMapRect {
        MKMapRect.world
    }

    init(points: [HeatmapPoint]) {
        self.points = points
        super.init()
    }
}
