import SwiftUI

struct SummaryCardsView: View {
    let summary: StatsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resumo").font(.headline)
            HStack {
                kpiCard(title: "Focos", value: "\(summary.totalFocos)")
                kpiCard(title: "FRP Σ", value: StatisticsFormatter.number(summary.frpSum))
                kpiCard(title: "FRP Média", value: StatisticsFormatter.optionalNumber(summary.frpAvg))
            }
            HStack {
                kpiCard(title: "FRP Mediana", value: StatisticsFormatter.optionalNumber(summary.frpMedian))
                kpiCard(title: "FRP P90", value: StatisticsFormatter.optionalNumber(summary.frpP90))
                kpiCard(title: "FRP Máx", value: StatisticsFormatter.optionalNumber(summary.frpMax))
            }
        }
    }

    private func kpiCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            // Valor alinhado à direita e sem quebra de linha
            Text(value)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }
}
