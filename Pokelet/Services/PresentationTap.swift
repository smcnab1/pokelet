import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics

final class PresentationTap {
    enum StartResult { case ready, accessibilityRequired, inputMonitoringRequired, unavailable }

    private static let mouseTypes: [CGEventType] = [
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged
    ]
    private static let mask = (mouseTypes + [.keyDown]).reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }

    var onClick: ((Bool) -> Void)?
    var onStop: ((String?) -> Void)?
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var healthCheck: Timer?
    private var blocking = false
    private var generation = 0
    private var buttons = PresentationButtons()

    var isActive: Bool { blocking }

    func start() -> StartResult {
        stop()
        guard AXIsProcessTrusted() else { return .accessibilityRequired }
        guard !IsSecureEventInputEnabled() else { return .unavailable }

        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<PresentationTap>.fromOpaque(context).takeUnretainedValue()
                .handle(type: type, event: event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: Self.mask,
                                          callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()),
              let inputSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            return CGPreflightListenEventAccess() ? .unavailable : .inputMonitoringRequired
        }

        port = tap
        source = inputSource
        CFRunLoopAddSource(CFRunLoopGetMain(), inputSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        // macOS can quietly remove unauthorised bits at creation. Verify that
        // mouse suppression and the Escape event are both present.
        guard CFMachPortIsValid(tap), CGEvent.tapIsEnabled(tap: tap), hasCompleteMask() else {
            stop()
            return CGPreflightListenEventAccess() ? .unavailable : .inputMonitoringRequired
        }

        buttons = PresentationButtons()
        blocking = true
        let timer = Timer(timeInterval: 0.40, repeats: true) { [weak self] _ in self?.checkHealth() }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        healthCheck = timer
        return .ready
    }

    func stop() {
        blocking = false
        generation += 1
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

    private func hasCompleteMask() -> Bool {
        var count: UInt32 = 0
        guard CGGetEventTapList(0, nil, &count) == .success, count > 0 else { return false }
        let capacity = count + 8
        var info = Array(repeating: CGEventTapInformation(), count: Int(capacity))
        guard CGGetEventTapList(capacity, &info, &count) == .success, count <= capacity else { return false }
        return info.prefix(Int(count)).contains {
            $0.tappingProcess == getpid() && $0.enabled &&
                $0.tapPoint == .cgSessionEventTap && $0.eventsOfInterest & Self.mask == Self.mask
        }
    }

    private func checkHealth() {
        guard blocking, let port else { return }
        if !CFMachPortIsValid(port) || !CGEvent.tapIsEnabled(tap: port) ||
            !AXIsProcessTrusted() || IsSecureEventInputEnabled() {
            finish("Presentation Mode ended because macOS changed input access.")
        }
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let original = Unmanaged.passUnretained(event)
        guard blocking else { return original }
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            finish("Presentation Mode ended because macOS stopped the event tap.")
            return original
        case .keyDown:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            if code == kVK_Escape { finish(nil) }
            return original
        default:
            break
        }

        let phase: PresentationButtons.Phase
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown: phase = .down
        case .leftMouseUp, .rightMouseUp, .otherMouseUp: phase = .up
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged: phase = .drag
        default: return original
        }

        let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        guard buttons.blocks(button: button, phase: phase) else { return original }
        if phase == .down {
            let current = generation
            DispatchQueue.main.async { [weak self] in
                guard let self, self.blocking, self.generation == current else { return }
                self.onClick?(type != .leftMouseDown)
            }
        }
        return nil
    }

    private func finish(_ reason: String?) {
        blocking = false
        let current = generation
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == current else { return }
            self.stop()
            self.onStop?(reason)
        }
    }
}
