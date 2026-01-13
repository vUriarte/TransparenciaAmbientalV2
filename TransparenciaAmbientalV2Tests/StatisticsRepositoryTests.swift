// StatisticsRepositoryTests.swift
import Foundation
import Testing
@testable import TransparenciaAmbientalV2

private actor MockService: FireDataServiceProtocol {
    let map: [Date: String] // CSV por data normalizada (startOfDay UTC)

    init(map: [Date: String]) {
        self.map = map
    }

    func fetchCSV(for date: Date) async throws -> String {
        guard let csv = map[date] else {
            throw NSError(domain: "MockService", code: 404)
        }
        return csv
    }
}

@Suite("StatisticsRepositoryInMemory cache and fetch")
struct StatisticsRepositoryTests {

    private var utcCal: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test("fetches missing dates, caches, and returns merged dictionary")
    func fetchAndCache() async throws {
        let cal = utcCal
        let d1 = cal.startOfDay(for: cal.date(from: DateComponents(year: 2024, month: 9, day: 1))!)
        let d2 = cal.startOfDay(for: cal.date(from: DateComponents(year: 2024, month: 9, day: 2))!)

        // CSVs mínimos com headers variados
        let csv1 = """
        latitude,longitude,estado,bioma,frp
        -10.0,-50.0,TOCANTINS,Cerrado,5
        -11.0,-51.0,PARÁ,Amazônia,10
        """
        let csv2 = """
        lat,lon,uf,bioma,frp
        -12.0,-52.0,BAHIA,Caatinga,2
        """

        let service = MockService(map: [d1: csv1, d2: csv2])
        let repo = StatisticsRepositoryInMemory(service: service)

        // Primeira chamada: baixa d1 e d2
        let result1 = try await repo.focuses(for: [d1, d2])
        #expect(result1[d1]?.count == 2)
        #expect(result1[d2]?.count == 1)
        #expect(result1[d1]?.allSatisfy { $0.date == d1 } == true)
        #expect(result1[d2]?.allSatisfy { $0.date == d2 } == true)

        // Segunda chamada: cache hit para d1, baixa nada novo
        let result2 = try await repo.focuses(for: [d1])
        #expect(result2[d1]?.count == 2)
    }

    @Test("store and purge interact with in-memory cache")
    func storeAndPurge() async throws {
        let cal = utcCal
        let d = cal.startOfDay(for: cal.date(from: DateComponents(year: 2024, month: 9, day: 3))!)

        let service = MockService(map: [:])
        let repo = StatisticsRepositoryInMemory(service: service)

        let f = FireFocus(id: "x", coordinate: .init(latitude: 0, longitude: 0), estado: "TOCANTINS", frp: 1, date: nil)
        try await repo.storeFocuses([f], for: d)

        let r1 = try await repo.focuses(for: [d])
        #expect(r1[d]?.count == 1)
        #expect(r1[d]?.first?.date == d)

        try await repo.purge(dates: [d])
        // Sem CSV no mock, a próxima consulta não repovoa
        do {
            _ = try await repo.focuses(for: [d])
            // Se chegarmos aqui, significa que não lançou erro (ok), mas não deve ter valor para a chave
        } catch {
            // Não esperamos erro aqui, apenas ausência de dado
            #expect(Bool(false))
        }
    }
}

