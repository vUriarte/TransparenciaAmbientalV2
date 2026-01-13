import CoreData
import CoreLocation

extension FireFocusEntity {

    static func upsert(into ctx: NSManagedObjectContext, focus: FireFocus, dayKey: Date) -> FireFocusEntity {
        let req = NSFetchRequest<FireFocusEntity>(entityName: "FireFocusEntity")
        req.predicate = NSPredicate(format: "id == %@", focus.id)
        req.fetchLimit = 1

        let obj = (try? ctx.fetch(req).first) ?? FireFocusEntity(context: ctx)
        obj.id = focus.id
        obj.latitude = focus.coordinate.latitude
        obj.longitude = focus.coordinate.longitude
        obj.date = focus.date
        obj.dayKey = dayKey
        obj.satelite = focus.satelite
        obj.municipio = focus.municipio
        obj.estado = focus.estado
        if let n = focus.numeroDiasSemChuva { obj.numeroDiasSemChuva = Int16(n) } else { obj.numeroDiasSemChuva = 0 }
        obj.riscoFogo = focus.riscoFogo
        obj.bioma = focus.bioma
        if let v = focus.frp { obj.frp = v } else { obj.frp = 0 }
        return obj
    }

    func toDomain() -> FireFocus {
        FireFocus(
            id: id ?? UUID().uuidString,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            satelite: satelite,
            municipio: municipio,
            estado: estado,
            numeroDiasSemChuva: Int(numeroDiasSemChuva),
            riscoFogo: riscoFogo,
            bioma: bioma,
            frp: frp == 0 ? nil : frp,
            date: date
        )
    }
}
