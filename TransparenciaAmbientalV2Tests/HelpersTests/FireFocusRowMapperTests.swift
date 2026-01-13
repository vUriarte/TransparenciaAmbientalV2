import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("FireFocusRowMapper mapping and key detection")
struct FireFocusRowMapperTests {

    @Test("Detecta chaves lat/lon em headers comuns")
    func detectLatLonKeysCommon() throws {
        let headers = ["id","lat","lon","municipio"]
        let (latKey, lonKey) = FireFocusRowMapper.detectLatLonKeys(headers: headers)
        #expect(latKey == "lat")
        #expect(lonKey == "lon")
    }

    @Test("Detecta chaves lat/lon em variantes")
    func detectLatLonKeysVariants() throws {
        let headers = ["ID","Latitude","Longitud","Data"]
        let (latKey, lonKey) = FireFocusRowMapper.detectLatLonKeys(headers: headers)
        #expect(latKey == "Latitude")
        #expect(lonKey == "Longitud")
    }

    @Test("Mapeia linha válida com ponto decimal")
    func mapRowValidDot() throws {
        let row: [String: String] = [
            "id": "abc",
            "lat": "-10.5",
            "lon": "-50.25",
            "municipio": "Teste",
            "estado": "BAHIA",
            "bioma": "Cerrado",
            "satelite": "AQUA",
            "numero_dias_sem_chuva": "7",
            "risco_fogo": "Alto",
            "frp": "123.4"
        ]
        let f = try #require(FireFocusRowMapper.mapRow(row: row, latKey: "lat", lonKey: "lon"))
        #expect(f.id == "abc")
        #expect(f.coordinate.latitude == -10.5)
        #expect(f.coordinate.longitude == -50.25)
        #expect(f.municipio == "Teste")
        #expect(f.estado == "BAHIA")
        #expect(f.bioma == "Cerrado")
        #expect(f.satelite == "AQUA")
        #expect(f.numeroDiasSemChuva == 7)
        #expect(f.riscoFogo == "Alto")
        #expect(f.frp == 123.4)
    }

    @Test("Mapeia linha válida com vírgula decimal")
    func mapRowValidComma() throws {
        let row: [String: String] = [
            "lat": "-9,75",
            "lon": "-48,5",
            "frp": "56,7"
        ]
        let f = try #require(FireFocusRowMapper.mapRow(row: row, latKey: "lat", lonKey: "lon"))
        #expect(abs(f.coordinate.latitude + 9.75) < 1e-9)
        #expect(abs(f.coordinate.longitude + 48.5) < 1e-9)
        #expect(abs((f.frp ?? -1) - 56.7) < 1e-9)
    }

    @Test("Descarta linha com lat/lon inválidos/out of range")
    func mapRowInvalid() throws {
        let rowBad: [String: String] = [
            "lat": "abc",
            "lon": "-50"
        ]
        #expect(FireFocusRowMapper.mapRow(row: rowBad, latKey: "lat", lonKey: "lon") == nil)

        let rowOut: [String: String] = [
            "lat": "95",
            "lon": "0"
        ]
        #expect(FireFocusRowMapper.mapRow(row: rowOut, latKey: "lat", lonKey: "lon") == nil)
    }

    @Test("mapAll aplica detecção de chaves e ignora linhas inválidas")
    func mapAllDetectsAndMaps() throws {
        let headers = ["id","Latitude","Longitud","municipio"]
        let rows: [[String: String]] = [
            ["id":"a","Latitude":"-10.0","Longitud":"-50.0","municipio":"X"],
            ["id":"b","Latitude":"abc","Longitud":"-49.5","municipio":"Y"],  // inválida
            ["id":"c","Latitude":"-9.5","Longitud":"-49.5","municipio":"Z"]
        ]
        let items = FireFocusRowMapper.mapAll(headers: headers, rows: rows)
        #expect(items.count == 2)
        #expect(Set(items.map { $0.id }) == Set(["a","c"]))
    }

    @Test("Gera UUID quando id ausente ou vazio")
    func generatesUUIDWhenMissingID() throws {
        let row: [String: String] = [
            "lat": "-10",
            "lon": "-50",
            "id": "   "
        ]
        let f = try #require(FireFocusRowMapper.mapRow(row: row, latKey: "lat", lonKey: "lon"))
        #expect(!f.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
