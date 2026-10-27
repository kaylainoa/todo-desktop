import Carbon

/// A system-wide keyboard shortcut that works no matter which app you're in.
/// Uses Carbon's RegisterEventHotKey, which (unlike key monitors) needs no
/// Accessibility permission.
final class HotKey {
    private var ref: EventHotKeyRef?
    private let action: () -> Void

    init(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().action()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let id = EventHotKeyID(signature: OSType(0x4654_4F44), id: 1) // "FTOD"
        RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id,
                            GetApplicationEventTarget(), 0, &ref)
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
    }
}
