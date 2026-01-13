import SwiftUI
import Charts

struct GroupChartView: View {
    let data: [GroupStat]
    let metric: StatisticsView.GroupMetric

    var body: some View {
        Chart {
            ForEach(data) { item in
                switch metric {
                case .count:
                    BarMark(
                        x: .value("Qtde", item.count),
                        y: .value("Grupo", item.key)
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                case .frp:
                    BarMark(
                        x: .value("FRP Σ", item.frpSum),
                        y: .value("Grupo", item.key)
                    )
                    .foregroundStyle(.orange)
                    .annotation(position: .trailing) {
                        Text(number(item.frpSum))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartLegend(.hidden)
    }

    private func number(_ x: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: x)) ?? "\(x)"
    }
}
