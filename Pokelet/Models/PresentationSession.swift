import Foundation

struct PresentationSession {
    enum Recovery: Equatable { case tapUnavailable, leaseExpired, drainExpired }
    static let maximumDuration: TimeInterval = 15 * 60
    private static let drainDuration: TimeInterval = 0.75

    private var buttons = PresentationButtons()
    private var activeUntil: TimeInterval?
    private var drainUntil: TimeInterval?

    var isActive: Bool { activeUntil != nil }
    var isDraining: Bool { drainUntil != nil && buttons.hasSuppressedButtons }

    mutating func arm(tapReady: Bool, shortcutReady: Bool, now: TimeInterval) -> Bool {
        guard tapReady, shortcutReady, !isActive, !isDraining else { return false }
        reset()
        activeUntil = now + Self.maximumDuration
        return true
    }

    mutating func end(now: TimeInterval) {
        guard isActive else { return }
        activeUntil = nil
        if buttons.hasSuppressedButtons { drainUntil = now + Self.drainDuration }
    }

    mutating func reset() { self = Self() }

    mutating func suppresses(button: Int, phase: PresentationButtons.Phase) -> Bool {
        guard isActive || isDraining else { return false }
        return buttons.blocks(button: button, phase: phase, allowNew: isActive)
    }

    func recovery(tapHealthy: Bool, now: TimeInterval) -> Recovery? {
        if !tapHealthy { return .tapUnavailable }
        if let activeUntil, now >= activeUntil { return .leaseExpired }
        if let drainUntil, now >= drainUntil { return .drainExpired }
        return nil
    }
}
