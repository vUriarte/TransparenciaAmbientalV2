import SwiftUI

struct StatisticsControlsView: View {
    @Binding var preset: StatisticsViewModel.PeriodPreset
    let stateLabel: String
    let biomeLabel: String
    let onTapState: () -> Void
    let onTapBiome: () -> Void
    @Binding var topN: Int
    @Binding var orderBy: GroupOrderBy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1) Presets de período
            Picker("Período", selection: $preset) {
                ForEach(StatisticsViewModel.PeriodPreset.allCases) { p in
                    Text(p.title).tag(p)
                }
            }
            .pickerStyle(.segmented)

            // 2) Filtros (Estado/Bioma)
            FiltersBarView(
                stateLabel: stateLabel,
                biomeLabel: biomeLabel,
                onTapState: onTapState,
                onTapBiome: onTapBiome
            )

            // 3) Top N centralizado em sua linha
            HStack {
                TopNControl(value: $topN, range: 1...20)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// Controle compacto para Top N centralizado, com "Top N" entre os botões −/+
private struct TopNControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 0) {
            // Botão menos
            Button {
                value = max(range.lowerBound, value - 1)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 34, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Diminuir Top")

            // Rótulo central "Top N"
            Text("Top \(value)")
                .font(.body)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(minWidth: 72) // garante área para centralização visual
                .padding(.horizontal, 8)

            // Botão mais
            Button {
                value = min(range.upperBound, value + 1)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 34, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Aumentar Top")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Top \(value)")
    }
}
