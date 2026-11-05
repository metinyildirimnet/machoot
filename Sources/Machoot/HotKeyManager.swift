import AppKit
import Carbon.HIToolbox

/// Registers system-wide hotkeys via Carbon's RegisterEventHotKey.
/// This API does not require Accessibility permission.
final class HotKeyManager {
    static let shared = HotKeyManager()

    private struct Binding {
        var shortcut: Shortcut?
        var handler: () -> Void
    }

    private static let signature: OSType = 0x4D43_4854 // 'MCHT'

    private var bindings: [UInt32: Binding] = [:]
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var isSuspended = false

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
            )
            guard status == noErr, hotKeyID.signature == HotKeyManager.signature else { return status }
            DispatchQueue.main.async { HotKeyManager.shared.bindings[hotKeyID.id]?.handler() }
            return noErr
        }, 1, &spec, nil, nil)
    }

    /// Sets (or clears, if `shortcut` is nil) the hotkey for `id`.
    /// Returns false if the system refused the combination (e.g. already taken).
    @discardableResult
    func set(id: UInt32, shortcut: Shortcut?, handler: @escaping () -> Void) -> Bool {
        unregister(id)
        bindings[id] = Binding(shortcut: shortcut, handler: handler)
        return isSuspended ? true : register(id)
    }

    /// Temporarily disables all hotkeys (used while recording a new shortcut).
    func suspend() {
        isSuspended = true
        for id in Array(refs.keys) { unregister(id) }
    }

    func resume() {
        isSuspended = false
        for id in bindings.keys { register(id) }
    }

    @discardableResult
    private func register(_ id: UInt32) -> Bool {
        guard let shortcut = bindings[id]?.shortcut else { return true }
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: HotKeyManager.signature, id: id)
        let status = RegisterEventHotKey(
            shortcut.keyCode, shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref
        )
        guard status == noErr, let ref else {
            NSLog("Machoot: failed to register hotkey \(shortcut.displayString) (status \(status))")
            return false
        }
        refs[id] = ref
        return true
    }

    private func unregister(_ id: UInt32) {
        if let ref = refs.removeValue(forKey: id) { UnregisterEventHotKey(ref) }
    }
}
