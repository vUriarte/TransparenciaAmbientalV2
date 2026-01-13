import SwiftUI

struct FiltersBarView: View {
    let stateLabel: String
    let biomeLabel: String
    let onTapState: () -> Void
    let onTapBiome: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)

            FilterPill(
                title: "Estado",
                value: stateLabel,
                systemImage: "mappin.circle",
                action: onTapState
            )

            FilterPill(
                title: "Bioma",
                value: biomeLabel,
                systemImage: "leaf",
                action: onTapBiome
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}


