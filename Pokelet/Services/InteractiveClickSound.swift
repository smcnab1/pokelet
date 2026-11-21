import ApplicationServices
import Foundation

/// Coalesce busy hit tests to the latest click. AX queries can wait on another
/// app, so all queries run off the event monitor and main thread.
@MainActor
final class InteractiveClickSound {
    private static let maximumAge = 0.24
    private let worker = DispatchQueue(label: "uk.co.sammcnab.Pokelet.InteractiveClickSound", qos: .userInitiated)
    private var busy = false
    private var next: Request?
    private var generation = 0

    private struct Request {
        let point: CGPoint
        let time: TimeInterval
        let generation: Int
        let result: (Bool) -> Void
    }

    static var accessibilityGranted: Bool { AXIsProcessTrusted() }

    func classify(at point: CGPoint, result: @escaping (Bool) -> Void) {
        let request = Request(point: point, time: ProcessInfo.processInfo.systemUptime,
                              generation: generation, result: result)
        if busy { next = request }
        else { start(request) }
    }

    func cancel() {
        generation += 1
        next = nil
    }

    private func start(_ request: Request) {
        busy = true
        let deadline = request.time + Self.maximumAge
        worker.async { [weak self] in
            let actionable = Self.hitTest(at: request.point, before: deadline)
            DispatchQueue.main.async {
                self?.complete(request, actionable: actionable, before: deadline)
            }
        }
    }

    private func complete(_ request: Request, actionable: Bool, before deadline: TimeInterval) {
        busy = false
        if request.generation == generation, ProcessInfo.processInfo.systemUptime < deadline {
            request.result(actionable)
        }
        if let next {
            self.next = nil
            start(next)
        }
    }

    nonisolated private static func hitTest(at point: CGPoint, before deadline: TimeInterval) -> Bool {
        guard ProcessInfo.processInfo.systemUptime < deadline else { return false }
        let desktop = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(desktop, 0.08)
        defer { AXUIElementSetMessagingTimeout(desktop, 0) }
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(desktop, Float(point.x), Float(point.y), &hit) == .success
        else { return false }

        for _ in 0..<4 {
            guard let element = hit, ProcessInfo.processInfo.systemUptime < deadline else { break }
            let role = attribute(kAXRoleAttribute, of: element) as? String
            if role == "AXWindow" || role == "AXApplication" { break }
            let enabled = attribute(kAXEnabledAttribute, of: element) as? Bool
            if enabled == false { return false }
            if isActionable(role: role, enabled: enabled, actions: []) { return true }
            var actions: CFArray?
            if AXUIElementCopyActionNames(element, &actions) == .success,
               isActionable(role: role, enabled: enabled, actions: (actions as? [String]) ?? []) { return true }
            guard let parent = attribute(kAXParentAttribute, of: element),
                  CFGetTypeID(parent) == AXUIElementGetTypeID() else { break }
            hit = (parent as! AXUIElement)
        }
        return false
    }

    nonisolated private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    nonisolated static func isActionable(role: String?, enabled: Bool?, actions: [String]) -> Bool {
        guard enabled != false, role != "AXWindow", role != "AXApplication" else { return false }
        let controls: Set<String> = [
            "AXButton", "AXCheckBox", "AXRadioButton", "AXLink", "AXPopUpButton", "AXMenuButton",
            "AXMenuItem", "AXDisclosureTriangle", "AXTab", "AXSlider", "AXIncrementor", "AXTextField",
            "AXTextArea", "AXComboBox", "AXSwitch", "AXColorWell", "AXSegmentedControl"
        ]
        return role.map(controls.contains) == true || actions.contains(kAXPressAction) || actions.contains(kAXPickAction)
    }
}
