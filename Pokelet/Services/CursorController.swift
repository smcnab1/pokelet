// Mouse monitoring, per-screen overlays and display-link tracking are adapted
// from Quiet Pointer's CursorManager. MIT, see LICENSE.
import AppKit
import QuartzCore
import os

final class CursorController {
    var onClick: (() -> Void)?
    var onTrackingFailure: (() -> Void)?

    private(set) var isRunning = false
    private var prefs = Preferences()
    private var overlays: [CursorOverlayWindow] = []
    private weak var activeOverlay: CursorOverlayWindow?
    private var monitors: [Any] = []
    private var displayLink: CADisplayLink?
    private var cadence = ClickCadence()
    private var ownsNativeHide = false
    private var lastMouse: CGPoint?
    private var lastMotion: CFTimeInterval = 0
    private var revealUntil: CFTimeInterval = 0
    private var lastDirection = CGVector.zero
    private var lastTurn: CFTimeInterval = 0
    private var lastFastMotion: CFTimeInterval = 0
    private var presentation = false
    private let logger = Logger(subsystem: "uk.co.sammcnab.Pokelet", category: "Cursor")

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        guard !NSScreen.screens.isEmpty, installMonitors() else {
            logger.error("Mouse monitoring could not start.")
            return false
        }
        isRunning = true
        rebuildScreens()
        return isRunning
    }

    func stop() {
        releaseNativeHide()
        isRunning = false
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
        closeOverlays()
        cadence = ClickCadence()
        revealUntil = 0
        lastDirection = .zero
        lastTurn = 0
        lastFastMotion = 0
    }

    func apply(_ updated: Preferences, presentation: Bool) {
        let appearanceChanged = prefs.style != updated.style || prefs.palette != updated.palette ||
            prefs.size != updated.size || prefs.shadow != updated.shadow || prefs.outline != updated.outline
        let arrivalChanged = prefs.clickOnly != updated.clickOnly || self.presentation != presentation
        let motionChanged = prefs.reducedMotion != updated.reducedMotion ||
            prefs.animate != updated.animate || prefs.effects != updated.effects ||
            prefs.celebration != updated.celebration || prefs.directionBounce != updated.directionBounce
        let hideChanged = prefs.keepNative != updated.keepNative
        prefs = updated
        self.presentation = presentation
        guard isRunning, appearanceChanged || motionChanged || arrivalChanged || hideChanged else { return }
        if appearanceChanged, !configureArtwork() { return }
        if motionChanged || arrivalChanged { overlays.forEach { $0.pointerLayer.reset() } }
        if arrivalChanged { revealUntil = 0 }
        updatePosition(NSEvent.mouseLocation, now: CACurrentMediaTime())
        updateNativeHide()
        displayLink?.isPaused = false
    }

    func rebuildScreens() {
        guard isRunning else { return }
        releaseNativeHide()
        closeOverlays()
        overlays = NSScreen.screens.map(CursorOverlayWindow.init)
        guard !overlays.isEmpty, configureArtwork() else {
            if isRunning { trackingFailed() }
            return
        }
        overlays.forEach { $0.orderFrontRegardless() }
        lastMotion = CACurrentMediaTime()
        updatePosition(NSEvent.mouseLocation, now: lastMotion)
        updateNativeHide()
    }

    func spaceChanged() {
        guard isRunning else { return }
        overlays.forEach { $0.orderFrontRegardless() }
        updatePosition(NSEvent.mouseLocation, now: CACurrentMediaTime())
        updateNativeHide()
        displayLink?.isPaused = false
    }

    func updateNativeHide() {
        // The public API only guarantees cursor changes in the foreground.
        guard isRunning, !clickOnly, !prefs.keepNative, NSApp.isActive,
              let activeOverlay, activeOverlay.isVisible else {
            releaseNativeHide()
            return
        }
        guard !ownsNativeHide else { return }
        ownsNativeHide = CGDisplayHideCursor(CGMainDisplayID()) == .success
    }

    func releaseNativeHide() {
        guard ownsNativeHide else { return }
        if CGDisplayShowCursor(CGMainDisplayID()) == .success {
            ownsNativeHide = false
        } else {
            logger.error("Cursor release failed; will retry on the next lifecycle change.")
        }
    }

    func tap(secondary: Bool) {
        guard isRunning else { return }
        let now = CACurrentMediaTime()
        lastMotion = now
        if clickOnly { revealUntil = now + 0.43 }
        updatePosition(NSEvent.mouseLocation, now: now)
        displayLink?.isPaused = false

        let count = cadence.record(at: now)
        let reduce = reduceMotion
        let energy = prefs.intensity.energy(clicks: count, reactive: prefs.reactive)
        let celebration = prefs.celebration && count >= 5 && count.isMultiple(of: 2) && !reduce
        let effects = prefs.effects && (prefs.intensity != .barelyThere || reduce)
        if prefs.animate, let activeOverlay {
            activeOverlay.pointerLayer.poke(energy: energy, secondary: secondary, motion: !reduce,
                                           effects: effects, celebration: celebration, reduced: reduce)
        }
        onClick?()
    }

    private var clickOnly: Bool { prefs.clickOnly && !presentation }
    private var reduceMotion: Bool { prefs.reducedMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private func installMonitors() -> Bool {
        let movement: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        // Inactive apps receive the global copy, our own windows receive the local copy.
        let mask = movement.union(clicks)
        guard let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handleMouse(event)
        }) else { return false }
        guard let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handleMouse(event)
            return event
        }) else {
            NSEvent.removeMonitor(global)
            return false
        }
        monitors = [global, local]
        return true
    }

    private func handleMouse(_ event: NSEvent) {
        guard isRunning else { return }
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            tap(secondary: event.type != .leftMouseDown)
        default:
            if clickOnly, revealUntil == 0 { return }
            if let displayLink, !displayLink.isPaused { return }
            lastMotion = CACurrentMediaTime()
            updatePosition(NSEvent.mouseLocation, now: lastMotion)
            displayLink?.isPaused = false
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard isRunning else { return }
        let now = CACurrentMediaTime()
        let mouse = NSEvent.mouseLocation
        if mouse != lastMouse {
            lastMotion = now
            updatePosition(mouse, now: now)
        }
        if clickOnly, now >= revealUntil {
            revealUntil = 0
            activeOverlay?.pointerLayer.place(.zero, visible: false)
            displayLink?.isPaused = true
        } else if !clickOnly, now - lastMotion > 0.085 {
            if prefs.directionBounce, now - lastFastMotion < 0.15, now - lastTurn > 0.22, !reduceMotion {
                activeOverlay?.pointerLayer.wobble(turn: lastDirection.dx < 0 ? -0.32 : 0.32)
                lastTurn = now
            }
            displayLink?.isPaused = true
        }
    }

    private func updatePosition(_ mouse: CGPoint, now: CFTimeInterval) {
        guard let overlay = overlays.first(where: { $0.frame.contains(mouse) }) else {
            activeOverlay?.pointerLayer.place(.zero, visible: false)
            releaseNativeHide()
            lastMouse = nil
            return
        }
        if overlay !== activeOverlay {
            activeOverlay?.pointerLayer.place(.zero, visible: false)
            activeOverlay = overlay
            displayLink?.invalidate()
            let link = overlay.display.displayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
            lastDirection = .zero
        }
        let visible = !clickOnly || now < revealUntil
        let point = CGPoint(x: mouse.x - overlay.frame.minX, y: mouse.y - overlay.frame.minY)
        overlay.pointerLayer.place(point, visible: visible)
        if let lastMouse, visible, prefs.directionBounce, !reduceMotion {
            noteTurn(from: lastMouse, to: mouse, now: now, layer: overlay.pointerLayer)
        }
        lastMouse = mouse
    }

    private func noteTurn(from previous: CGPoint, to point: CGPoint, now: CFTimeInterval, layer: PointerLayer) {
        let dx = point.x - previous.x, dy = point.y - previous.y
        let speed = hypot(dx, dy)
        guard speed >= 15 else { return }
        lastFastMotion = now
        let direction = CGVector(dx: dx / speed, dy: dy / speed)
        let dot = direction.dx * lastDirection.dx + direction.dy * lastDirection.dy
        if dot < -0.55, now - lastTurn > 0.38 {
            layer.wobble(turn: direction.dx < 0 ? -1 : 1)
            lastTurn = now
        }
        lastDirection = direction
    }

    private func configureArtwork() -> Bool {
        var images: [CGFloat: CGImage] = [:]
        for overlay in overlays {
            let scale = overlay.display.backingScaleFactor
            if images[scale] == nil {
                images[scale] = PointerArt.image(style: prefs.style, palette: prefs.palette, size: prefs.size,
                                                scale: scale, outline: prefs.outline, shadow: prefs.shadow)
            }
            guard let image = images[scale] else {
                trackingFailed()
                return false
            }
            overlay.pointerLayer.configure(image: image, prefs: prefs)
        }
        return true
    }

    private func closeOverlays() {
        displayLink?.invalidate()
        displayLink = nil
        activeOverlay = nil
        lastMouse = nil
        overlays.forEach { $0.close() }
        overlays.removeAll()
    }

    private func trackingFailed() {
        logger.error("Pointer overlay could not be configured.")
        stop()
        onTrackingFailure?()
    }
}
