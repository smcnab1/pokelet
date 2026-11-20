// Adapted from Quiet Pointer's HotKeyManager. MIT, see QuietPointer-MIT.txt.
import Carbon.HIToolbox
import Foundation

final class HotKeys {
    enum Action: UInt32, CaseIterable { case pointer = 1, presentation, presentationAlternate }
    private static let signature: OSType = 0x504B4C54 // PKLT
    private var registered: [Action: (Shortcut, EventHotKeyRef)] = [:]
    private var handler: EventHandlerRef?
    private var pressed: Set<Action> = []
    var onFire: ((Action) -> Void)?

    func contains(_ action: Action) -> Bool { registered[action] != nil }

    @discardableResult
    func register(_ shortcut: Shortcut, for action: Action) -> Bool {
        if registered[action]?.0 == shortcut { return true }
        guard installHandler() else { return false }
        var reference: EventHotKeyRef?
        let id = EventHotKeyID(signature: Self.signature, id: action.rawValue)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, id,
                                         GetApplicationEventTarget(), UInt32(kEventHotKeyExclusive), &reference)
        guard status == noErr, let reference else { return false }
        unregister(action)
        registered[action] = (shortcut, reference)
        return true
    }

    func unregister(_ action: Action) {
        pressed.remove(action)
        if let (_, ref) = registered.removeValue(forKey: action) { UnregisterEventHotKey(ref) }
    }

    func clearPressedKeys() { pressed.removeAll() }

    func stop() {
        Action.allCases.forEach(unregister)
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }

    private func installHandler() -> Bool {
        if handler != nil { return true }
        let spec = [kEventHotKeyPressed, kEventHotKeyReleased].map {
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32($0))
        }
        let callback: EventHandlerUPP = { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr, id.signature == HotKeys.signature,
                  let action = Action(rawValue: id.id) else { return OSStatus(eventNotHandledErr) }
            let keys = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            if GetEventKind(event) == UInt32(kEventHotKeyReleased) {
                keys.pressed.remove(action)
            } else if keys.pressed.insert(action).inserted {
                // Keep menu tracking and lifecycle changes out of the Carbon callback.
                DispatchQueue.main.async { [weak keys] in
                    guard let keys, keys.contains(action) else { return }
                    keys.onFire?(action)
                }
            }
            return noErr
        }
        return InstallEventHandler(GetApplicationEventTarget(), callback, spec.count, spec,
                                   Unmanaged.passUnretained(self).toOpaque(), &handler) == noErr
    }
}
