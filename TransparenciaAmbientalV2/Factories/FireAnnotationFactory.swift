import Foundation
import MapKit

struct FireAnnotationFactory {
    static func make(from focus: FireFocus) -> FireAnnotation {
        FireAnnotation(focus: focus)
    }

    static func makeAll(from focuses: [FireFocus]) -> [FireAnnotation] {
        focuses.map { FireAnnotation(focus: $0) }
    }
}
