// Adapted from Quiet Pointer's CursorOverlayWindow. MIT, see LICENSE.
import AppKit

final class CursorOverlayWindow: NSWindow {
    let display: NSScreen
    let pointerLayer = PointerLayer()

    init(display: NSScreen) {
        self.display = display
        super.init(contentRect: display.frame, styleMask: .borderless, backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        isMovable = false
        sharingType = .readOnly
        animationBehavior = .none
        let view = NSView(frame: CGRect(origin: .zero, size: display.frame.size))
        view.wantsLayer = true
        view.layer?.addSublayer(pointerLayer.root)
        contentView = view
        // Explicitly use global AppKit coordinates for secondary-screen origins.
        setFrame(display.frame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
