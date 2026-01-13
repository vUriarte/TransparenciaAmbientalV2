import Foundation
import CoreLocation
import MapKit

enum MapGrid {
    static func scale(for zoomLevel: Int) -> Double {
        switch zoomLevel {
        case ..<5: return 1      
        case 5..<7: return 2
        case 7..<9: return 4
        case 9..<11: return 8
        case 11..<13: return 16
        case 13..<15: return 32
        default: return 64
        }
    }

    static func bin(for coordinate: CLLocationCoordinate2D, zoomLevel: Int) -> (Int16, Int16) {
        let s = scale(for: zoomLevel)
        let latBin = Int16(floor((coordinate.latitude + 90.0) * s))
        let lonBin = Int16(floor((coordinate.longitude + 180.0) * s))
        return (latBin, lonBin)
    }

    static func bins(in region: MKCoordinateRegion, zoomLevel: Int) -> (ClosedRange<Int16>, ClosedRange<Int16>) {
        let s = scale(for: zoomLevel)
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let latRange = Int16(floor((minLat + 90.0) * s))...Int16(floor((maxLat + 90.0) * s))
        let lonRange = Int16(floor((minLon + 180.0) * s))...Int16(floor((maxLon + 180.0) * s))
        return (latRange, lonRange)
    }
}