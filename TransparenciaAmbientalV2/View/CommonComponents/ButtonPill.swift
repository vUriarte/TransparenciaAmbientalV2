import SwiftUI

struct ButtonPillStyle: ButtonStyle {
    var enabledBackground = Color(.secondarySystemBackground).opacity(0.9)
    var disabledBackground = Color(.tertiarySystemFill)
    var enabledStroke = Color.secondary.opacity(0.15)
    var disabledStroke = Color.secondary.opacity(0.07)
    var enabledForeground = Color.primary
    var disabledForeground = Color.secondary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 36)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isEnabled ? enabledForeground : disabledForeground)
            .background(
                (isEnabled ? enabledBackground : disabledBackground)
                    .opacity(configuration.isPressed && isEnabled ? 0.95 : 1.0)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isEnabled ? enabledStroke : disabledStroke, lineWidth: 0.5)
            )
            .contentShape(Capsule())
            .shadow(color: Color.black.opacity(isEnabled ? 0.06 : 0.0), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
    }
}

struct ButtonPillLabelPStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .imageScale(.medium)
                .foregroundStyle(.secondary)

            configuration.title
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
    }
}
