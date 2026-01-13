import Foundation

struct StatisticsEngine: StatisticsEngineProtocol {

    func summarize(focuses: [FireFocus]) -> StatsSummary {
        let frps = focuses.compactMap { $0.frp }
        let total = focuses.count
        let sum = frps.reduce(0.0, +)
        let avg: Double? = frps.isEmpty ? nil : sum / Double(frps.count)
        let sorted = frps.sorted()
        let median: Double? = percentile(sorted, p: 50)
        let p90: Double? = percentile(sorted, p: 90)
        let maxVal: Double? = frps.max()

        return StatsSummary(
            totalFocos: total,
            frpSum: sum,
            frpAvg: avg,
            frpMedian: median,
            frpP90: p90,
            frpMax: maxVal
        )
    }

    func group(focuses: [FireFocus], by key: StatsGroupingKey, topN: Int, orderBy: GroupOrderBy) -> [GroupStat] {
        guard !focuses.isEmpty, topN > 0 else { return [] }
        let totalCount = focuses.count

        let groups: [String: (count: Int, frpSum: Double)] = focuses.reduce(into: [:]) { acc, f in
            let k = groupingKeyValue(for: f, by: key)
            var current = acc[k] ?? (0, 0.0)
            current.count += 1
            if let frp = f.frp {
                current.frpSum += frp
            }
            acc[k] = current
        }

        var stats = groups.map { (k, v) in
            GroupStat(
                key: k,
                count: v.count,
                frpSum: v.frpSum,
                share: totalCount > 0 ? Double(v.count) / Double(totalCount) : 0.0
            )
        }

        stats.sort { a, b in
            switch orderBy {
            case .count:
                if a.count != b.count { return a.count > b.count }
                if a.frpSum != b.frpSum { return a.frpSum > b.frpSum }
                return a.key.localizedCaseInsensitiveCompare(b.key) == .orderedAscending
            case .frpSum:
                if a.frpSum != b.frpSum { return a.frpSum > b.frpSum }
                if a.count != b.count { return a.count > b.count }
                return a.key.localizedCaseInsensitiveCompare(b.key) == .orderedAscending
            }
        }

        if stats.count > topN {
            stats = Array(stats.prefix(topN))
        }
        return stats
    }

    func timeSeries(
        focuses: [FireFocus],
        calendar: Calendar,
        start: Date,
        end: Date
    ) -> [TimePoint] {
        
        let dateStart = calendar.startOfDay(for: start)
        let dateEnd = calendar.startOfDay(for: end)

        // Agrega focos por bucket
        var agg: [Date: (count: Int, frpSum: Double)] = [:]
        for f in focuses {
            guard let date = f.date else { continue }
            let s = calendar.startOfDay(for: date)
            // Só considera focos que caem dentro do intervalo solicitado
            if s < dateStart || s > dateEnd { continue }
            var cur = agg[s] ?? (0, 0.0)
            cur.count += 1
            if let frp = f.frp {
                cur.frpSum += frp
            }
            agg[s] = cur
        }

        // Gera todos os buckets do intervalo, preenchendo zeros quando necessário
        var points: [TimePoint] = []
        var cursor = dateStart
        while cursor <= dateEnd {
            let v = agg[cursor] ?? (0, 0.0)
            points.append(TimePoint(date: cursor, count: v.count, frpSum: v.frpSum))
            let next = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            // Evita loop infinito em caso de calendário patológico
            if next == cursor { break }
            cursor = calendar.startOfDay(for: next)
        }

        return points
    }

    // MARK: - Helpers

    private func groupingKeyValue(for f: FireFocus, by key: StatsGroupingKey) -> String {
        switch key {
        case .state:
            // Normaliza para maiúsculas (compatível com BrazilianState.normalize)
            return BrazilianState.normalize(f.estado) ?? "Desconhecido"
        case .biome:
            return f.bioma?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Desconhecido"
        case .municipio:
            let muni = f.municipio?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Desconhecido"
            if let st = BrazilianState.fromCSV(f.estado) {
                return "\(muni) (\(st.uf))"
            } else if let ufCandidate = BrazilianState.normalize(f.estado), ufCandidate.count == 2 {
                return "\(muni) (\(ufCandidate))"
            } else {
                return muni
            }
        }
    }

    // Percentil nearest-rank (p em 0..100), requer array já ordenado ascendente
    private func percentile(_ sorted: [Double], p: Int) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let clamped = max(0, min(100, p))
        if clamped == 0 { return sorted.first }
        if clamped == 100 { return sorted.last }
        let rank = Int(ceil(Double(clamped) / 100.0 * Double(sorted.count)))
        let idx = max(0, min(sorted.count - 1, rank - 1))
        return sorted[idx]
    }
}
