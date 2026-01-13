import Testing
import Foundation
@testable import TransparenciaAmbientalV2

@Suite("FireDataService URL building")
struct FireDataServiceURLTests {

    @Test("Monta URL com formato yyyyMMdd")
    func buildsDailyURL() throws {
        let base = URL(string: "https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/diario/Brasil/")!
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 7
        comps.day = 30
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Calendar(identifier: .gregorian).date(from: comps)!

        let url = FireDataURLBuilder.csvURL(baseURL: base, for: date)

        #expect(url.absoluteString.hasSuffix("/focos_diario_br_20250730.csv"))
    }
}
