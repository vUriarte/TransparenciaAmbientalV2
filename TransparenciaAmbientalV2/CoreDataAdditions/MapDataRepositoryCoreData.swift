import Foundation
import CoreData
import MapKit
import os
private let mapLog = OSLog(subsystem: "br.uriarte.transparencia", category: "map")

protocol MapDataRepositoryProtocol {
    func pins(in region: MKCoordinateRegion, zoomLevel: Int, days: [Date], limitPerCell: Int) throws -> [FireFocus]
    func heatmap(in region: MKCoordinateRegion, zoomLevel: Int, days: [Date]) throws -> [HeatCell]
}

struct HeatCell: Hashable {
    let latBin: Int16
    let lonBin: Int16
    let count: Int
    let sample: FireFocus? 

    static func == (lhs: HeatCell, rhs: HeatCell) -> Bool {
        return lhs.latBin == rhs.latBin &&
               lhs.lonBin == rhs.lonBin &&
               lhs.count  == rhs.count
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(latBin)
        hasher.combine(lonBin)
        hasher.combine(count)
    }
}

final class MapDataRepositoryCoreData: MapDataRepositoryProtocol {
    private let stack: CoreDataStack
    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    init(stack: CoreDataStack = .shared) { self.stack = stack }

    // Pins
    func pins(in region: MKCoordinateRegion, zoomLevel: Int, days: [Date], limitPerCell: Int = 50) throws -> [FireFocus] {
        guard !days.isEmpty else { return [] }
        #if DEBUG
        let signpostID = OSSignpostID(log: mapLog)
        os_signpost(.begin, log: mapLog, name: "pins.fetch", signpostID: signpostID, "zoom=%d limitPerCell=%d", zoomLevel, limitPerCell)
        let t0 = CFAbsoluteTimeGetCurrent()
        #endif
        let keys = days.map { utc.startOfDay(for: $0) }
        let ctx = stack.viewContext

        let (latRange, lonRange) = MapGrid.bins(in: region, zoomLevel: zoomLevel)

        let req: NSFetchRequest<FireFocusEntity> = FireFocusEntity.fetchRequest()
        req.predicate = NSPredicate(format: "dayKey IN %@ AND latBin >= %d AND latBin <= %d AND lonBin >= %d AND lonBin <= %d",
                                    keys as NSArray, latRange.lowerBound, latRange.upperBound, lonRange.lowerBound, lonRange.upperBound)
        
        // Batch para salvar memória
        req.fetchBatchSize = 500
        req.returnsObjectsAsFaults = true

        let rows = try ctx.fetch(req)

        // Agrupa por (latBin, lonBin) e limita
        var buckets: [String: [FireFocus]] = [:]
        buckets.reserveCapacity(256)
        for e in rows {
            let key = "\(e.latBin)-\(e.lonBin)"
            var arr = buckets[key] ?? []
            if arr.count < limitPerCell {
                arr.append(e.toDomain())
                buckets[key] = arr
            }
        }
        
        #if DEBUG
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        let totalRows = rows.count
        let bucketCount = buckets.count
        let totalPins = buckets.values.reduce(0) { $0 + $1.count }
        os_signpost(.end, log: mapLog, name: "pins.fetch", signpostID: signpostID, "rows=%d buckets=%d pins=%d elapsed=%.3fs", totalRows, bucketCount, totalPins, elapsed)
        #endif
        return buckets.values.flatMap { $0 }
    }

    // Heatmap
    func heatmap(in region: MKCoordinateRegion, zoomLevel: Int, days: [Date]) throws -> [HeatCell] {
        guard !days.isEmpty else { return [] }
        #if DEBUG
        let signpostID = OSSignpostID(log: mapLog)
        os_signpost(.begin, log: mapLog, name: "heatmap.fetch", signpostID: signpostID, "zoom=%d", zoomLevel)
        let t0 = CFAbsoluteTimeGetCurrent()
        #endif
        let keys = days.map { utc.startOfDay(for: $0) }
        let ctx = stack.viewContext
        let (latRange, lonRange) = MapGrid.bins(in: region, zoomLevel: zoomLevel)

        let req = NSFetchRequest<NSDictionary>(entityName: "FireFocusEntity")
        req.resultType = .dictionaryResultType
        req.predicate = NSPredicate(format: "dayKey IN %@ AND latBin >= %d AND latBin <= %d AND lonBin >= %d AND lonBin <= %d",
                                    keys as NSArray, latRange.lowerBound, latRange.upperBound, lonRange.lowerBound, lonRange.upperBound)

        let count = NSExpressionDescription()
        count.name = "cnt"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "id")])
        count.expressionResultType = .integer32AttributeType

        req.propertiesToGroupBy = ["latBin", "lonBin"]
        req.propertiesToFetch = ["latBin", "lonBin", count]

        let dicts = try ctx.fetch(req)
        
        #if DEBUG
        let cells: [HeatCell] = dicts.compactMap { d in
            let latBin = d["latBin"] as? Int16
            let lonBin = d["lonBin"] as? Int16
            let cnt = d["cnt"] as? Int ?? 0
            if let latBin, let lonBin {
                return HeatCell(latBin: latBin, lonBin: lonBin, count: cnt, sample: nil)
            }
            return nil
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        os_signpost(.end, log: mapLog, name: "heatmap.fetch", signpostID: signpostID, "cells=%d elapsed=%.3fs", cells.count, elapsed)
        return cells
        #else
        return dicts.compactMap { d in
            let latBin = d["latBin"] as? Int16
            let lonBin = d["lonBin"] as? Int16
            let cnt = d["cnt"] as? Int ?? 0
            if let latBin, let lonBin {
                return HeatCell(latBin: latBin, lonBin: lonBin, count: cnt, sample: nil)
            }
            return nil
        }
        #endif

    }
}
