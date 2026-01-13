import Foundation
import CoreLocation

struct FireFocus: Identifiable {
    // Identificador estável: usa a coluna "id" do CSV quando disponível
    let id: String
    let coordinate: CLLocationCoordinate2D

    // Campos parseados do CSV
    let satelite: String?
    let municipio: String?
    let estado: String?
    let numeroDiasSemChuva: Int?
    let riscoFogo: String?
    let bioma: String?
    let frp: Double?

    // Data associada ao foco (preenchida pelo repositório de estatísticas com a data do CSV)
    let date: Date?

    // Construtor completo
    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        satelite: String? = nil,
        municipio: String? = nil,
        estado: String? = nil,
        numeroDiasSemChuva: Int? = nil,
        riscoFogo: String? = nil,
        bioma: String? = nil,
        frp: Double? = nil,
        date: Date? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.satelite = satelite
        self.municipio = municipio
        self.estado = estado
        self.numeroDiasSemChuva = numeroDiasSemChuva
        self.riscoFogo = riscoFogo
        self.bioma = bioma
        self.frp = frp
        self.date = date
    }

    // Construtor prático usado por testes/uso manual mínimo
    init(
        coordinate: CLLocationCoordinate2D,
        estado: String? = nil,
        bioma: String? = nil,
        date: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.coordinate = coordinate
        self.satelite = nil
        self.municipio = nil
        self.estado = estado
        self.numeroDiasSemChuva = nil
        self.riscoFogo = nil
        self.bioma = bioma
        self.frp = nil
        self.date = date
    }

    // Compatibilidade: inicializador que aceita "raw" e mapeia para os campos conhecidos
    init(coordinate: CLLocationCoordinate2D, raw: [String: String], date: Date? = nil) {
        let normalized = CSVKeyNormalization.normalizeKeys(raw)

        let idFromRaw = CSVKeyNormalization.trim(raw["id"])
        self.id = (idFromRaw?.isEmpty == false ? idFromRaw! : UUID().uuidString)
        self.coordinate = coordinate

        self.satelite = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["satelite", "satélite", "satellite"])
        self.municipio = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["municipio", "município"])
        self.estado = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["estado", "uf"])
        self.numeroDiasSemChuva = Int(CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["numero_dias_sem_chuva", "dias_sem_chuva", "diassemschuva"]) ?? "")
        self.riscoFogo = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["risco_fogo", "risco", "riscofogo"])
        self.bioma = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["bioma"])

        if let frpRaw = CSVKeyNormalization.value(in: raw, normalized: normalized, keys: ["frp"]),
           let frpParsed = CSVKeyNormalization.parseDecimal(frpRaw) {
            self.frp = frpParsed
        } else {
            self.frp = nil
        }
        self.date = date
    }

    // Compatibilidade: construtor completo com id + raw (para testes)
    init(id: String, coordinate: CLLocationCoordinate2D, raw: [String: String], date: Date? = nil) {
        self.init(coordinate: coordinate, raw: raw, date: date)
        self = FireFocus(
            id: id,
            coordinate: coordinate,
            satelite: self.satelite,
            municipio: self.municipio,
            estado: self.estado,
            numeroDiasSemChuva: self.numeroDiasSemChuva,
            riscoFogo: self.riscoFogo,
            bioma: self.bioma,
            frp: self.frp,
            date: date
        )
    }

    func with(date: Date) -> FireFocus {
        FireFocus(
            id: id,
            coordinate: coordinate,
            satelite: satelite,
            municipio: municipio,
            estado: estado,
            numeroDiasSemChuva: numeroDiasSemChuva,
            riscoFogo: riscoFogo,
            bioma: bioma,
            frp: frp,
            date: date
        )
    }
}

