import Foundation

struct CSVKeyNormalization {
    static func normalizeKeys(_ row: [String: String]) -> [String: String] {
        var map: [String: String] = [:]
        for (k, v) in row {
            let nk = normalizeKey(k)
            map[nk] = v
        }
        return map
    }

    static func normalizeKey(_ key: String) -> String {
        let trimmed = key.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        let decomposed = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let compact = decomposed.replacingOccurrences(of: " ", with: "_")
        return compact
    }

    static func value(in original: [String: String], normalized: [String: String], keys: [String]) -> String? {
        for k in keys {
            if let v = normalized[k], !v.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                return v
            }
        }
        return nil
    }

    // MARK: - helpers

    static func trim(_ value: String?) -> String? {
        guard let v = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else { return nil }
        return v.isEmpty ? nil : v
    }

    // Limpa string decimal: trim + troca vírgula por ponto; nil se vazio
    static func cleanDecimalString(_ value: String?) -> String? {
        guard let t = trim(value) else { return nil }
        let replaced = t.replacingOccurrences(of: ",", with: ".")
        return replaced.isEmpty ? nil : replaced
    }

    static func parseDecimal(_ value: String?) -> Double? {
        guard let cleaned = cleanDecimalString(value) else { return nil }
        return Double(cleaned)
    }
}

