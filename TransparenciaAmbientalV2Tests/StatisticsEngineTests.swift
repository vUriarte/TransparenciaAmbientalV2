// StatisticsEngineTests.swift
import Foundation
import Testing
@testable import TransparenciaAmbientalV2

@Suite("StatisticsEngine basic metrics and aggregations")
struct StatisticsEngineTests {
    let engine = StatisticsEngine()

    private var utcCal: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test("summarize handles empty and FRP nil/zero correctly")
    func summarizeBasics() {
        let empty = engine.summarize(focuses: [])
        #expect(empty.totalFocos == 0)
        #expect(empty.frpSum == 0)
        #expect(empty.frpAvg == nil)
        #expect(empty.frpMedian == nil)
        #expect(empty.frpP90 == nil)
        #expect(empty.frpMax == nil)

        let d = Date(timeIntervalSince1970: 0)
        let f1 = FireFocus(id: "1", coordinate: .init(latitude: 0, longitude: 0), frp: nil, date: d)
        let f2 = FireFocus(id: "2", coordinate: .init(latitude: 0, longitude: 0), frp: 0, date: d)
        let f3 = FireFocus(id: "3", coordinate: .init(latitude: 0, longitude: 0), frp: 10, date: d)
        let f4 = FireFocus(id: "4", coordinate: .init(latitude: 0, longitude: 0), frp: 20, date: d)

        let sum = engine.summarize(focuses: [f1, f2, f3, f4])
        #expect(sum.totalFocos == 4)
        #expect(sum.frpSum == 30)
        #expect(sum.frpAvg == 10) // média sobre [0,10,20] = 30/3
        #expect(sum.frpMedian == 10) // valores ordenados [0,10,20] -> mediana nearest-rank de 50% é 10
        #expect(sum.frpP90 == 20) // nearest-rank 90% de 3 valores -> índice 2 -> 20
        #expect(sum.frpMax == 20)
    }

    @Test("group by state with Top N and deterministic tiebreak")
    func groupByState() {
        let d = Date(timeIntervalSince1970: 0)
        let items: [FireFocus] = [
            FireFocus(id: "a1", coordinate: .init(latitude: 0, longitude: 0), estado: "TOCANTINS", frp: 5, date: d),
            FireFocus(id: "a2", coordinate: .init(latitude: 0, longitude: 0), estado: "TOCANTINS", frp: 2, date: d),
            FireFocus(id: "b1", coordinate: .init(latitude: 0, longitude: 0), estado: "PARÁ", frp: 10, date: d),
            FireFocus(id: "c1", coordinate: .init(latitude: 0, longitude: 0), estado: "BAHIA", frp: nil, date: d),
            FireFocus(id: "d1", coordinate: .init(latitude: 0, longitude: 0), estado: nil, frp: 1, date: d),
        ]

        let top = engine.group(focuses: items, by: .state, topN: 2, orderBy: .count)
        #expect(top.count == 2)
        #expect(top[0].key == "TOCANTINS")
        #expect(top[0].count == 2)
        #expect(top[0].frpSum == 7)
        #expect(top[1].key == "PARÁ") // empate com BAHIA em count=1, mas PARÁ tem frpSum maior e desempate pela métrica
    }

    @Test("time series bucketing for day/week/month")
    func timeSeriesBuckets() {
        var cal = utcCal
        let d1 = cal.date(from: DateComponents(year: 2024, month: 9, day: 1))!
        let d2 = cal.date(from: DateComponents(year: 2024, month: 9, day: 2))!
        let d3 = cal.date(from: DateComponents(year: 2024, month: 9, day: 10))!

        let items: [FireFocus] = [
            FireFocus(id: "1", coordinate: .init(latitude: 0, longitude: 0), frp: 1, date: d1),
            FireFocus(id: "2", coordinate: .init(latitude: 0, longitude: 0), frp: 2, date: d1),
            FireFocus(id: "3", coordinate: .init(latitude: 0, longitude: 0), frp: 3, date: d2),
            FireFocus(id: "4", coordinate: .init(latitude: 0, longitude: 0), frp: 4, date: d3),
        ]

        let day = engine.timeSeries(focuses: items, bucket: .day, calendar: cal)
        #expect(day.count == 3)
        #expect(day[0].date == cal.startOfDay(for: d1))
        #expect(day[0].count == 2)
        #expect(day[0].frpSum == 3)

        let week = engine.timeSeries(focuses: items, bucket: .week, calendar: cal)
        #expect(!week.isEmpty)

        let month = engine.timeSeries(focuses: items, bucket: .month, calendar: cal)
        #expect(month.count == 1)
        #expect(month[0].count == 4)
        #expect(month[0].frpSum == 10)
    }
}

