import Testing
import MapKit
@testable import TransparenciaAmbientalV2

// Mock do serviço para injetar CSV customizado
actor MockParseService: FireDataServiceProtocol {
    let csv: String
    init(csv: String) { self.csv = csv }
    func fetchCSV(for date: Date) async throws -> String { csv }
}

@Suite("ContentViewModel CSV download and typed parsing")
struct ContentViewModelParsingTests {

    @Test("Download popula modelo tipado e filtros usam estado/bioma do modelo")
    @MainActor
    func downloadAndFilter() async throws {
        // CSV com cabeçalhos variados e vírgula decimal
        let csv = """
        id,lat,lon,municipio,estado,bioma,satelite,numero_dias_sem_chuva,risco_fogo,frp
        a,-10.0,-50.0,TESTE1,BAHIA,Cerrado,TERRA,5,Alto,100,0
        b,-9.5,-49.5,TESTE2,TOCANTINS,Cerrado,AQUA,0,Baixo,25,0
        c,-7.0,-47.0,TESTE3,MARANHÃO,Amazônia,NOAA,12,Muito Alto,300,0
        """

        let vm = ContentViewModel(service: MockParseService(csv: csv))
        await vm.downloadData()

        // Existem 3 focos
        #expect(vm.focuses.count == 3)

        // Campos tipados presentes
        let a = try #require(vm.focuses.first(where: { $0.id == "a" }))
        #expect(a.municipio == "TESTE1")
        #expect(a.estado == "BAHIA")
        #expect(a.bioma == "Cerrado")
        #expect(a.satelite == "TERRA")
        #expect(a.numeroDiasSemChuva == 5)
        #expect(a.riscoFogo == "Alto")
        #expect(a.frp == 100.0)

        // Filtro por Estado
        vm.selectedState = .bahia
        #expect(vm.filteredFocuses.count == 1)

        // Filtro por Bioma
        vm.selectedState = nil
        vm.selectedBiome = .cerrado
        #expect(vm.filteredFocuses.count == 2)

        // Filtro combinado
        vm.selectedState = .maranhao
        vm.selectedBiome = .amazonia
        #expect(vm.filteredFocuses.count == 1)
    }
}
