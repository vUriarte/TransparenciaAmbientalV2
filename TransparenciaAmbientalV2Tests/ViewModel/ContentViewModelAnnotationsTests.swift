import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("ContentViewModel annotations delegation and filtering")
struct ContentViewModelAnnotationsTests {

    // Serviço dummy que não é chamado nesses testes (apenas satisfaz o init)
    actor DummyService: FireDataServiceProtocol {
        func fetchCSV(for date: Date) async throws -> String { "" }
    }

    private func sampleFocuses() -> [FireFocus] {
        [
            FireFocus(
                id: "a",
                coordinate: CLLocationCoordinate2D(latitude: -12.0, longitude: -45.0),
                municipio: "CidadeA",
                estado: "BAHIA",
                bioma: "Cerrado"
            ),
            FireFocus(
                id: "b",
                coordinate: CLLocationCoordinate2D(latitude: -13.0, longitude: -44.0),
                municipio: "CidadeB",
                estado: "BAHIA",
                bioma: "Cerrado"
            ),
            FireFocus(
                id: "c",
                coordinate: CLLocationCoordinate2D(latitude: -7.0, longitude: -47.0),
                municipio: "CidadeC",
                estado: "MARANHÃO",
                bioma: "Amazônia"
            )
        ]
    }

    @Test("annotations reflete filteredFocuses sem filtros")
    @MainActor
    func annotationsNoFilter() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        let anns = vm.annotations
        #expect(anns.count == vm.filteredFocuses.count)
        #expect(Set(anns.map { $0.focusID }) == Set(vm.filteredFocuses.map { $0.id }))
    }

    @Test("annotations reflete filteredFocuses com filtro por Estado")
    @MainActor
    func annotationsWithStateFilter() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        vm.selectedState = .bahia
        let anns = vm.annotations

        #expect(anns.count == 2)
        #expect(Set(anns.map { $0.focusID }) == Set(["a","b"]))
    }

    @Test("annotations reflete filteredFocuses com filtro por Bioma")
    @MainActor
    func annotationsWithBiomeFilter() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        vm.selectedBiome = .amazonia
        let anns = vm.annotations

        #expect(anns.count == 1)
        #expect(anns.first?.focusID == "c")
    }
}
