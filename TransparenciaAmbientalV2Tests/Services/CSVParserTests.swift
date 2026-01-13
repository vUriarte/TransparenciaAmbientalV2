import Testing
@testable import TransparenciaAmbientalV2

@Suite("CSVParser basic parsing")
struct CSVParserTests {

    @Test("Parse simples com header e uma linha")
    func simpleParse() throws {
        let csv = "id,lat,lon\nabc, -10.1, -50.2"
        let result = CSVParser.parseCSV(csv)
        #expect(result.headers == ["id","lat","lon"])
        #expect(result.rows.count == 1)
        #expect(result.rows[0]["id"] == "abc")
        #expect(result.rows[0]["lat"] == "-10.1")
        #expect(result.rows[0]["lon"] == "-50.2")
    }

    @Test("Suporta BOM no início")
    func supportsBOM() throws {
        let csv = "\u{FEFF}id,lat,lon\nabc, -1, -2"
        let result = CSVParser.parseCSV(csv)
        #expect(result.headers.first == "id")
        #expect(result.rows.first?["lon"] == "-2")
    }

    @Test("Campos entre aspas com vírgula interna")
    func quotedFields() throws {
        let csv = "id,municipio\n1,\"SÃO FÉLIX, DO XINGU\""
        let result = CSVParser.parseCSV(csv)
        #expect(result.rows.first?["municipio"] == "SÃO FÉLIX, DO XINGU")
    }
}
