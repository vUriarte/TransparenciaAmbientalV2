import Foundation

enum BrazilianState: String, CaseIterable, Identifiable {
    case acre = "ACRE"
    case alagoas = "ALAGOAS"
    case amapa = "AMAPÁ"
    case amazonas = "AMAZONAS"
    case bahia = "BAHIA"
    case ceara = "CEARÁ"
    case distritoFederal = "DISTRITO FEDERAL"
    case espiritoSanto = "ESPÍRITO SANTO"
    case goias = "GOIÁS"
    case maranhao = "MARANHÃO"
    case matoGrosso = "MATO GROSSO"
    case matoGrossoDoSul = "MATO GROSSO DO SUL"
    case minasGerais = "MINAS GERAIS"
    case para = "PARÁ"
    case paraiba = "PARAÍBA"
    case parana = "PARANÁ"
    case pernambuco = "PERNAMBUCO"
    case piaui = "PIAUÍ"
    case rioDeJaneiro = "RIO DE JANEIRO"
    case rioGrandeDoNorte = "RIO GRANDE DO NORTE"
    case rioGrandeDoSul = "RIO GRANDE DO SUL"
    case rondonia = "RONDÔNIA"
    case roraima = "RORAIMA"
    case santaCatarina = "SANTA CATARINA"
    case saoPaulo = "SÃO PAULO"
    case sergipe = "SERGIPE"
    case tocantins = "TOCANTINS"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var uf: String {
        switch self {
        case .acre: return "AC"
        case .alagoas: return "AL"
        case .amapa: return "AP"
        case .amazonas: return "AM"
        case .bahia: return "BA"
        case .ceara: return "CE"
        case .distritoFederal: return "DF"
        case .espiritoSanto: return "ES"
        case .goias: return "GO"
        case .maranhao: return "MA"
        case .matoGrosso: return "MT"
        case .matoGrossoDoSul: return "MS"
        case .minasGerais: return "MG"
        case .para: return "PA"
        case .paraiba: return "PB"
        case .parana: return "PR"
        case .pernambuco: return "PE"
        case .piaui: return "PI"
        case .rioDeJaneiro: return "RJ"
        case .rioGrandeDoNorte: return "RN"
        case .rioGrandeDoSul: return "RS"
        case .rondonia: return "RO"
        case .roraima: return "RR"
        case .santaCatarina: return "SC"
        case .saoPaulo: return "SP"
        case .sergipe: return "SE"
        case .tocantins: return "TO"
        }
    }

    // Normaliza valor vindo do CSV e compara com o enum
    static func matches(csvValue: String?, to state: BrazilianState) -> Bool {
        guard let normalized = normalize(csvValue) else { return false }
        return normalized == state.rawValue
    }

    static func normalize(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value.uppercased()
    }

    // Tenta resolver um valor vindo do CSV (nome por extenso ou sigla UF) para um BrazilianState
    static func fromCSV(_ value: String?) -> BrazilianState? {
        guard let norm = normalize(value) else { return nil }
        // 1) Match por nome por extenso (rawValue)
        if let st = allCases.first(where: { $0.rawValue == norm }) {
            return st
        }
        // 2) Match por sigla UF
        let byUF: [String: BrazilianState] = [
            "AC": .acre, "AL": .alagoas, "AP": .amapa, "AM": .amazonas, "BA": .bahia,
            "CE": .ceara, "DF": .distritoFederal, "ES": .espiritoSanto, "GO": .goias, "MA": .maranhao,
            "MT": .matoGrosso, "MS": .matoGrossoDoSul, "MG": .minasGerais, "PA": .para, "PB": .paraiba,
            "PR": .parana, "PE": .pernambuco, "PI": .piaui, "RJ": .rioDeJaneiro, "RN": .rioGrandeDoNorte,
            "RS": .rioGrandeDoSul, "RO": .rondonia, "RR": .roraima, "SC": .santaCatarina, "SP": .saoPaulo,
            "SE": .sergipe, "TO": .tocantins
        ]
        return byUF[norm]
    }
}

