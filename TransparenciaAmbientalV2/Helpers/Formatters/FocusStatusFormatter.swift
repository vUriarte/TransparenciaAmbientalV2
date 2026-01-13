import Foundation

struct FocusStatusFormatter {
    static let emptyMessage = "Nenhum ponto encontrado."

    static func exhibitMessage(total: Int, state: BrazilianState?, biome: Biome?) -> String {
        let wherePart = wherePart(state: state, biome: biome)
        return "Exibindo \(total) pontos\(wherePart)."
    }

    static func wherePart(state: BrazilianState?, biome: Biome?) -> String {
        switch (state, biome) {
        case (nil, nil):
            return ""
        case (let st?, nil):
            return " em \(st.displayName)"
        case (nil, let bio?):
            return " no bioma \(bio.displayName)"
        case (let st?, let bio?):
            return " em \(st.displayName), bioma \(bio.displayName)"
        }
    }
}

