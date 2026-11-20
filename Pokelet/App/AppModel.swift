import AppKit
import Combine
import ServiceManagement
import UniformTypeIdentifiers

final class AppModel: ObservableObject {
    @Published private(set) var prefs: Preferences
    @Published private(set) var mode = InteractionMode()
    @Published private(set) var loginStatus: SMAppService.Status = .notRegistered
    @Published private(set) var shortcutMessage: String?
    @Published private(set) var presentationMessage: String?
    @Published private(set) var audioMessage: String?
    @Published private(set) var generalMessage: String?
    @Published private(set) var pointerMessage: String?

    private let store = PreferenceStore(defaults: .standard)
    private let cursor = CursorController()
    private let tap = PresentationTap()
    private let sound = SoundPlayer()
    private let keys = HotKeys()
    private var suspended = false
    private var previewCleanup: DispatchWorkItem?

    init() { prefs = store.load() }

    func start() {
        keys.onFire = { [weak self] action in
            guard let self else { return }
            switch action {
            case .pointer: self.togglePointer()
            case .presentation, .presentationAlternate: self.togglePresentation()
            }
        }
        cursor.onClick = { [weak self] in
            guard let self, self.prefs.soundEnabled, self.prefs.volume > 0 else { return }
            self.sound.play(volume: self.prefs.volume)
        }
        cursor.onTrackingFailure = { [weak self] in self?.trackingFailed() }
        tap.onClick = { [weak self] secondary in self?.cursor.tap(secondary: secondary) }
        tap.onStop = { [weak self] reason in self?.endPresentation(reason) }
        registerShortcuts()
        refreshLoginStatus()
        mode.setPointer(prefs.restoreEnabled && prefs.lastEnabled)
        applyInputState()
        prepareClickSound()
    }

    func shutDown() {
        tap.stop()
        cursor.stop()
        keys.stop()
        previewCleanup?.cancel()
        sound.stop()
    }

    func togglePointer() {
        pointerMessage = nil
        if mode.presentation { endPresentation(nil) }
        let enabled = !mode.pointer
        mode.setPointer(enabled)
        update(\.lastEnabled, enabled)
        applyInputState()
    }

    func togglePresentation() {
        if mode.presentation { endPresentation(nil); return }
        guard !suspended else { return }
        presentationMessage = nil
        guard keys.contains(.presentation) || keys.register(.presentationDefault, for: .presentation) else {
            presentationMessage = "⌃⌥T is unavailable. Free that shortcut before starting Presentation Mode."
            return
        }

        // Never arm a tap unless we can first show the character.
        cursor.apply(prefs, presentation: true)
        guard cursor.start() else {
            applyInputState()
            presentationMessage = "Presentation Mode needs a working onscreen pointer."
            return
        }

        let result = tap.start()
        _ = mode.startPresentation(tapReady: result == .ready)
        applyInputState()
        switch result {
        case .ready: break
        case .accessibilityRequired:
            presentationMessage = "Allow Pokelet in Privacy & Security → Accessibility, then try again."
            tap.requestAccessibility()
        case .inputMonitoringRequired:
            presentationMessage = "Allow Pokelet in Privacy & Security → Input Monitoring, then try again."
            tap.requestInputMonitoring()
        case .unavailable:
            presentationMessage = "macOS could not verify the input tap and Escape shortcut. Try again outside secure text entry."
        }
    }

    func endPresentation(_ reason: String?) {
        tap.stop()
        mode.stopPresentation()
        presentationMessage = reason
        applyInputState()
    }

    func pause() {
        suspended = true
        if mode.presentation { endPresentation("Presentation Mode ended when the session became inactive.") }
        cursor.stop()
    }

    func resume() {
        suspended = false
        applyInputState()
    }

    func screensChanged() { cursor.rebuildScreens() }
    func spaceChanged() { cursor.spaceChanged() }
    func appBecameActive() { cursor.updateNativeHide(); refreshLoginStatus() }
    func appWillResignActive() { cursor.releaseNativeHide() }

    func update<T>(_ key: WritableKeyPath<Preferences, T>, _ value: T) {
        var next = prefs
        next[keyPath: key] = value
        let soundChanged = next.sound != prefs.sound || next.soundEnabled != prefs.soundEnabled ||
            (next.volume == 0) != (prefs.volume == 0)
        guard next != prefs else { return }
        prefs = next
        store.save(next)
        cursor.apply(next, presentation: mode.presentation)
        if soundChanged { prepareClickSound() }
    }

    func setShortcut(_ shortcut: Shortcut, presentation: Bool) {
        let other = presentation ? prefs.pointerShortcut : prefs.presentationShortcut
        guard shortcut.isAssignable else {
            shortcutMessage = "Use a key with Control, Option or Command."
            return
        }
        guard shortcut != other, presentation || shortcut != .presentationDefault else {
            shortcutMessage = "That shortcut is already assigned in Pokelet."
            return
        }
        let action: HotKeys.Action = presentation ? .presentationAlternate : .pointer
        if presentation && shortcut == .presentationDefault {
            guard keys.contains(.presentation) || keys.register(.presentationDefault, for: .presentation) else {
                shortcutMessage = "That shortcut is in use or reserved by macOS."
                return
            }
            keys.unregister(.presentationAlternate)
        } else if !keys.register(shortcut, for: action) {
            shortcutMessage = "That shortcut is in use or reserved by macOS."
            return
        }
        shortcutMessage = nil
        update(presentation ? \.presentationShortcut : \.pointerShortcut, shortcut)
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        generalMessage = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            generalMessage = error.localizedDescription
        }
        refreshLoginStatus()
    }

    func chooseCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose a click sound"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self, weak panel] response in
            guard response == .OK, let self, let url = panel?.url else { return }
            do {
                try self.sound.importSound(from: url)
                self.update(\.customSoundName, url.lastPathComponent)
                self.update(\.sound, .custom)
                self.prepareClickSound()
            } catch { self.audioMessage = error.localizedDescription }
        }
        if let window = NSApp.keyWindow { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { panel.begin(completionHandler: completion) }
    }

    func previewSound() {
        audioMessage = nil
        guard prefs.sound != .silent, prefs.volume > 0 else { return }
        previewCleanup?.cancel()
        do {
            try sound.prepare(prefs.sound)
            if !sound.play(volume: prefs.volume) { audioMessage = "macOS could not play this sound." }
            if !prefs.soundEnabled {
                let cleanup = DispatchWorkItem { [weak self] in
                    guard let self, !self.prefs.soundEnabled else { return }
                    self.sound.stop()
                }
                previewCleanup = cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.1, execute: cleanup)
            }
        } catch { audioMessage = error.localizedDescription }
    }

    func reset() {
        endPresentation(nil)
        mode.setPointer(false)
        cursor.stop()
        sound.stop()
        previewCleanup?.cancel()
        store.reset()
        prefs = Preferences()
        keys.stop()
        registerShortcuts()
        audioMessage = nil
        presentationMessage = nil
        pointerMessage = nil
        generalMessage = nil
        if loginStatus == .enabled || loginStatus == .requiresApproval { toggleLaunchAtLogin(false) }
        do { try sound.removeCustomSound() } catch { audioMessage = error.localizedDescription }
    }

    private func refreshLoginStatus() { loginStatus = SMAppService.mainApp.status }

    private func registerShortcuts() {
        var failed: [String] = []
        if !keys.register(prefs.pointerShortcut, for: .pointer) { failed.append(prefs.pointerShortcut.title) }
        if !keys.register(.presentationDefault, for: .presentation) { failed.append(Shortcut.presentationDefault.title) }
        if prefs.presentationShortcut != .presentationDefault,
           !keys.register(prefs.presentationShortcut, for: .presentationAlternate) {
            failed.append(prefs.presentationShortcut.title)
        }
        shortcutMessage = failed.isEmpty ? nil : "Unavailable shortcuts: " + failed.joined(separator: ", ")
    }

    private func prepareClickSound() {
        audioMessage = nil
        previewCleanup?.cancel()
        guard prefs.soundEnabled, prefs.volume > 0 else { sound.stop(); return }
        do { try sound.prepare(prefs.sound) }
        catch { audioMessage = error.localizedDescription }
    }

    private func applyInputState() {
        cursor.apply(prefs, presentation: mode.presentation)
        guard !suspended, mode.showsPointer else { cursor.stop(); return }
        if !cursor.start(), mode.showsPointer { trackingFailed() }
    }

    private func trackingFailed() {
        tap.stop()
        mode.setPointer(false)
        update(\.lastEnabled, false)
        pointerMessage = "Pokelet could not start the overlay. The macOS cursor is available."
    }
}
