import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("FireAnnotationFactory creation from FireFocus")
struct FireAnnotationFactoryTests {

    @Test("make cria anotação com ID e coordenada do foco")
    func makeSingle() throws {
        let focus = FireFocus(
            id: "f1",
            coordinate: CLLocationCoordinate2D(latitude: -12.3, longitude: -45.6),
            municipio: "Cidade",
            estado: "BAHIA",
            bioma: "Cerrado"
        )
        let ann = FireAnnotationFactory.make(from: focus)

        #expect(ann.focusID == focus.id)
        #expect(ann.coordinate.latitude == focus.coordinate.latitude)
        #expect(ann.coordinate.longitude == focus.coordinate.longitude)
    }

    @Test("makeAll preserva contagem e ordem")
    func makeAllOrder() throws {
        let focuses: [FireFocus] = [
            FireFocus(id: "a", coordinate: .init(latitude: -10, longitude: -50)),
            FireFocus(id: "b", coordinate: .init(latitude: -11, longitude: -51)),
            FireFocus(id: "c", coordinate: .init(latitude: -12, longitude: -52))
        ]
        let anns = FireAnnotationFactory.makeAll(from: focuses)

        #expect(anns.count == focuses.count)
        #expect(anns[0].focusID == "a")
        #expect(anns[1].focusID == "b")
        #expect(anns[2].focusID == "c")
    }
}
