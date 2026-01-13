import Testing
import MapKit
@testable import TransparenciaAmbientalV2

@Suite("ContentViewModel filtering by State and Biome")
struct ContentViewModelFilterTests {

    @Test("No filters returns all focuses")
    @MainActor
    func noFilters() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()
        #expect(vm.filteredFocuses.count == 4)
    }

    @Test("Filter by State only")
    @MainActor
    func filterByState() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        vm.selectedState = .bahia
        #expect(vm.filteredFocuses.count == 2) // 2 focos na BAHIA

        vm.selectedState = .tocantins
        #expect(vm.filteredFocuses.count == 1) // 1 foco no TOCANTINS

        vm.selectedState = .maranhao
        #expect(vm.filteredFocuses.count == 1) // 1 foco no MARANHÃO
    }

    @Test("Filter by Biome only")
    @MainActor
    func filterByBiome() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        vm.selectedBiome = .cerrado
        #expect(vm.filteredFocuses.count == 3) // 3 focos no Cerrado

        vm.selectedBiome = .amazonia
        #expect(vm.filteredFocuses.count == 1) // 1 foco na Amazônia
    }

    @Test("Filter by State and Biome combined")
    @MainActor
    func filterCombined() throws {
        let vm = ContentViewModel(service: DummyService())
        vm.focuses = sampleFocuses()

        vm.selectedState = .bahia
        vm.selectedBiome = .cerrado
        #expect(vm.filteredFocuses.count == 2) // 2 focos na BAHIA e no Cerrado

        vm.selectedState = .maranhao
        vm.selectedBiome = .amazonia
        #expect(vm.filteredFocuses.count == 1) // 1 foco no MARANHÃO e Amazônia

        vm.selectedState = .tocantins
        vm.selectedBiome = .amazonia
        #expect(vm.filteredFocuses.isEmpty) // nenhum nessa combinação
    }
}

// Serviço dummy que nunca é chamado nos testes de filtro (só para satisfazer o init)
actor DummyService: FireDataServiceProtocol {
    func fetchCSV(for date: Date) async throws -> String { "" }
}

// Amostra de focos sintéticos com combinações de estado/bioma
private func sampleFocuses() -> [FireFocus] {
    [
        FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -12.0, longitude: -45.0),
            raw: ["estado": "BAHIA", "bioma": "Cerrado"]
        ),
        FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -13.0, longitude: -44.0),
            raw: ["estado": "BAHIA", "bioma": "Cerrado"]
        ),
        FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -7.0, longitude: -47.0),
            raw: ["estado": "MARANHÃO", "bioma": "Amazônia"]
        ),
        FireFocus(
            coordinate: CLLocationCoordinate2D(latitude: -9.0, longitude: -49.8),
            raw: ["estado": "TOCANTINS", "bioma": "Cerrado"]
        )
    ]
}
