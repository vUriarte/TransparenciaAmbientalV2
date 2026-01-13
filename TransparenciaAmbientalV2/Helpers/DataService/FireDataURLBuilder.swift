import Foundation

struct FireDataURLBuilder {
    static func csvURL(baseURL: URL, for date: Date) -> URL {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyyMMdd"
        let name = "focos_diario_br_\(df.string(from: date)).csv"
        return baseURL.appendingPathComponent(name)
    }
}
