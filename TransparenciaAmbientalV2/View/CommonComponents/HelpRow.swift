import SwiftUI

struct HelpRow: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .bold()
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
