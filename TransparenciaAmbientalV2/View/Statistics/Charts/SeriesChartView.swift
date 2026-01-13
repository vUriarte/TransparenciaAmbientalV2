import SwiftUI
import Combine
import Charts

struct SeriesChartView: View {
    let points: [TimePoint]
    let metric: StatisticsView.SeriesMetric
    let domain: ClosedRange<Date>

    var body: some View {
        // Máximo da série conforme a métrica selecionada
        let yMaxRaw: Double = {
            switch metric {
            case .count:
                return Double(points.map { $0.count }.max() ?? 0)
            case .frp:
                return points.map { $0.frpSum }.max() ?? 0
            }
        }()

        // Garante um domínio mínimo visível quando todos os valores são 0
        let yMax: Double = yMaxRaw > 0 ? yMaxRaw * 1.1 : 1.0
        let isFlatZeroSeries = yMaxRaw == 0

        Chart {
            switch metric {
            case .count:
                ForEach(points) { p in
                    LineMark(
                        x: .value("Data", p.date),
                        y: .value("Qtde", p.count)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)
                    .symbol(Circle())
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                if let last = points.last {
                    PointMark(
                        x: .value("Data", last.date),
                        y: .value("Qtde", last.count)
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .topTrailing) {
                        Text("\(last.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }

            case .frp:
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Data", p.date),
                        y: .value("FRP Σ", p.frpSum)
                    )
                    .foregroundStyle(.green.opacity(0.25))
                    .interpolationMethod(.monotone)
                }
                ForEach(points) { p in
                    LineMark(
                        x: .value("Data", p.date),
                        y: .value("FRP Σ", p.frpSum)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                if let last = points.last {
                    PointMark(
                        x: .value("Data", last.date),
                        y: .value("FRP Σ", last.frpSum)
                    )
                    .foregroundStyle(.green)
                    .annotation(position: .topTrailing) {
                        Text(StatisticsFormatter.number(last.frpSum))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: points.map(\.date)) {
                AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                AxisTick()
                AxisValueLabel(format: .dateTime.day(.defaultDigits))
            }
        }
        .chartYAxis {
            if isFlatZeroSeries {
                // Força rótulos para 0 e 1 quando a série é toda zero
                AxisMarks(values: [0, 1]) {
                    AxisGridLine().foregroundStyle(.gray.opacity(0.08))
                    AxisTick()
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            } else {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(.gray.opacity(0.08))
                    AxisTick()
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(Color(.systemBackground))
                .cornerRadius(6)
        }
        // Domínios fixos: X (período) e Y (mínimo 0…1 quando todos os valores são 0)
        .chartXScale(domain: domain)
        .chartYScale(domain: 0...yMax)
        // Rótulo compacto indicando a métrica selecionada (Qtde ou FRP Σ)
        .overlay(alignment: .topLeading) {
            MetricBadge(text: metric == .count ? "Métrica: Qtde" : "Métrica: FRP Σ")
                .padding(.top, 6)
                .padding(.leading, 6)
        }
    }
}
