import MapKit

extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion, epsilon: CLLocationDegrees = 0.0001) -> Bool {
        abs(center.latitude - other.center.latitude) < epsilon &&
        abs(center.longitude - other.center.longitude) < epsilon &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < epsilon &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < epsilon
    }
}
