import CoreAudio
import Foundation
import IOBluetooth

/// Detects whether macOS itself has a pair of buds connected, without touching
/// the radio. `IOBluetoothDevice.isConnected()` often reports false for Galaxy
/// Buds even while they're playing, but the moment macOS connects them it
/// publishes them as a Bluetooth audio device — a reliable, passive signal.
enum BluetoothAudio {
    /// True when the Mac has a live link to `device`: IOBluetooth says so, or a
    /// Bluetooth audio device for it (matched by address or name) exists.
    static func macHasLink(to device: IOBluetoothDevice) -> Bool {
        device.isConnected() || isAudioDevicePresent(name: device.name, address: device.addressString)
    }

    static func isAudioDevicePresent(name: String?, address: String?) -> Bool {
        let wantAddress = normalize(address)
        for id in deviceIDs() where isBluetooth(id) {
            if let wantAddress, !wantAddress.isEmpty,
               let uid = stringProperty(id, kAudioDevicePropertyDeviceUID),
               normalize(uid)?.contains(wantAddress) == true {
                return true
            }
            if let name, !name.isEmpty,
               let deviceName = stringProperty(id, kAudioObjectPropertyName),
               deviceName == name {
                return true
            }
        }
        return false
    }

    /// Calls `handler` on the main queue whenever the system's audio device
    /// list changes — e.g. right after macOS connects or drops the buds.
    static func observeDeviceChanges(_ handler: @escaping () -> Void) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        _ = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main
        ) { _, _ in handler() }
    }

    // MARK: - CoreAudio helpers

    /// Hex digits only, upper-cased, so "ac-80-0a-…" matches "AC:80:0A…:output".
    private static func normalize(_ string: String?) -> String? {
        string.map { String($0.uppercased().filter { $0.isLetter || $0.isNumber }) }
    }

    private static func deviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr, size > 0 else {
            return []
        }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else {
            return []
        }
        return ids
    }

    private static func isBluetooth(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport) == noErr else {
            return false
        }
        return transport == kAudioDeviceTransportTypeBluetooth
            || transport == kAudioDeviceTransportTypeBluetoothLE
    }

    private static func stringProperty(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
              let string = value?.takeRetainedValue() else {
            return nil
        }
        return string as String
    }
}
