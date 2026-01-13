import Foundation

struct FireFocusFilter {
    static func filter(_ focuses: [FireFocus], state: BrazilianState?, biome: Biome?) -> [FireFocus] {
        focuses.filter { focus in
            let matchesState: Bool = {
                guard let sel = state else { return true }
                return BrazilianState.matches(csvValue: focus.estado, to: sel)
            }()

            let matchesBiome: Bool = {
                guard let sel = biome else { return true }
                return Biome.matches(csvValue: focus.bioma, to: sel)
            }()

            return matchesState && matchesBiome
        }
    }
}

