import Testing
@testable import TransparenciaAmbientalV2

@Suite("FocusStatusFormatter message formatting")
struct FocusStatusFormatterTests {

    @Test("Mensagem vazia")
    func emptyMessage() throws {
        #expect(FocusStatusFormatter.emptyMessage == "Nenhum ponto encontrado.")
    }

    @Test("Exhibit sem filtros")
    func exhibitNoFilters() throws {
        let msg = FocusStatusFormatter.exhibitMessage(total: 5, state: nil, biome: nil)
        #expect(msg == "Exibindo 5 pontos.")
    }

    @Test("Exhibit com Estado apenas")
    func exhibitWithState() throws {
        let msg = FocusStatusFormatter.exhibitMessage(total: 2, state: .bahia, biome: nil)
        #expect(msg == "Exibindo 2 pontos em BAHIA.")
    }

    @Test("Exhibit com Bioma apenas")
    func exhibitWithBiome() throws {
        let msg = FocusStatusFormatter.exhibitMessage(total: 3, state: nil, biome: .cerrado)
        #expect(msg == "Exibindo 3 pontos no bioma Cerrado.")
    }

    @Test("Exhibit com Estado e Bioma")
    func exhibitWithBoth() throws {
        let msg = FocusStatusFormatter.exhibitMessage(total: 1, state: .maranhao, biome: .amazonia)
        #expect(msg == "Exibindo 1 pontos em MARANHÃO, bioma Amazônia.")
    }
}
