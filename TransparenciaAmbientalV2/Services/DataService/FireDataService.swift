import Foundation
import os

private let log = OSLog(subsystem: "br.uriarte.transparencia", category: "perf")


actor FireDataService: FireDataServiceProtocol {
    private let baseURL = URL(string: "https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/diario/Brasil/")!

    func fetchCSV(for date: Date) async throws -> String {
        let t0 = CFAbsoluteTimeGetCurrent()
        
        let csvURL = await FireDataURLBuilder.csvURL(baseURL: baseURL, for: date)
        
        let (csvData, response) = try await URLSession.shared.data(from: csvURL)
        
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw NSError(domain: "FireDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Arquivo não encontrado para a data selecionada."])
        }
        
        let t1 = CFAbsoluteTimeGetCurrent()
        
        guard let csv = String(data: csvData, encoding: .utf8) ?? String(data: csvData, encoding: .isoLatin1) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let t2 = CFAbsoluteTimeGetCurrent()
        
        await os_log("CSV fetch=%.3fs parseStart=%.3fs url=%{public}@", log: log, type: .info, t1 - t0, t2 - t0, csvURL.absoluteString)

        return csv
    }

    // Internal para permitir teste via extensão se necessário
    func csvURL(for date: Date) -> URL {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyyMMdd"
        let name = "focos_diario_br_\(df.string(from: date)).csv"
        return baseURL.appendingPathComponent(name)
    }
}
