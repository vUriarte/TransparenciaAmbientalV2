import Foundation
import CoreData
import CoreLocation
import os

private let statsLog = OSLog(subsystem: "br.uriarte.transparencia", category: "stats")

#if DEBUG

@inline(__always)
private func DLog(_ items: Any...) {
    print("📊", items.map { "\($0)" }.joined(separator: " "))
}
#else
@inline(__always)
private func DLog(_ items: Any...) {}
#endif

actor StatisticsRepositoryCoreData: StatisticsRepositoryProtocol {
    private let service: FireDataServiceProtocol
    private let stack: CoreDataStack
    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    init(service: FireDataServiceProtocol, stack: CoreDataStack) async {
        self.service = service
        self.stack = stack
    }

    func focuses(for dates: [Date]) async throws -> [Date: [FireFocus]] {
        let t0 = CFAbsoluteTimeGetCurrent()
        let keys = dates.map { utc.startOfDay(for: $0) }
        var result: [Date: [FireFocus]] = [:]

        // Cache local
        let local = try await fetchLocal(keys: keys)
        for (k, arr) in local { result[k] = arr }
        let localCount = local.values.reduce(0) { $0 + $1.count }

        // Dias faltantes
        let missing = keys.filter { (result[$0]?.isEmpty ?? true) }
        await DLog("focuses(for:)", "days:", keys.count,
                   "from-cache:", localCount,
                   "missing-days:", missing.count)
        await os_log("stats.local keys=%d localCount=%d missing=%d", log: statsLog, type: .info,
               keys.count, localCount, missing.count)

        // Baixar faltantes
        var downloadedCount = 0
        if !missing.isEmpty {
            let dlT0 = CFAbsoluteTimeGetCurrent()
            let downloaded = try await fetchRemoteAndPersist(days: missing)
            for (k, arr) in downloaded {
                result[k] = arr
                downloadedCount += arr.count
            }
            let dlMs = Int((CFAbsoluteTimeGetCurrent() - dlT0) * 1000)
            await DLog("downloaded-days:", downloaded.count,
                       "downloaded-focos:", downloadedCount,
                       "timeMs:", dlMs)
        }

        let totalMs = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        let totalCount = result.values.reduce(0) { $0 + $1.count }
        await DLog("focuses(total):", totalCount, "timeMs:", totalMs)

        return result
    }
    
    private func fmtDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    func storeFocuses(_ focuses: [FireFocus], for date: Date) async throws {
        let key = utc.startOfDay(for: date)
        try await persist(focuses: focuses, for: key)
    }
    

    func purge(dates: [Date]) async throws {
        let keys = dates.map { utc.startOfDay(for: $0) }
        // Hop para o MainActor para criar um novo contexto em background
        let ctx: NSManagedObjectContext = await MainActor.run { stack.newBackgroundContext() }

        let deletedIDs: [NSManagedObjectID] = try await ctx.perform {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: "FireFocusEntity")
            req.predicate = NSPredicate(format: "dayKey IN %@", keys as NSArray)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            del.resultType = .resultTypeObjectIDs
            let res = try ctx.execute(del) as? NSBatchDeleteResult
            return (res?.result as? [NSManagedObjectID]) ?? []
        }

        if !deletedIDs.isEmpty {
            await MainActor.run {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs], into: [self.stack.viewContext])
            }
        }
    }

    @MainActor private func fetchLocal(keys: [Date]) throws -> [Date: [FireFocus]] {
        let ctx = stack.viewContext

        // Request novo e “limpo” para garantir o tipo correto:
        let req = NSFetchRequest<FireFocusEntity>(entityName: "FireFocusEntity")
        req.resultType = .managedObjectResultType
        req.propertiesToFetch = nil
        req.returnsDistinctResults = false

        req.predicate = NSPredicate(format: "dayKey IN %@", keys as NSArray)
        req.sortDescriptors = [
            NSSortDescriptor(key: "dayKey", ascending: true),
            NSSortDescriptor(key: "id", ascending: true)
        ]

        let rows = try ctx.fetch(req)

        return Dictionary(grouping: rows, by: { $0.dayKey ?? Date.distantPast })
            .mapValues { $0.map { $0.toDomain() } }
    }

    private func fetchRemoteAndPersist(days: [Date]) async throws -> [Date: [FireFocus]] {
        var out: [Date: [FireFocus]] = [:]
        out.reserveCapacity(days.count)

        // Limitar concorrencia, evitar picos de CPU e pressão de memória
        let maxConcurrent = 2
        var index = 0
        while index < days.count {
            let end = min(index + maxConcurrent, days.count)
            let slice = Array(days[index..<end])
            try await withThrowingTaskGroup(of: (Date, [FireFocus]).self) { group in
                for day in slice {
                    group.addTask { try await (day, self.download(day: day)) }
                }
                for try await (day, focuses) in group { out[day] = focuses }
            }
            index = end
            await DLog("batch days:", slice.map { fmtDay($0) }.joined(separator: ","))
        }
        return out
    }

    private func download(day: Date) async throws -> [FireFocus] {
        let csv = try await service.fetchCSV(for: day)
        let parsed = await MainActor.run { CSVParser.parseCSV(csv) }
        let mappedRaw = await MainActor.run { FireFocusRowMapper.mapAll(headers: parsed.headers, rows: parsed.rows) }
        let mapped: [FireFocus] = await MainActor.run {
            mappedRaw.map {
                FireFocus(
                    id: $0.id,
                    coordinate: $0.coordinate,
                    satelite: $0.satelite,
                    municipio: $0.municipio,
                    estado: $0.estado,
                    numeroDiasSemChuva: $0.numeroDiasSemChuva,
                    riscoFogo: $0.riscoFogo,
                    bioma: $0.bioma,
                    frp: $0.frp,
                    date: $0.date ?? day
                )
            }
        }
        try await persist(focuses: mapped, for: day)
        return mapped
    }

    private func persist(focuses: [FireFocus], for dayKey: Date) async throws {
        guard !focuses.isEmpty else { return }
        // Hop para o MainActor para criar um novo contexto em background
        let ctx: NSManagedObjectContext = await MainActor.run { stack.newBackgroundContext() }
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.undoManager = nil

        let t0 = CFAbsoluteTimeGetCurrent()
        let stats = try await ctx.perform { () throws -> (processed: Int, existingCount: Int, inserted: Int, skipped: Int) in
            // 1) IDs existentes do dia
            let idReq = NSFetchRequest<NSDictionary>(entityName: "FireFocusEntity")
            idReq.resultType = .dictionaryResultType
            idReq.propertiesToFetch = ["id"]
            idReq.predicate = NSPredicate(format: "dayKey == %@", dayKey as NSDate)
            let existingDicts = try ctx.fetch(idReq)
            let existing: Set<String> = Set(existingDicts.compactMap { $0["id"] as? String })
            let existingCount = existing.count

            // 2) Inserções em lote
            var inserted = 0
            var skipped = 0
            var processed = 0

            for f in focuses {
                processed += 1
                if existing.contains(f.id) {
                    skipped += 1
                    continue
                }
                let obj = FireFocusEntity(context: ctx)
                obj.id = f.id
                obj.latitude = f.coordinate.latitude
                obj.longitude = f.coordinate.longitude
                obj.date = f.date
                obj.dayKey = dayKey
                obj.satelite = f.satelite
                obj.municipio = f.municipio
                obj.estado = f.estado
                obj.numeroDiasSemChuva = Int16(f.numeroDiasSemChuva ?? 0)
                obj.riscoFogo = f.riscoFogo
                obj.bioma = f.bioma
                obj.frp = f.frp ?? 0
                FireFocusEntity.applyBins(obj, from: f.coordinate)
                inserted += 1

                if inserted % 500 == 0 {
                    try ctx.save()
                    ctx.reset()
                }
            }

            if ctx.hasChanges {
                try ctx.save()
                ctx.reset()
            }

            return (processed, existingCount, inserted, skipped)
        }

        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        await DLog("persist day:", self.fmtDay(dayKey),
                   "processed:", stats.processed,
                   "existingIDs:", stats.existingCount,
                   "inserted:", stats.inserted,
                   "skipped:", stats.skipped,
                   "timeMs:", ms)
    }
}
