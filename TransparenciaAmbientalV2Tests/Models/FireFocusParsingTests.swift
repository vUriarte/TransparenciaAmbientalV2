import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("FireFocus parsing from CSV raw")
struct FireFocusParsingTests {

    @Test("Popula campos com chaves comuns (sem acentos) e FRP com ponto")
    func parseCommonKeys() throws {
        let raw: [String: String] = [
            "id": "abc123",
            "municipio": "Xinguara",
            "estado": "PARÁ",
            "bioma": "Amazônia",
            "satelite": "AQUA",
            "numero_dias_sem_chuva": "7",
            "risco_fogo": "Alto",
            "frp": "123.4",
            "lat": "-7.0",
            "lon": "-50.0"
        ]

        let focus = FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -7, longitude: -50),
            raw: raw
        )

        #expect(focus.id.count > 0)
        #expect(focus.municipio == "Xinguara")
        #expect(focus.estado == "PARÁ")
        #expect(focus.bioma == "Amazônia")
        #expect(focus.satelite == "AQUA")
        #expect(focus.numeroDiasSemChuva == 7)
        #expect(focus.riscoFogo == "Alto")
        #expect(focus.frp == 123.4)
    }

    @Test("Popula campos com chaves acentuadas/variantes e FRP com vírgula")
    func parseAccentedKeysAndCommaFRP() throws {
        let raw: [String: String] = [
            "município": "Palmas",
            "UF": "TOCANTINS",
            "bioma": "Cerrado",
            "satélite": "TERRA",
            "dias_sem_chuva": "12",
            "risco": "Muito Alto",
            "frp": "56,7"
        ]

        let focus = FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -10, longitude: -48),
            raw: raw
        )

        #expect(focus.municipio == "Palmas")
        #expect(focus.estado == "TOCANTINS")
        #expect(focus.bioma == "Cerrado")
        #expect(focus.satelite == "TERRA")
        #expect(focus.numeroDiasSemChuva == 12)
        #expect(focus.riscoFogo == "Muito Alto")
        #expect(focus.frp == 56.7)
    }

    @Test("Construtor completo preserva campos")
    func fullInitializer() throws {
        let f = FireFocus(
            id: "z1",
            coordinate: CLLocationCoordinate2D(latitude: -11, longitude: -45),
            satelite: "NOAA",
            municipio: "TesteCity",
            estado: "BAHIA",
            numeroDiasSemChuva: 3,
            riscoFogo: "Moderado",
            bioma: "Cerrado",
            frp: 10.0
        )
        #expect(f.id == "z1")
        #expect(f.satelite == "NOAA")
        #expect(f.municipio == "TesteCity")
        #expect(f.estado == "BAHIA")
        #expect(f.numeroDiasSemChuva == 3)
        #expect(f.riscoFogo == "Moderado")
        #expect(f.bioma == "Cerrado")
        #expect(f.frp == 10.0)
    }
}
