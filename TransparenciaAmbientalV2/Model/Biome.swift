import Foundation

enum Biome: String, CaseIterable, Identifiable {
    case amazonia = "Amazônia"
    case cerrado = "Cerrado"
    case caatinga = "Caatinga"
    case mataAtlantica = "Mata Atlântica"
    case pampa = "Pampa"
    case pantanal = "Pantanal"

    var id: String { rawValue }
    var displayName: String { rawValue }

    static func matches(csvValue: String?, to biome: Biome) -> Bool {
        guard let norm = normalize(csvValue) else { return false }
        return norm == normalize(biome.rawValue)
    }

    static func normalize(_ value: String?) -> String? {
        guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return nil }
        // Mantemos case-insensitive e tratamos acentos por simplicidade via uppercase (não removemos diacríticos)
        return v.uppercased()
    }
}
