import SwiftUI

/// Listen-mode picker drawn as a glass segmented control: a recessed track with
/// a raised thumb that springs across to the chosen mode.
///
/// Shared by the menu-bar panel and the settings window so both surfaces show
/// the same control.
struct ListenModePicker: View {
    let modes: [NoiseControlMode]
    let selection: NoiseControlMode
    var tint: Color = .accentColor
    var height: CGFloat = 54
    let onSelect: (NoiseControlMode) -> Void

    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(modes) { mode in
                segment(mode)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.glassTrack)
        )
        .animation(.glass, value: selection)
    }

    private func segment(_ mode: NoiseControlMode) -> some View {
        let selected = mode == selection
        return Button { onSelect(mode) } label: {
            VStack(spacing: 4) {
                Image(systemName: mode.iconName)
                    .font(.system(size: height * 0.32, weight: .medium))
                    .symbolEffect(.bounce, value: selected)
                Text(LocalizedStringKey(mode.shortName))
                    .font(.system(size: 11, weight: selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Color.glassOnThumb : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.glassThumb)
                        .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
                        .matchedGeometryEffect(id: "thumb", in: thumb)
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text(LocalizedStringKey(mode.displayName)))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
