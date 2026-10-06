import AppKit
import SwiftUI

/// The compact glass panel shown from the menu-bar icon — a Control Center
/// style quick view. Detailed controls live in the settings window.
struct MenuPopoverView: View {
    @Bindable var bluetooth: BluetoothManager
    let openDetail: (DashboardSection) -> Void

    private var status: BudsStatus { bluetooth.status }
    private var model: BudsModel? { bluetooth.connectedModel }
    private var deviceName: String {
        bluetooth.connectedName ?? model?.rawValue ?? "Galaxy Buds"
    }

    var body: some View {
        VStack(spacing: 12) {
            if bluetooth.isConnected {
                connected
            } else if bluetooth.handedOffToPhone {
                handedOff
            } else {
                disconnected
            }
            footer
        }
        .padding(16)
        .frame(width: 344)
        .background(VisualEffectBackground(material: .popover, cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.glassEdge, lineWidth: 0.5)
        )
        .animation(.glass, value: bluetooth.isConnected)
        .focusEffectDisabled() // no focus ring on the auto-focused default button
    }

    // MARK: - Connected

    private var connected: some View {
        VStack(spacing: 12) {
            header
            batteries
            if model?.supportsANC == true {
                listenModule
            }
            tiles
            equalizerModule
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "earbuds")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: deviceName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Circle().fill(Color.batteryGreen).frame(width: 7, height: 7)
                        .background(Circle().fill(Color.batteryGreen.opacity(0.25)).frame(width: 13, height: 13))
                    Text("Connected").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            iconButton("gearshape", help: "Settings…") { openDetail(.overview) }
        }
        .padding(.horizontal, 2)
    }

    /// Left, right and — when the model reports it — the case. The case only
    /// reports while the buds sit in it, so it shows "—" the rest of the time.
    private var batteries: some View {
        let showCase = model?.supportsCaseBattery == true
        return HStack(spacing: 0) {
            CircularBatteryGauge(
                level: status.batteryLeft, label: "Left",
                present: status.batteryLeft > 0, charging: status.isLeftCharging)
                .frame(maxWidth: .infinity)
            CircularBatteryGauge(
                level: status.batteryRight, label: "Right",
                present: status.batteryRight > 0, charging: status.isRightCharging)
                .frame(maxWidth: .infinity)
            if showCase {
                CircularBatteryGauge(
                    level: status.batteryCase, label: "Case",
                    present: status.batteryCase > 0, kind: .budsCase)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 2)
        .glassCard(padding: 12)
    }

    /// Listen mode plus ANC strength. Strength only means anything while ANC is
    /// the active mode, so it's dimmed — not hidden — to keep the panel from
    /// resizing under the pointer.
    private var listenModule: some View {
        let ancActive = status.noiseControlMode == .anc
        return VStack(spacing: 10) {
            GlassSectionHeader(title: "Listen mode",
                               value: LocalizedStringKey(status.noiseControlMode.displayName))
            ListenModePicker(
                modes: model?.listenModes ?? [],
                selection: status.noiseControlMode
            ) { bluetooth.setNoiseControl($0) }

            HStack(spacing: 12) {
                Text("ANC strength")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                AncStrengthStepper(
                    level: status.ancLevel,
                    count: model?.ancLevelCount ?? 2
                ) { bluetooth.setAncLevel($0) }
            }
            .padding(.horizontal, 2)
            .disabled(!ancActive)
            .opacity(ancActive ? 1 : 0.35)
            .animation(.glass, value: ancActive)
        }
        .glassCard()
    }

    /// Control Center–style toggle tiles.
    private var tiles: some View {
        HStack(spacing: 8) {
            if model?.supportsDetectConversations == true {
                let on = status.detectConversations
                tile(icon: "bubble.left.and.text.bubble.right",
                     title: "Conversation",
                     subtitle: on ? "Auto ambient on" : "Off",
                     active: on) {
                    bluetooth.setDetectConversations(!on)
                }
            }
            tile(icon: "bell.badge", title: "Find earbuds", subtitle: "Ring both", active: false) {
                openDetail(.findEarbuds)
            }
        }
    }

    private func tile(
        icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey,
        active: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(active ? Color.white.opacity(0.22) : Color.glassTrack))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).opacity(0.75)
                }
            }
            .foregroundStyle(active ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(active ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.glassCard))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.glassEdge, lineWidth: 0.5)
            )
            .animation(.glass, value: active)
        }
        .buttonStyle(.pressable)
    }

    private var equalizerModule: some View {
        // Models with the full custom EQ expose .custom; older models only the
        // fixed presets.
        let supportsCustom = model?.supportsCustomEqualizer == true
        let presets: [EqualizerPreset] = supportsCustom
            ? EqualizerPreset.allCases
            : EqualizerPreset.allCases.filter { $0 != .custom }
        return VStack(spacing: 10) {
            GlassSectionHeader(title: "Equalizer",
                               value: LocalizedStringKey(status.equalizerPreset.displayName))
            EqualizerPresetGrid(
                presets: presets,
                selection: status.equalizerPreset,
                columns: 3, compact: true
            ) { bluetooth.setEqualizer($0) }
        }
        .glassCard()
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            if bluetooth.isConnected {
                Button { openDetail(.overview) } label: {
                    Text("Galaxy Buds Settings…")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .glassCard(cornerRadius: 12, padding: 0)
                }
                .buttonStyle(.pressable)
            } else {
                Spacer()
            }
            if bluetooth.isConnected && !bluetooth.handedOffToPhone {
                squareButton("iphone", help: "Send audio to phone") { bluetooth.handOffToPhone() }
            }
            squareButton("power", help: "Quit") { NSApplication.shared.terminate(nil) }
        }
    }

    private func squareButton(_ symbol: String, help: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .glassCard(cornerRadius: 12, padding: 0)
        }
        .buttonStyle(.pressable)
        .help(help)
        .accessibilityLabel(Text(help))
    }

    private func iconButton(_ symbol: String, help: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.glassCard))
        }
        .buttonStyle(.pressable)
        .help(help)
        .accessibilityLabel(Text(help))
    }

    // MARK: - Other states

    /// Shown while the buds are intentionally handed off to the phone.
    private var handedOff: some View {
        VStack(spacing: 14) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.variableColor.iterative, options: .repeating)
            VStack(spacing: 3) {
                Text(verbatim: deviceName).font(.system(size: 15, weight: .semibold))
                Text("Audio on phone").font(.caption).foregroundStyle(.secondary)
            }
            Button {
                bluetooth.reclaimFromPhone()
            } label: {
                Label("Connect on Mac", systemImage: "laptopcomputer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassCard(padding: 16)
        .transition(.opacity)
    }

    private var disconnected: some View {
        VStack(spacing: 12) {
            Image(systemName: "earbuds")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("No Buds Connected").font(.headline)
            Text("Connect your Galaxy Buds to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { openDetail(.overview) } label: {
                Text("Connect").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassCard(padding: 16)
        .transition(.opacity)
    }
}

/// Grid of equalizer preset chips. Shared by the panel and the window.
struct EqualizerPresetGrid: View {
    let presets: [EqualizerPreset]
    let selection: EqualizerPreset
    var columns: Int = 3
    var compact: Bool = true
    let onSelect: (EqualizerPreset) -> Void

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: compact ? 6 : 10), count: columns),
            spacing: compact ? 6 : 10
        ) {
            ForEach(presets) { preset in
                chip(preset)
            }
        }
        .animation(.glass, value: selection)
    }

    private func chip(_ preset: EqualizerPreset) -> some View {
        let selected = preset == selection
        return Button { onSelect(preset) } label: {
            Group {
                if compact {
                    Text(LocalizedStringKey(preset.displayName))
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: preset.iconName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(LocalizedStringKey(preset.displayName))
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
            }
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: compact ? 10 : 16, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.glassTrack))
                    .shadow(color: selected ? Color.accentColor.opacity(0.35) : .clear, radius: 6, y: 3)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
