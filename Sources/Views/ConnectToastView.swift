import SwiftUI

/// The small AirPods-style card that drops in when the buds connect: device,
/// "Connected" and the battery levels. It dismisses itself after a few
/// seconds; clicking it opens the full panel.
struct ConnectToastView: View {
    @Bindable var bluetooth: BluetoothManager
    let onTap: () -> Void

    private var status: BudsStatus { bluetooth.status }
    private var model: BudsModel? { bluetooth.connectedModel }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "earbuds")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: bluetooth.connectedName ?? model?.rawValue ?? "Galaxy Buds")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Circle().fill(Color.batteryGreen).frame(width: 6, height: 6)
                        Text("Connected").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    CircularBatteryGauge(
                        level: status.batteryLeft, label: "L",
                        present: status.batteryLeft > 0, charging: status.isLeftCharging,
                        diameter: 30)
                    CircularBatteryGauge(
                        level: status.batteryRight, label: "R",
                        present: status.batteryRight > 0, charging: status.isRightCharging,
                        diameter: 30)
                    if model?.supportsCaseBattery == true && status.batteryCase > 0 {
                        CircularBatteryGauge(
                            level: status.batteryCase, label: "Case",
                            present: true, diameter: 30, kind: .budsCase)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: 330)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .background(VisualEffectBackground(material: .popover, cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.glassEdge, lineWidth: 0.5)
        )
        .focusEffectDisabled()
    }
}
