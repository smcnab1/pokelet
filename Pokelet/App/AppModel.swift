import AppKit
import Combine
import ServiceManagement
import UniformTypeIdentifiers

final class AppModel: ObservableObject {
    @Published var settingsPage = SettingsPage.pointer
    @Published private(set) var prefs: Preferences
    @Published private(set) var mode = InteractionMode()
    @Published private(set) var loginStatus: SMAppService.Status = .notRegistered
    @Published private(set) var shortcutMessage: String?
    @Published private(set) var presentationMessage: String?
    @Published private(set) var audioMessage: String?
    @Published private(set) var generalMessage: String?
    @Published private(set) var pointerMessage: String?
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false
    @Published private(set) var needsInputMonitoring = false

    let isAcceptanceProfile: Bool
    let isStudioAcceptance: Bool
    let presentationAvailable: Bool
    var isMenuBarExit: ((CGPoint) -> Bool)? {
        didSet { tap.isMenuBarExit = isMenuBarExit }
    }

    private let store: PreferenceStore
    private let cursor = CursorController()
    private let tap = PresentationTap()
    private let sound: SoundPlayer
    private let keys = HotKeys()
    private var suspended = false
    private var audioNeedsRecovery = false

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let acceptance = arguments.contains("--acceptance-profile")
        var defaults = acceptance ? UserDefaults(suiteName: "uk.co.sammcnab.Pokelet.Acceptance")! : .standard
        var supportDirectory = acceptance ? "Pokelet Acceptance" : "Pokelet"
        #if DEBUG
        isStudioAcceptance = arguments.contains("--studio-acceptance") ||
            Bundle.main.bundleIdentifier == "uk.co.sammcnab.Pokelet.StudioAcceptance"
        presentationAvailable = !isStudioAcceptance && acceptance && arguments.contains("--presentation-acceptance")
        if isStudioAcceptance {
            defaults = UserDefaults(suiteName: "uk.co.sammcnab.Pokelet.StudioAcceptance.Preferences")!
            supportDirectory = "Pokelet Studio Acceptance"
        }
        #else
        isStudioAcceptance = false
        presentationAvailable = false
        #endif
        isAcceptanceProfile = isStudioAcceptance || acceptance
        let store = PreferenceStore(defaults: defaults)
        self.store = store
        prefs = store.load()
        sound = SoundPlayer(supportDirectory: supportDirectory)
    }

    func start() {
        keys.onFire = { [weak self] action in
            guard let self else { return }
            switch action {
            case .pointer: self.togglePointer()
            case .presentation, .presentationAlternate: self.endPresentation(nil)
            }
        }
        cursor.onClick = { [weak self] in self?.playClickSound() }
        cursor.onTrackingFailure = { [weak self] in self?.trackingFailed() }
        tap.onClick = { [weak self] secondary in self?.cursor.tap(secondary: secondary) }
        tap.onStop = { [weak self] reason in self?.endPresentation(reason) }
        registerShortcuts()
        refreshLoginStatus()
        mode.setPointer(!isStudioAcceptance && prefs.restoreEnabled && prefs.lastEnabled)
        applyInputState()
    }

    func shutDown() {
        tap.invalidate()
        cursor.stop()
        keys.stop()
        sound.stopPreview()
        sound.stop()
    }

    func togglePointer() {
        guard !isStudioAcceptance else { return }
        pointerMessage = nil
        if mode.presentation { endPresentation(nil) }
        let enabled = !mode.pointer
        mode.setPointer(enabled)
        update(\.lastEnabled, enabled)
        applyInputState()
    }

    func startPresentation() {
        guard !mode.presentation, !suspended, presentationAvailable else { return }
        presentationMessage = nil
        refreshPermissionStatus()
        guard accessibilityGranted else {
            presentationMessage = "Grant Accessibility access in Presentation settings, then try again."
            return
        }
        let shortcutReady = keys.contains(.presentation) || keys.register(.presentationDefault, for: .presentation)
        guard shortcutReady else {
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

        if !mode.showsPointer { prepareClickSound() }
        let result = tap.start(shortcutReady: shortcutReady)
        _ = mode.startPresentation(tapReady: result == .ready)
        applyInputState()
        switch result {
        case .ready:
            needsInputMonitoring = false
        case .accessibilityRequired:
            presentationMessage = "Grant Accessibility access in Presentation settings, then try again."
        case .inputMonitoringRequired:
            needsInputMonitoring = true
            presentationMessage = "macOS could not observe Escape. Grant Input Monitoring in Presentation settings."
        case .mouseButtonsHeld:
            presentationMessage = "Release all mouse buttons and try again."
        case .unavailable:
            presentationMessage = "The input tap or Escape shortcut is unavailable. Try again outside secure text entry."
        }
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        guard presentationAvailable else { return }
        accessibilityGranted = PresentationTap.accessibilityGranted
        inputMonitoringGranted = PresentationTap.inputMonitoringGranted
    }

    func requestAccessibility() {
        guard presentationAvailable else { return }
        tap.requestAccessibility()
        refreshPermissionStatus()
    }

    func requestInputMonitoring() {
        guard presentationAvailable, needsInputMonitoring else { return }
        tap.requestInputMonitoring()
        refreshPermissionStatus()
    }

    func endPresentation(_ reason: String?) {
        guard mode.presentation else { return }
        tap.stop()
        mode.stopPresentation()
        presentationMessage = reason
        applyInputState()
    }

    func pause() {
        suspended = true
        tap.invalidate()
        if mode.presentation { endPresentation("Presentation Mode ended when the session became inactive.") }
        cursor.stop()
        sound.stop()
        sound.stopPreview()
    }

    func resume() {
        guard suspended else { return }
        suspended = false
        keys.clearPressedKeys()
        applyInputState()
    }

    func screensChanged() { cursor.rebuildScreens() }
    func spaceChanged() { cursor.spaceChanged() }
    func setReplacementWindow(_ window: NSWindow?) {
        cursor.replacementWindow = window
        cursor.refreshPlacement()
    }
    func keyWindowChanged() { cursor.refreshPlacement() }
    func menuTrackingChanged(started: Bool) { cursor.menuTrackingChanged(started: started) }
    func motionPreferenceChanged() { cursor.cancelAnimations() }
    func appBecameActive() {
        cursor.activationChanged(isActive: true)
        refreshLoginStatus()
        refreshPermissionStatus()
    }
    func appWillResignActive() { cursor.activationChanged(isActive: false) }

    func update<T>(_ key: WritableKeyPath<Preferences, T>, _ value: T) {
        var next = prefs
        next[keyPath: key] = value
        setPreferences(next)
    }

    private func setPreferences(_ next: Preferences) {
        let soundChanged = next.sound != prefs.sound || next.soundEnabled != prefs.soundEnabled ||
            (next.volume == 0) != (prefs.volume == 0)
        guard next != prefs else { return }
        prefs = next
        store.save(next)
        cursor.apply(next, presentation: mode.presentation)
        if soundChanged {
            sound.stopPreview()
            prepareClickSound()
        }
    }

    func setShortcut(_ shortcut: Shortcut, presentation: Bool) {
        guard !presentation || (presentationAvailable && !mode.presentation) else { return }
        let other = presentation ? prefs.pointerShortcut : prefs.presentationShortcut
        guard shortcut.isAssignable else {
            shortcutMessage = "Use a key with Control, Option or Command."
            return
        }
        guard shortcut != other, presentation || shortcut != .presentationDefault else {
            shortcutMessage = "That shortcut is already assigned in Pokelet."
            return
        }
        if isStudioAcceptance {
            shortcutMessage = nil
            update(\.pointerShortcut, shortcut)
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
        guard !isStudioAcceptance else { return }
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
                var next = self.prefs
                next.customSoundName = url.lastPathComponent
                next.sound = .custom
                let reimporting = self.prefs.sound == .custom
                self.setPreferences(next)
                if reimporting {
                    self.sound.stopPreview()
                    self.prepareClickSound()
                }
            } catch { self.audioMessage = error.localizedDescription }
        }
        if let window = NSApp.keyWindow { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { panel.begin(completionHandler: completion) }
    }

    func previewSound() {
        audioMessage = nil
        guard prefs.sound != .silent, prefs.volume > 0 else { return }
        do { try sound.preview(prefs.sound, volume: prefs.volume) }
        catch { audioMessage = error.localizedDescription }
    }

    func reset() {
        endPresentation(nil)
        mode.setPointer(false)
        cursor.stop()
        sound.stop()
        sound.stopPreview()
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

    private func refreshLoginStatus() {
        guard !isStudioAcceptance else { return }
        loginStatus = SMAppService.mainApp.status
    }

    private func registerShortcuts() {
        guard !isStudioAcceptance else { return }
        var failed: [String] = []
        if !keys.register(prefs.pointerShortcut, for: .pointer) { failed.append(prefs.pointerShortcut.title) }
        if presentationAvailable {
            if !keys.register(.presentationDefault, for: .presentation) { failed.append(Shortcut.presentationDefault.title) }
            if prefs.presentationShortcut != .presentationDefault,
               !keys.register(prefs.presentationShortcut, for: .presentationAlternate) {
                failed.append(prefs.presentationShortcut.title)
            }
        }
        shortcutMessage = failed.isEmpty ? nil : "Unavailable shortcuts: " + failed.joined(separator: ", ")
    }

    private var shouldPlayClickSound: Bool {
        prefs.soundEnabled && prefs.volume > 0 && prefs.sound != .silent
    }

    private func prepareClickSound() {
        audioMessage = nil
        audioNeedsRecovery = false
        guard cursor.isRunning, shouldPlayClickSound else { sound.stop(); return }
        do { try sound.prepare(prefs.sound) }
        catch {
            audioMessage = error.localizedDescription
            audioNeedsRecovery = true
        }
    }

    private func playClickSound() {
        guard shouldPlayClickSound else { return }
        if sound.play(volume: prefs.volume) { audioNeedsRecovery = false; return }
        guard !audioNeedsRecovery else { return }
        // Recreate the pool once if playback fails after an output change.
        prepareClickSound()
        if !sound.play(volume: prefs.volume) {
            audioNeedsRecovery = true
            if audioMessage == nil {
                audioMessage = "macOS could not play this sound. Re-enable click sounds to retry."
            }
        }
    }

    private func applyInputState() {
        cursor.apply(prefs, presentation: mode.presentation)
        guard !suspended, mode.showsPointer else {
            cursor.stop()
            sound.stop()
            return
        }
        let wasRunning = cursor.isRunning
        if cursor.start() {
            if !wasRunning { prepareClickSound() }
        } else if mode.showsPointer {
            trackingFailed()
        }
    }

    private func trackingFailed() {
        tap.invalidate()
        sound.stop()
        mode.setPointer(false)
        update(\.lastEnabled, false)
        pointerMessage = "Pokelet could not start the overlay. The macOS cursor is available."
    }
}
