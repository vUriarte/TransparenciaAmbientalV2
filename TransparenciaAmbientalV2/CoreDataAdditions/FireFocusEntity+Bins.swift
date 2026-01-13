import CoreLocation

extension FireFocusEntity {
    static func applyBins(_ obj: FireFocusEntity, from coordinate: CLLocationCoordinate2D, zoomLevelForPersist: Int = 14) {
        let (latB, lonB) = MapGrid.bin(for: coordinate, zoomLevel: zoomLevelForPersist)
        obj.latBin = latB
        obj.lonBin = lonB
    }
}