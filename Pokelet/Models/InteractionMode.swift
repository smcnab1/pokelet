import Foundation

struct InteractionMode {
    private(set) var pointer = false
    private(set) var presentation = false
    var showsPointer: Bool { pointer || presentation }

    mutating func setPointer(_ enabled: Bool) {
        pointer = enabled
        if !enabled { stopPresentation() }
    }

    @discardableResult
    mutating func startPresentation(tapReady: Bool) -> Bool {
        guard tapReady else { return false }
        presentation = true
        return true
    }

    mutating func stopPresentation() { presentation = false }
}

struct PresentationButtons {
    enum Phase { case down, drag, up }
    // Only gestures whose down event we blocked should lose their drag and up.
    private var suppressed: UInt64 = 0
    var hasSuppressedButtons: Bool { suppressed != 0 }

    mutating func blocks(button: Int, phase: Phase, allowNew: Bool = true) -> Bool {
        guard (0..<64).contains(button) else { return false }
        let bit = UInt64(1) << button
        switch phase {
        case .down:
            // A fresh down supersedes any missing up for this button.
            guard allowNew else { suppressed &= ~bit; return false }
            suppressed |= bit
            return true
        case .drag:
            return suppressed & bit != 0
        case .up:
            let blocked = suppressed & bit != 0
            suppressed &= ~bit
            return blocked
        }
    }
}
