import Testing
import UIKit
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("CalloutViewFactory builds detail view")
struct CalloutViewFactoryTests {

    @Test("Cria view com conteúdo quando há dados")
    func buildsView() throws {
        let focus = FireFocus(
            id: "z1",
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
        let factory = CalloutViewFactory()

        let view = factory.makeDetailView(for: ann)
        #expect(view.subviews.isEmpty == false) // contém a stack
    }

    @Test("Cria view com fallback quando não há dados")
    func buildsViewWithFallback() throws {
        let focus = FireFocus(id: "z2", coordinate: .init(latitude: 0, longitude: 0))
        let ann = FireAnnotation(focus: focus)
        let factory = CalloutViewFactory()

        let view = factory.makeDetailView(for: ann)
        // Ainda retorna uma view válida
        #expect(view.subviews.isEmpty == false)
    }
}
