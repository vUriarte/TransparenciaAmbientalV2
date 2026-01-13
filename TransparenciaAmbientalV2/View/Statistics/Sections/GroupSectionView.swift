import SwiftUI

struct GroupSectionView: View {
    @Binding var selectedGroupTab: StatisticsView.GroupTab
    @Binding var groupMetric: StatisticsView.GroupMetric

    let byState: [GroupStat]
    let byBiome: [GroupStat]
    let byMunicipio: [GroupStat]
    let topN: Int

    var emptyTextProvider: (String) -> AnyView = { AnyView(Text($0)) }

    init(
        selectedGroupTab: Binding<StatisticsView.GroupTab>,
        groupMetric: Binding<StatisticsView.GroupMetric>,
        byState: [GroupStat],
        byBiome: [GroupStat],
        byMunicipio: [GroupStat],
        topN: Int,
        emptyTextProvider: @escaping (String) -> some View
    ) {
        self._selectedGroupTab = selectedGroupTab
        self._groupMetric = groupMetric
        self.byState = byState
        self.byBiome = byBiome
        self.byMunicipio = byMunicipio
        self.topN = topN
        self.emptyTextProvider = { AnyView(emptyTextProvider($0)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top \(topN) por grupo").font(.headline)
                Spacer()
                Picker("Métrica", selection: $groupMetric) {
                    ForEach(StatisticsView.GroupMetric.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }

            Picker("Grupo", selection: $selectedGroupTab) {
                ForEach(StatisticsView.GroupTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            let data: [GroupStat] = {
                switch selectedGroupTab {
                case .state: return byState
                case .biome: return byBiome
                case .municipio: return byMunicipio
                }
            }()

            #if canImport(Charts)
            if !data.isEmpty {
                GroupChartView(data: data, metric: groupMetric)
                    .frame(minHeight: 220)
                    .padding(.vertical, 6)
            } else {
                emptyTextProvider("Sem dados para os filtros selecionados.")
            }
            #else
            VStack(spacing: 6) {
                ForEach(data) { item in
                    HStack {
                        Text(item.key).lineLimit(1)
                        Spacer()
                        Text("\(item.count)")
                        Text("•")
                        Text(StatisticsFormatter.number(item.frpSum))
                        Text("•")
                        Text(StatisticsFormatter.percent(item.share))
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                if data.isEmpty {
                    emptyTextProvider("Sem dados para os filtros selecionados.")
                }
            }
            #endif
        }
    }
}
