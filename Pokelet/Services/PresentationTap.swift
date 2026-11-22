import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics
import Foundation

final class PresentationTap {
    enum StartResult { case ready, accessibilityRequired, inputMonitoringRequired, mouseButtonsHeld, unavailable }

    private static let mouseTypes: [CGEventType] = [
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged
    ]
    private static let mask = (mouseTypes + [.keyDown]).reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }

    var onClick: ((CGPoint, Bool) -> Void)?
    var onStop: ((String?) -> Void)?
    var isMenuBarExit: ((CGPoint) -> Bool)?
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var healthCheck: Timer?
    private var generation = 0
    private var finishPending = false
    private var monitorsKeyboardPermission = false
    private var session = PresentationSession()

    static var accessibilityGranted: Bool { AXIsProcessTrusted() }
    static var inputMonitoringGranted: Bool { CGPreflightListenEventAccess() }
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    func start(shortcutReady: Bool) -> StartResult {
        guard shortcutReady, !session.isDraining, !session.isActive else { return .unavailable }
        invalidate()
        guard Self.accessibilityGranted else { return .accessibilityRequired }
        guard !IsSecureEventInputEnabled() else { return .unavailable }
        guard !(0..<32).contains(where: isButtonDown) else { return .mouseButtonsHeld }
        monitorsKeyboardPermission = Self.inputMonitoringGranted

        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<PresentationTap>.fromOpaque(context).takeUnretainedValue()
                .handle(type: type, event: event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: Self.mask,
                                          callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()),
              let inputSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            return Self.inputMonitoringGranted ? .unavailable : .inputMonitoringRequired
        }

        port = tap
        source = inputSource
        CFRunLoopAddSource(CFRunLoopGetMain(), inputSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        // macOS may silently remove unauthorised events from the requested mask.
        let tapReady = isHealthy && hasCompleteMask()
        guard session.arm(tapReady: tapReady, shortcutReady: shortcutReady, now: now) else {
            invalidate()
            return Self.inputMonitoringGranted ? .unavailable : .inputMonitoringRequired
        }

        let timer = Timer(timeInterval: 0.20, repeats: true) { [weak self] _ in self?.checkHealth() }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        healthCheck = timer
        return .ready
    }

    /// End suppression of new clicks immediately. Keep only matched releases briefly.
    func stop() {
        finishPending = false
        generation += 1
        session.end(now: now)
        if !session.isDraining { invalidate() }
    }

    /// Used when the tap is unhealthy, the session suspends, or the app quits.
    func invalidate() {
        finishPending = false
        monitorsKeyboardPermission = false
        generation += 1
        session.reset()
        healthCheck?.invalidate()
        healthCheck = nil
        if let port { CGEvent.tapEnable(tap: port, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
    }

    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func requestInputMonitoring() { _ = CGRequestListenEventAccess() }

    private var isHealthy: Bool {
        guard let port else { return false }
        return CFMachPortIsValid(port) && CGEvent.tapIsEnabled(tap: port) &&
            Self.accessibilityGranted && !IsSecureEventInputEnabled() &&
            (!monitorsKeyboardPermission || Self.inputMonitoringGranted)
    }

    private func isButtonDown(_ index: UInt32) -> Bool {
        guard let button = CGMouseButton(rawValue: index) else { return false }
        return CGEventSource.buttonState(.combinedSessionState, button: button)
    }

    private func hasCompleteMask() -> Bool {
        var count: UInt32 = 0
        guard CGGetEventTapList(0, nil, &count) == .success, count > 0 else { return false }
        let capacity = count + 8
        var info = Array(repeating: CGEventTapInformation(), count: Int(capacity))
        guard CGGetEventTapList(capacity, &info, &count) == .success, count <= capacity else { return false }
        return info.prefix(Int(count)).contains {
            $0.tappingProcess == getpid() && $0.enabled && $0.options == .defaultTap &&
                $0.tapPoint == .cgSessionEventTap && $0.eventsOfInterest & Self.mask == Self.mask
        }
    }

    private func checkHealth() {
        guard !finishPending else { return }
        switch session.recovery(tapHealthy: isHealthy, now: now) {
        case .tapUnavailable:
            let wasActive = session.isActive
            invalidate()
            if wasActive { onStop?("Presentation Mode ended because macOS changed input access.") }
        case .leaseExpired:
            stop()
            onStop?("Presentation Mode ended after 15 minutes.")
        case .drainExpired:
            invalidate()
        case nil:
            if !session.isActive, !session.isDraining { invalidate() }
        }
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let original = Unmanaged.passUnretained(event)
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            finishFromTap("Presentation Mode ended because macOS stopped the event tap.", tapLost: true)
            return original
        case .keyDown:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            if session.isActive, code == kVK_Escape { finishFromTap(nil) }
            return original
        default:
            break
        }

        // Enforce the time bound even if main run loop timer delivery is delayed.
        switch session.recovery(tapHealthy: true, now: now) {
        case .leaseExpired: finishFromTap("Presentation Mode ended after 15 minutes.")
        case .drainExpired: session.reset()
        default: break
        }
        let phase: PresentationButtons.Phase
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown: phase = .down
        case .leftMouseUp, .rightMouseUp, .otherMouseUp: phase = .up
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged: phase = .drag
        default: return original
        }

        let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        guard session.suppresses(button: button, phase: phase) else { return original }
        if type == .leftMouseDown, isMenuBarExit?(event.unflippedLocation) == true {
            // The indicator itself is a stop control. Consume this gesture too.
            finishFromTap(nil)
        } else if phase == .down {
            let point = event.unflippedLocation
            let current = generation
            DispatchQueue.main.async { [weak self] in
                guard let self, self.session.isActive, self.generation == current else { return }
                self.onClick?(point, type != .leftMouseDown)
            }
        }
        return nil
    }

    private func finishFromTap(_ reason: String?, tapLost: Bool = false) {
        let wasActive = session.isActive
        if tapLost { session.reset() }
        else { session.end(now: now) }
        guard !finishPending else { return }
        finishPending = true
        generation += 1
        let current = generation
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == current else { return }
            self.finishPending = false
            if !self.session.isDraining { self.invalidate() }
            if wasActive { self.onStop?(reason) }
        }
    }
}
