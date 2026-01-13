import Foundation

enum StatisticsFormatter {
    static func number(_ x: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: x)) ?? "\(x)"
    }

    static func optionalNumber(_ x: Double?) -> String {
        guard let x else { return "—" }
        return number(x)
    }

    static func percent(_ x: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: x)) ?? "\(x * 100)%"
    }

    static func date(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: d)
    }
}
