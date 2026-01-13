import Testing
@testable import TransparenciaAmbientalV2

@Suite("CSVKeyNormalization value and key normalization")
struct CSVKeyNormalizationTests {

    @Test("trim removes whitespace/newlines and returns nil when empty")
    func trimBasic() throws {
        #expect(CSVKeyNormalization.trim("  abc ") == "abc")
        #expect(CSVKeyNormalization.trim("\n\t xyz \t") == "xyz")
        #expect(CSVKeyNormalization.trim(nil) == nil)
        #expect(CSVKeyNormalization.trim("") == nil)
        #expect(CSVKeyNormalization.trim("   ") == nil)
    }

    @Test("cleanDecimalString trims and replaces comma with dot")
    func cleanDecimal() throws {
        #expect(CSVKeyNormalization.cleanDecimalString(" 123,45 ") == "123.45")
        #expect(CSVKeyNormalization.cleanDecimalString("  0,0") == "0.0")
        #expect(CSVKeyNormalization.cleanDecimalString(nil) == nil)
        #expect(CSVKeyNormalization.cleanDecimalString("   ") == nil)
    }

    @Test("parseDecimal parses cleaned decimal string to Double")
    func parseDecimal() throws {
        #expect(CSVKeyNormalization.parseDecimal(" 123,45 ") == 123.45)
        #expect(CSVKeyNormalization.parseDecimal("0.001") == 0.001)
        #expect(CSVKeyNormalization.parseDecimal(nil) == nil)
        #expect(CSVKeyNormalization.parseDecimal("   ") == nil)
        #expect(CSVKeyNormalization.parseDecimal("abc") == nil)
    }

    @Test("normalizeKeys and value lookup handle accented/variant keys")
    func normalizeAndLookup() throws {
        let raw: [String: String] = [
            "município": "Palmas",
            "UF": "TOCANTINS",
            "satélite": "TERRA",
            "dias_sem_chuva": "12",
            "risco": "Muito Alto",
            "bioma": "Cerrado",
            "frp": "56,7"
        ]
        let norm = CSVKeyNormalization.normalizeKeys(raw)

        let municipio = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["municipio", "município"])
        let estado = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["estado", "uf"])
        let satelite = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["satelite", "satélite"])
        let dias = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["numero_dias_sem_chuva", "dias_sem_chuva"])
        let risco = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["risco_fogo", "risco"])
        let bioma = CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["bioma"])
        let frp = CSVKeyNormalization.parseDecimal(CSVKeyNormalization.value(in: raw, normalized: norm, keys: ["frp"]))

        #expect(municipio == "Palmas")
        #expect(estado == "TOCANTINS")
        #expect(satelite == "TERRA")
        #expect(dias == "12")
        #expect(risco == "Muito Alto")
        #expect(bioma == "Cerrado")
        #expect(frp == 56.7)
    }
}
