// Adapted from Quiet Pointer's HotKeyManager. MIT, see LICENSE.
import Carbon.HIToolbox
import Foundation

final class HotKeys {
    enum Action: UInt32, CaseIterable { case pointer = 1, presentation, presentationAlternate }
    private static let signature: OSType = 0x504B4C54 // PKLT
    private var registered: [Action: (Shortcut, EventHotKeyRef)] = [:]
    private var handler: EventHandlerRef?
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
        if let (_, ref) = registered.removeValue(forKey: action) { UnregisterEventHotKey(ref) }
    }

    func stop() {
        Action.allCases.forEach(unregister)
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }

    private func installHandler() -> Bool {
        if handler != nil { return true }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr, id.signature == HotKeys.signature,
                  let action = Action(rawValue: id.id) else { return OSStatus(eventNotHandledErr) }
            let keys = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            // Keep menu tracking and lifecycle changes out of the Carbon callback.
            DispatchQueue.main.async { [weak keys] in keys?.onFire?(action) }
            return noErr
        }
        return InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec,
                                   Unmanaged.passUnretained(self).toOpaque(), &handler) == noErr
    }
}
