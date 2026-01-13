import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("FireAnnotation title/subtitle from FireFocus")
struct FireAnnotationTests {

    @Test("Monta título/subtítulo com município, estado e bioma")
    func titleSubtitle() throws {
        let focus = FireFocus(
            id: "x1",
            coordinate: CLLocationCoordinate2D(latitude: -12, longitude: -45),
            satelite: "AQUA",
            municipio: "Barreiras",
            estado: "BAHIA",
            numeroDiasSemChuva: 2,
            riscoFogo: "Moderado",
            bioma: "Cerrado",
            frp: 50.0
        )

        let ann = FireAnnotation(focus: focus)
        #expect(ann.title == "Barreiras")
        #expect(ann.subtitle == "BAHIA • Cerrado")
    }

    @Test("Subtítulo cai para estado quando não há bioma")
    func subtitleFallbackEstado() throws {
        let focus = FireFocus(
            id: "x2",
            coordinate: CLLocationCoordinate2D(latitude: -10, longitude: -48),
            municipio: "Palmas",
            estado: "TOCANTINS"
        )
        let ann = FireAnnotation(focus: focus)
        #expect(ann.title == "Palmas")
        #expect(ann.subtitle == "TOCANTINS")
    }

    @Test("Sem município/estado/bioma resulta em título genérico e subtítulo nil")
    func subtitleNone() throws {
        let focus = FireFocus(
            id: "x3",
            coordinate: CLLocationCoordinate2D(latitude: -9, longitude: -47)
        )
        let ann = FireAnnotation(focus: focus)
        #expect(ann.title == "Foco de queimada")
        #expect(ann.subtitle == nil)
    }
}
