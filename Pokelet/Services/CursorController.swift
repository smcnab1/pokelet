// Mouse monitoring, per-screen overlays and display-link tracking are adapted
// from Quiet Pointer's CursorManager. MIT, see QuietPointer-MIT.txt.
import AppKit
import QuartzCore
import os

final class CursorController {
    var onClick: (() -> Void)?
    var onTrackingFailure: (() -> Void)?
    weak var replacementWindow: NSWindow?

    private(set) var isRunning = false
    private var prefs = Preferences()
    private var overlays: [CursorOverlayWindow] = []
    private weak var activeOverlay: CursorOverlayWindow?
    private var monitors: [Any] = []
    private var displayLink: CADisplayLink?
    private var cadence = ClickCadence()
    private var visibility = CursorVisibility()
    private var restoreRetry: DispatchWorkItem?
    private var restoreAttempts = 0
    private var replacementIsSuspended = false
    private var menuTrackingDepth = 0
    private var lastMouse: CGPoint?
    private var lastMotion: CFTimeInterval = 0
    private var revealUntil: CFTimeInterval = 0
    private var motion = CursorMotion()
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
        motion = CursorMotion()
    }

    func apply(_ updated: Preferences, presentation: Bool) {
        let appearanceChanged = prefs.style != updated.style || prefs.palette != updated.palette ||
            prefs.customColour != updated.customColour ||
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
        if motionChanged || arrivalChanged { cancelAnimations() }
        if arrivalChanged { revealUntil = 0 }
        updatePosition(NSEvent.mouseLocation, now: CACurrentMediaTime())
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
    }

    func spaceChanged() {
        guard isRunning else { return }
        releaseNativeHide()
        overlays.forEach { $0.orderFrontRegardless() }
        updatePosition(NSEvent.mouseLocation, now: CACurrentMediaTime())
    }

    func activationChanged(isActive: Bool) {
        replacementIsSuspended = !isActive
        if visibility.needsRestore { releaseNativeHide() }
        refreshPlacement()
    }

    func menuTrackingChanged(started: Bool) {
        menuTrackingDepth = max(0, menuTrackingDepth + (started ? 1 : -1))
        refreshPlacement()
    }

    func refreshPlacement() {
        guard isRunning else { releaseNativeHide(); return }
        updatePosition(NSEvent.mouseLocation, now: CACurrentMediaTime())
    }

    func cancelAnimations() {
        overlays.forEach { $0.pointerLayer.reset() }
    }

    private func updateNativeHide(eligible: Bool) {
        // Quartz ignores the display parameter, but the hide count is balanced.
        // A failed hide is attempted again only after leaving the eligible region.
        if !visibility.needsRestore { restoreAttempts = 0 }
        visibility.update(eligible: eligible, hide: {
            CGDisplayHideCursor(CGMainDisplayID()) == .success
        }, show: {
            CGDisplayShowCursor(CGMainDisplayID()) == .success
        })
        if visibility.needsRestore {
            scheduleRestore()
        } else {
            restoreRetry?.cancel()
            restoreRetry = nil
        }
    }

    private func releaseNativeHide() { updateNativeHide(eligible: false) }

    private func scheduleRestore() {
        guard restoreRetry == nil, restoreAttempts < 3 else { return }
        restoreAttempts += 1
        logger.error("Quartz could not restore the cursor. Retrying the owned show.")
        let retry = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.restoreRetry = nil
            self.releaseNativeHide()
            if !self.visibility.needsRestore { self.refreshPlacement() }
        }
        restoreRetry = retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: retry)
    }

    private func canReplace(at mouse: CGPoint, on overlay: CursorOverlayWindow) -> Bool {
        guard !prefs.keepNative, !clickOnly, !replacementIsSuspended, menuTrackingDepth == 0, NSApp.isActive,
              overlay.isVisible, let window = replacementWindow, window.isVisible, window.isKeyWindow, window.isOnActiveSpace,
              window.attachedSheet == nil else { return false }
        // An active Settings window can still sit behind another window.
        // AppKit's hit test skips our click-through overlay.
        guard window.convertToScreen(window.contentLayoutRect).contains(mouse) else { return false }
        return NSWindow.windowNumber(at: mouse, belowWindowWithWindowNumber: 0) == window.windowNumber
    }

    func tap(secondary: Bool) {
        guard isRunning else { return }
        let now = CACurrentMediaTime()
        lastMotion = now
        if clickOnly { revealUntil = now + ClickResponse.revealDuration }
        updatePosition(NSEvent.mouseLocation, now: now)
        if clickOnly { displayLink?.isPaused = false }

        let count = cadence.record(at: now)
        let reduce = reduceMotion
        if prefs.animate, let activeOverlay {
            let response = ClickResponse(prefs: prefs, count: count, reduced: reduce)
            activeOverlay.pointerLayer.poke(energy: response.energy, secondary: secondary, motion: !reduce,
                                           effects: response.effects, celebration: response.celebration, reduced: reduce)
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
            // Settings controls and previews keep their interactions local.
            self?.handleMouse(event, animateClick: false)
            return event
        }) else {
            NSEvent.removeMonitor(global)
            return false
        }
        monitors = [global, local]
        return true
    }

    private func handleMouse(_ event: NSEvent, animateClick: Bool = true) {
        guard isRunning else { return }
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            if animateClick { tap(secondary: event.type != .leftMouseDown) }
            else { refreshPlacement() }
        default:
            if clickOnly, revealUntil == 0, !visibility.ownsHide { return }
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
            if !visibility.ownsHide { activeOverlay?.pointerLayer.place(.zero, visible: false) }
            displayLink?.isPaused = true
        } else if !clickOnly, now - lastMotion > CursorMotion.stopDelay {
            if prefs.directionBounce, !reduceMotion, let turn = motion.stopped(at: now) {
                activeOverlay?.pointerLayer.wobble(turn: turn)
            }
            displayLink?.isPaused = true
        }
    }

    private func updatePosition(_ mouse: CGPoint, now: CFTimeInterval) {
        guard let overlay = overlays.first(where: { $0.frame.contains(mouse) }) else {
            activeOverlay?.pointerLayer.place(.zero, visible: false)
            if activeOverlay != nil { releaseNativeHide() }
            activeOverlay = nil
            displayLink?.isPaused = true
            lastMouse = nil
            return
        }
        if overlay !== activeOverlay {
            activeOverlay?.pointerLayer.place(.zero, visible: false)
            activeOverlay = overlay
            let wasTracking = displayLink?.isPaused == false
            displayLink?.invalidate()
            let link = overlay.display.displayLink(target: self, selector: #selector(tick(_:)))
            link.isPaused = !wasTracking
            link.add(to: .main, forMode: .common)
            displayLink = link
            motion.resetDirection()
        }
        let visible = !clickOnly || now < revealUntil
        // Place the character before hiding the native cursor on a new display.
        let eligible = visible && canReplace(at: mouse, on: overlay)
        if eligible, !visibility.ownsHide {
            overlay.pointerLayer.place(local(mouse, in: overlay.frame), visible: true)
        }
        if !visibility.needsRestore { updateNativeHide(eligible: eligible) }
        let location = visibility.ownsHide ? mouse :
            CursorGeometry.companion(at: mouse, in: overlay.frame, size: prefs.size)
        overlay.pointerLayer.place(local(location, in: overlay.frame), visible: visible || visibility.ownsHide)
        if let lastMouse, visible, prefs.directionBounce, !reduceMotion,
           let turn = motion.turn(from: lastMouse, to: mouse, now: now) {
            overlay.pointerLayer.wobble(turn: turn)
        }
        lastMouse = mouse
    }

    private func local(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: point.y - frame.minY)
    }

    private func configureArtwork() -> Bool {
        var images: [CGFloat: CGImage] = [:]
        for overlay in overlays {
            let scale = overlay.display.backingScaleFactor
            if images[scale] == nil {
                images[scale] = PointerArt.image(prefs: prefs, scale: scale)
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
