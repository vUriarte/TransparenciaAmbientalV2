import Testing
import CoreLocation
@testable import TransparenciaAmbientalV2

@Suite("FireFocusFilter state/biome filtering")
struct FireFocusFilterTests {

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
            ),
            FireFocus(
                id: "d",
                coordinate: CLLocationCoordinate2D(latitude: -9.0, longitude: -49.8),
                municipio: "CidadeD",
                estado: "TOCANTINS",
                bioma: "Cerrado"
            )
        ]
    }

    @Test("Sem filtros retorna todos")
    func noFilters() throws {
        let focuses = sampleFocuses()
        let result = FireFocusFilter.filter(focuses, state: nil, biome: nil)
        #expect(result.count == 4)
        #expect(Set(result.map { $0.id }) == Set(["a","b","c","d"]))
    }

    @Test("Filtro por Estado apenas")
    func filterByState() throws {
        let focuses = sampleFocuses()
        let resultBA = FireFocusFilter.filter(focuses, state: .bahia, biome: nil)
        #expect(resultBA.count == 2)
        #expect(Set(resultBA.map { $0.id }) == Set(["a","b"]))

        let resultTO = FireFocusFilter.filter(focuses, state: .tocantins, biome: nil)
        #expect(resultTO.count == 1)
        #expect(resultTO.first?.id == "d")

        let resultMA = FireFocusFilter.filter(focuses, state: .maranhao, biome: nil)
        #expect(resultMA.count == 1)
        #expect(resultMA.first?.id == "c")
    }

    @Test("Filtro por Bioma apenas")
    func filterByBiome() throws {
        let focuses = sampleFocuses()
        let resultCerrado = FireFocusFilter.filter(focuses, state: nil, biome: .cerrado)
        #expect(resultCerrado.count == 3)
        #expect(Set(resultCerrado.map { $0.id }) == Set(["a","b","d"]))

        let resultAmazonia = FireFocusFilter.filter(focuses, state: nil, biome: .amazonia)
        #expect(resultAmazonia.count == 1)
        #expect(resultAmazonia.first?.id == "c")
    }

    @Test("Filtro combinado Estado + Bioma")
    func filterCombined() throws {
        let focuses = sampleFocuses()
        let r1 = FireFocusFilter.filter(focuses, state: .bahia, biome: .cerrado)
        #expect(r1.count == 2)
        #expect(Set(r1.map { $0.id }) == Set(["a","b"]))

        let r2 = FireFocusFilter.filter(focuses, state: .maranhao, biome: .amazonia)
        #expect(r2.count == 1)
        #expect(r2.first?.id == "c")

        let r3 = FireFocusFilter.filter(focuses, state: .tocantins, biome: .amazonia)
        #expect(r3.isEmpty)
    }
}
