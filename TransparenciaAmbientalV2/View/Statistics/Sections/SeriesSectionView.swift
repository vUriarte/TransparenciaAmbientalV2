import SwiftUI
import Combine

#if canImport(Charts)
import Charts
#endif

struct SeriesSectionView: View {
    @Binding var seriesMetric: StatisticsView.SeriesMetric
    let points: [TimePoint]

    let emptyTextProvider: (String) -> AnyView
    let startDate: Date
    let endDate: Date

    init(
        seriesMetric: Binding<StatisticsView.SeriesMetric>,
        points: [TimePoint],
        emptyTextProvider: @escaping (String) -> some View,
        startDate: Date,
        endDate: Date
    ) {
        self._seriesMetric = seriesMetric
        self.points = points
        self.emptyTextProvider = { AnyView(emptyTextProvider($0)) }
        self.startDate = startDate
        self.endDate = endDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Série temporal").font(.headline)
                Spacer()
                Picker("Métrica", selection: $seriesMetric) {
                    ForEach(StatisticsView.SeriesMetric.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }

            #if canImport(Charts)
            if !points.isEmpty {
                SeriesChartView(
                    points: points,
                    metric: seriesMetric,
                    domain: startDate...endDate
                )
                .frame(minHeight: 240)
                .padding(.vertical, 6)
            } else {
                emptyTextProvider("Sem pontos na série para os filtros selecionados.")
            }
            #else
            VStack(spacing: 6) {
                ForEach(points) { p in
                    HStack {
                        Text(StatisticsFormatter.date(p.date))
                        Spacer()
                        if seriesMetric == .count {
                            Text("\(p.count) focos")
                        } else {
                            Text(StatisticsFormatter.number(p.frpSum))
                        }
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                if points.isEmpty {
                    emptyTextProvider("Sem pontos na série para os filtros selecionados.")
                }
            }
            #endif
        }
    }
}
