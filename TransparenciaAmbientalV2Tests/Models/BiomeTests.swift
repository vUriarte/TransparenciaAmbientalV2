import Testing
@testable import TransparenciaAmbientalV2

@Suite("Biome normalization and matching")
struct BiomeTests {

    @Test("Normalize handles case and trimming")
    func normalizeBasic() throws {
        #expect(Biome.normalize("  Cerrado ") == "CERRADO")
        #expect(Biome.normalize("amazônia") == "AMAZÔNIA")
        #expect(Biome.normalize(nil) == nil)
        #expect(Biome.normalize("") == nil)
        #expect(Biome.normalize("   ") == nil)
    }

    @Test("Matches compares CSV value to enum correctly")
    func matchesEnum() throws {
        #expect(Biome.matches(csvValue: "Cerrado", to: .cerrado))
        #expect(Biome.matches(csvValue: "  Amazônia", to: .amazonia))
        #expect(Biome.matches(csvValue: "Mata Atlântica", to: .mataAtlantica))
        #expect(Biome.matches(csvValue: "Pantanal", to: .pantanal))
        #expect(Biome.matches(csvValue: "caatinga", to: .caatinga))
        #expect(Biome.matches(csvValue: "Pampa", to: .pampa))

        #expect(Biome.matches(csvValue: "Desconhecido", to: .cerrado) == false)
        #expect(Biome.matches(csvValue: nil, to: .cerrado) == false)
    }
}
