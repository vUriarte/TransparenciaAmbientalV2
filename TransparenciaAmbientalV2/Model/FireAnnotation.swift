import Foundation
import MapKit

final class FireAnnotation: NSObject, MKAnnotation {
    let focusID: String
    let coordinate: CLLocationCoordinate2D
    let titleText: String?
    let subtitleText: String?
    let focus: FireFocus
    // MKAnnotation
    var title: String? { titleText }
    var subtitle: String? { subtitleText }    

    init(focus: FireFocus) {
        self.focus = focus
        self.focusID = focus.id
        self.coordinate = focus.coordinate

        self.titleText = focus.municipio ?? "Foco de queimada"
        if let estado = focus.estado, let bioma = focus.bioma {
            self.subtitleText = "\(estado) • \(bioma)"
        } else if let estado = focus.estado {
            self.subtitleText = estado
        } else if let bioma = focus.bioma {
            self.subtitleText = bioma
        } else {
            self.subtitleText = nil
        }

        super.init()
    }
}
