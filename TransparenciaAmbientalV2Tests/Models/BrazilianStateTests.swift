import Testing
@testable import TransparenciaAmbientalV2

@Suite("BrazilianState normalization and matching")
struct BrazilianStateTests {

    @Test("Normalize handles case and trimming")
    func normalizeBasic() throws {
        #expect(BrazilianState.normalize("  goiás ") == "GOIÁS")
        #expect(BrazilianState.normalize("piauí") == "PIAUÍ")
        #expect(BrazilianState.normalize(" roraima ") == "RORAIMA")
        #expect(BrazilianState.normalize(nil) == nil)
        #expect(BrazilianState.normalize("") == nil)
        #expect(BrazilianState.normalize("   ") == nil)
    }

    @Test("Matches compares CSV value to enum correctly")
    func matchesEnum() throws {
        #expect(BrazilianState.matches(csvValue: "Bahia", to: .bahia))
        #expect(BrazilianState.matches(csvValue: "  GOIÁS", to: .goias))
        #expect(BrazilianState.matches(csvValue: "São Paulo", to: .saoPaulo))
        #expect(BrazilianState.matches(csvValue: "Maranhão", to: .maranhao))
        #expect(BrazilianState.matches(csvValue: "pará", to: .para))

        #expect(BrazilianState.matches(csvValue: "Goiás ", to: .maranhao) == false)
        #expect(BrazilianState.matches(csvValue: nil, to: .bahia) == false)
    }
}
