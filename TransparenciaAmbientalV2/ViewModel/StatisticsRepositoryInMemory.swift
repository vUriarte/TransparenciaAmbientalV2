import Foundation

actor StatisticsRepositoryInMemory: StatisticsRepositoryProtocol {
    private let service: FireDataServiceProtocol
    private var cache: [Date: [FireFocus]] = [:]

    // Datas normalizadas para início do dia em UTC para chaveamento consistente
    private let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    init(service: FireDataServiceProtocol) async {
        self.service = service
    }

    func focuses(for dates: [Date]) async throws -> [Date: [FireFocus]] {
        var result: [Date: [FireFocus]] = [:]
        result.reserveCapacity(dates.count)

        for date in dates {
            let key = normalizedDay(date)
            if let cached = cache[key] {
                result[key] = cached
                continue
            }

            // Fetch do CSV e parse
            let csv = try await service.fetchCSV(for: key)
            let parsed = await MainActor.run { CSVParser.parseCSV(csv) }
            let mapped = await MainActor.run {
                FireFocusRowMapper.mapAll(headers: parsed.headers, rows: parsed.rows)
            }

            // Injeta a data normalizada em cada foco
            let withDate = await MainActor.run {
                mapped.map { $0.with(date: key) }
            }
            
            cache[key] = withDate
            result[key] = withDate
        }

        return result
    }

    func storeFocuses(_ focuses: [FireFocus], for date: Date) async throws {
        let key = normalizedDay(date)
        let withDate: [FireFocus] = await MainActor.run {
            focuses.map { $0.with(date: key) }
        }
        cache[key] = withDate
    }

    func purge(dates: [Date]) async throws {
        for d in dates {
            cache.removeValue(forKey: normalizedDay(d))
        }
    }

    // MARK: - Helpers

    private func normalizedDay(_ date: Date) -> Date {
        utcCalendar.startOfDay(for: date)
    }
}
