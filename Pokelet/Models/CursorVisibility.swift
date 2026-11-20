/// One successful hide owns exactly one successful show.
struct CursorVisibility {
    private enum State { case visible, hideFailed, hidden, restorePending }
    private var state: State = .visible

    var ownsHide: Bool { state == .hidden || state == .restorePending }
    var needsRestore: Bool { state == .restorePending }

    mutating func update(eligible: Bool, hide: () -> Bool, show: () -> Bool) {
        switch (state, eligible) {
        case (.visible, true):
            state = hide() ? .hidden : .hideFailed
        case (.hideFailed, false):
            state = .visible
        case (.hidden, false), (.restorePending, _):
            state = show() ? (eligible ? .hideFailed : .visible) : .restorePending
        default:
            break
        }
    }
}
