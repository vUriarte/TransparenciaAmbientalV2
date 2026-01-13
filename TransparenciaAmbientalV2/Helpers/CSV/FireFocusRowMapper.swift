import Foundation
import CoreLocation

struct FireFocusRowMapper {

    // Detecta chaves de latitude/longitude em headers variados
    static func detectLatLonKeys(headers: [String]) -> (String?, String?) {
        let lower = headers.map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased() }
        let candidatesLat = ["latitude", "lat", "y", "latitud"]
        let candidatesLon = ["longitude", "lon", "long", "lng", "x", "longitud"]

        var latKey: String?
        var lonKey: String?

        for (i, h) in lower.enumerated() {
            if latKey == nil, candidatesLat.contains(h) {
                latKey = headers[i]
            }
            if lonKey == nil, candidatesLon.contains(h) {
                lonKey = headers[i]
            }
        }
        return (latKey, lonKey)
    }

    // Mapeia todas as linhas para FireFocus usando headers
    static func mapAll(headers: [String], rows: [[String: String]]) -> [FireFocus] {
        let (latKeyOpt, lonKeyOpt) = detectLatLonKeys(headers: headers)
        guard let latKey = latKeyOpt, let lonKey = lonKeyOpt else {
            return []
        }

        var items: [FireFocus] = []
        items.reserveCapacity(rows.count)

        for row in rows {
            if let focus = mapRow(row: row, latKey: latKey, lonKey: lonKey) {
                items.append(focus)
            }
        }
        return items
    }

    // Mapeia uma única linha em FireFocus, se válida
    static func mapRow(row: [String: String], latKey: String, lonKey: String) -> FireFocus? {
        guard let latRaw = row[latKey], let lonRaw = row[lonKey] else { return nil }

        // Normaliza e parseia lat/lon
        guard
            let latStr = CSVKeyNormalization.cleanDecimalString(latRaw),
            let lonStr = CSVKeyNormalization.cleanDecimalString(lonRaw),
            let lat = Double(latStr),
            let lon = Double(lonStr)
        else { return nil }

        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        guard coord.latitude >= -90, coord.latitude <= 90, coord.longitude >= -180, coord.longitude <= 180 else { return nil }

        // Normaliza chaves para lookup dos demais campos
        let norm = CSVKeyNormalization.normalizeKeys(row)

        let csvID = CSVKeyNormalization.trim(row["id"])

        let satelite = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["satelite", "satélite", "satellite"])
        let municipio = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["municipio", "município"])
        let estado = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["estado", "uf"])
        let bioma = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["bioma"])
        let riscoFogo = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["risco_fogo", "risco", "riscofogo"])

        let diasStr = CSVKeyNormalization.value(in: row, normalized: norm, keys: ["numero_dias_sem_chuva", "dias_sem_chuva", "diassemschuva"])
        let numeroDiasSemChuva = Int(diasStr ?? "")

        let frp = CSVKeyNormalization.parseDecimal(CSVKeyNormalization.value(in: row, normalized: norm, keys: ["frp"]))

        return FireFocus(
            id: (csvID?.isEmpty == false ? csvID! : UUID().uuidString),
            coordinate: coord,
            satelite: satelite,
            municipio: municipio,
            estado: estado,
            numeroDiasSemChuva: numeroDiasSemChuva,
            riscoFogo: riscoFogo,
            bioma: bioma,
            frp: frp
        )
    }
}

