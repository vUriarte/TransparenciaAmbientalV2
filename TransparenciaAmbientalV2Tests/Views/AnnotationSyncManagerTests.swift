import Testing
import MapKit
@testable import TransparenciaAmbientalV2

@Suite("AnnotationSyncManager add/remove diff")
struct AnnotationSyncManagerTests {

    @Test("Sincroniza adicionando e removendo anotações conforme IDs")
    @MainActor
    func syncAddsAndRemoves() throws {
        let map = MKMapView(frame: .init(x: 0, y: 0, width: 200, height: 200))
        let manager = AnnotationSyncManager()

        // Registra views (não essencial para o teste de dados, mas mantém fluxo realista)
        manager.registerViews(on: map)

        // Estado inicial: vazio
        #expect(map.annotations.isEmpty)

        // Entradas iniciais
        let f1 = FireFocus(id: "a", coordinate: .init(latitude: -10, longitude: -50))
        let f2 = FireFocus(id: "b", coordinate: .init(latitude: -11, longitude: -51))
        let anns1 = [FireAnnotation(focus: f1), FireAnnotation(focus: f2)]

        manager.sync(on: map, with: anns1)
        // Deve ter 2 anotações
        #expect(Set(map.annotations.compactMap { ($0 as? FireAnnotation)?.focusID }) == Set(["a","b"]))

        // Nova entrada substitui "b" por "c"
        let f3 = FireFocus(id: "c", coordinate: .init(latitude: -12, longitude: -52))
        let anns2 = [FireAnnotation(focus: f1), FireAnnotation(focus: f3)]

        manager.sync(on: map, with: anns2)
        // Deve ter "a" e "c"
        #expect(Set(map.annotations.compactMap { ($0 as? FireAnnotation)?.focusID }) == Set(["a","c"]))
    }

    @Test("removeFireAnnotations remove apenas FireAnnotation")
    @MainActor
    func removeOnlyFireAnnotations() throws {
        let map = MKMapView()
        let manager = AnnotationSyncManager()

        // Adiciona duas FireAnnotation e um MKPointAnnotation genérico
        let fa1 = FireAnnotation(focus: FireFocus(id: "x", coordinate: .init(latitude: 0, longitude: 0)))
        let fa2 = FireAnnotation(focus: FireFocus(id: "y", coordinate: .init(latitude: 1, longitude: 1)))
        let other = MKPointAnnotation()
        other.coordinate = .init(latitude: 2, longitude: 2)

        map.addAnnotations([fa1, fa2, other])
        #expect(map.annotations.count == 3)

        manager.removeFireAnnotations(from: map)
        // Deve restar apenas a anotação genérica
        #expect(map.annotations.count == 1)
        #expect(!(map.annotations.first is FireAnnotation))
    }
}
