import Testing
import MapKit
@testable import TransparenciaAmbientalV2

// Mock do serviço para injetar CSV customizado com headers variantes
actor MockVariantService: FireDataServiceProtocol {
    let csv: String
    init(csv: String) { self.csv = csv }
    func fetchCSV(for date: Date) async throws -> String { csv }
}

@Suite("ContentViewModel parsing with header variants and value formats")
struct ContentViewModelParsingVariantsTests {

    @Test("Headers variantes (Latitude/Longitud), vírgula decimal e id vazio")
    @MainActor
    func variantsAndCommaDecimal() async throws {
        // Note: headers com 'Latitude' e 'Longitud'; id vazio na primeira linha
        let csv = """
        id,Latitude,Longitud,município,UF,bioma,satélite,numero_dias_sem_chuva,risco,frp
          , -10, -50,Palmas,TOCANTINS,Cerrado,TERRA,12,Muito Alto,56,7
        b,-9, -49.5,Xinguara,PARÁ,Amazônia,AQUA,5,Alto,123.4
        """

        let vm = ContentViewModel(service: MockVariantService(csv: csv))
        await vm.downloadData()

        // Devem existir 2 focos
        #expect(vm.focuses.count == 2)

        // Primeiro foco: id gerado (não vazio), valores parseados
        let f0 = try #require(vm.focuses.first)
        #expect(!f0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(f0.municipio == "Palmas")
        #expect(f0.estado == "TOCANTINS")
        #expect(f0.bioma == "Cerrado")
        #expect(f0.satelite == "TERRA")
        #expect(f0.numeroDiasSemChuva == 12)
        #expect(f0.riscoFogo == "Muito Alto")
        // FRP na primeira linha está como "56,7" (vírgula decimal) — parser deve tratar e ler 56.7
        #expect(f0.frp == 56.7)

        // Segundo foco: id "b" preservado
        let f1 = try #require(vm.focuses.last)
        #expect(f1.id == "b")
        #expect(f1.municipio == "Xinguara")
        #expect(f1.estado == "PARÁ")
        #expect(f1.bioma == "Amazônia")
        #expect(f1.satelite == "AQUA")
        #expect(f1.numeroDiasSemChuva == 5)
        #expect(f1.riscoFogo == "Alto")
        #expect(f1.frp == 123.4)

        // Filtragem continua funcionando com os campos tipados
        vm.selectedState = .goias
        #expect(vm.filteredFocuses.isEmpty)

        vm.selectedState = .para
        #expect(vm.filteredFocuses.count == 1)

        vm.selectedState = nil
        vm.selectedBiome = .cerrado
        #expect(vm.filteredFocuses.count == 1)
    }

    @Test("Linha inválida (lat/lon ausentes ou inválidos) é descartada silenciosamente")
    @MainActor
    func discardsInvalidRows() async throws {
        let csv = """
        id,lat,lon,municipio
        x,abc,-50,Teste
        y,-10,zzz,Teste2
        z,-10.0,-50.0,Valida
        """

        let vm = ContentViewModel(service: MockVariantService(csv: csv))
        await vm.downloadData()

        // Apenas a última linha deve virar foco
        #expect(vm.focuses.count == 1)
        #expect(vm.focuses[0].id == "z")
        #expect(vm.focuses[0].municipio == "Valida")
    }
}
