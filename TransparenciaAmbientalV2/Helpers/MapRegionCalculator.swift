import Foundation
import MapKit
import CoreLocation

struct MapRegionCalculator {

    /// Calcula uma região que engloba todas as coordenadas fornecidas, aplicando padding e limites de delta.
    /// - Parameters:
    ///   - coordinates: Lista de coordenadas a enquadrar.
    ///   - paddingFactor: Fator multiplicador sobre o span calculado (ex.: 1.3).
    ///   - minDelta: Delta mínimo para evitar zoom excessivo.
    ///   - maxDelta: Delta máximo para evitar zoom muito aberto.
    ///   - fallback: Região a retornar quando não há coordenadas (opcional).
    /// - Returns: Uma MKCoordinateRegion ou `fallback`/nil quando não há coordenadas.
    static func region(
        fitting coordinates: [CLLocationCoordinate2D],
        paddingFactor: Double = 1.3,
        minDelta: CLLocationDegrees = 0.5,
        maxDelta: CLLocationDegrees = 60,
        fallback: MKCoordinateRegion? = nil
    ) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return fallback }

        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )

        var span = MKCoordinateSpan(
            latitudeDelta: max(minDelta, (maxLat - minLat) * paddingFactor),
            longitudeDelta: max(minDelta, (maxLon - minLon) * paddingFactor)
        )

        span.latitudeDelta = min(span.latitudeDelta, maxDelta)
        span.longitudeDelta = min(span.longitudeDelta, maxDelta)

        return MKCoordinateRegion(center: center, span: span)
    }

    /// Conveniência: aceita modelos FireFocus e extrai coordenadas.
    static func region(
        fitting focuses: [FireFocus],
        paddingFactor: Double = 1.3,
        minDelta: CLLocationDegrees = 0.5,
        maxDelta: CLLocationDegrees = 60,
        fallback: MKCoordinateRegion? = nil
    ) -> MKCoordinateRegion? {
        let coords = focuses.map { $0.coordinate }
        return region(
            fitting: coords,
            paddingFactor: paddingFactor,
            minDelta: minDelta,
            maxDelta: maxDelta,
            fallback: fallback
        )
        }
}

