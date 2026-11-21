import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private let model = AppModel()
    private let menu = NSMenu()
    private var status: NSStatusItem?
    private var tokens: [AnyCancellable] = []
    private var settings: NSWindow?
    private var systemSleeping = false
    private var screenSleeping = false
    private var sessionInactive = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status = item
        menu.delegate = self
        item.menu = menu
        model.isMenuBarExit = { [weak item] point in
            guard let button = item?.button, let window = button.window, window.isVisible else { return false }
            return window.convertToScreen(button.convert(button.bounds, to: nil)).contains(point)
        }
        model.$mode.sink { [weak self] mode in self?.refreshStatus(mode) }.store(in: &tokens)
        model.start()
        menuNeedsUpdate(menu)

        let local = NotificationCenter.default
        observe(NSApplication.didChangeScreenParametersNotification, center: local) { $0.model.screensChanged() }
        observe(NSWindow.didBecomeKeyNotification, center: local) { $0.model.keyWindowChanged() }
        observe(NSWindow.didResignKeyNotification, center: local) { $0.model.keyWindowChanged() }
        observe(NSMenu.didBeginTrackingNotification, center: local) { $0.model.menuTrackingChanged(started: true) }
        observe(NSMenu.didEndTrackingNotification, center: local) { $0.model.menuTrackingChanged(started: false) }
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
            local.publisher(for: name).sink { [weak self] note in
                guard let self, let window = note.object as? NSWindow, window === self.settings else { return }
                self.model.keyWindowChanged()
            }.store(in: &tokens)
        }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, center: workspace) {
            $0.model.motionPreferenceChanged()
        }
        observe(NSWorkspace.activeSpaceDidChangeNotification, center: workspace) { $0.model.spaceChanged() }
        observe(NSWorkspace.willSleepNotification, center: workspace) { $0.systemSleeping = true; $0.updateSuspension() }
        observe(NSWorkspace.didWakeNotification, center: workspace) { $0.systemSleeping = false; $0.updateSuspension() }
        observe(NSWorkspace.screensDidSleepNotification, center: workspace) { $0.setScreenSleeping(true) }
        observe(NSWorkspace.screensDidWakeNotification, center: workspace) { $0.setScreenSleeping(false) }
        observe(NSWorkspace.sessionDidResignActiveNotification, center: workspace) { $0.setSessionInactive(true) }
        observe(NSWorkspace.sessionDidBecomeActiveNotification, center: workspace) { $0.setSessionInactive(false) }
        if model.isStudioAcceptance || ProcessInfo.processInfo.arguments.contains("--settings") { openSettings() }
    }

    func applicationDidBecomeActive(_ notification: Notification) { model.appBecameActive() }
    func applicationWillResignActive(_ notification: Notification) { model.appWillResignActive() }

    func applicationWillTerminate(_ notification: Notification) {
        tokens.removeAll()
        model.shutDown()
        if let status { NSStatusBar.system.removeStatusItem(status) }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if model.mode.presentation {
            let active = NSMenuItem(title: "Clicks paused · Esc or ⌃⌥T to exit", action: nil, keyEquivalent: "")
            menu.addItem(active)
        }
        add(model.mode.pointer ? "Disable Pointer" : "Enable Pointer",
            action: model.isStudioAcceptance ? nil : #selector(togglePointer), shortcut: model.prefs.pointerShortcut.title)
        addSubmenu("Pointer Style", choices: PointerStyle.allCases.map(\.title),
                   selected: PointerStyle.allCases.firstIndex(of: model.prefs.style), action: #selector(changeStyle(_:)))
        addSubmenu("Animation Intensity", choices: Intensity.allCases.map(\.title),
                   selected: model.prefs.intensity.rawValue, action: #selector(changeIntensity(_:)))
        add("Click Sounds", action: #selector(toggleSound), checked: model.prefs.soundEnabled)
        if model.mode.presentation {
            add("End Presentation Mode", action: #selector(togglePresentation), shortcut: Shortcut.presentationDefault.title)
        } else if model.presentationAvailable {
            add("Start Presentation Mode", action: #selector(togglePresentation), shortcut: Shortcut.presentationDefault.title)
        } else {
            add("Presentation Settings…", action: #selector(openPresentationSettings))
        }
        if let issue = model.presentationMessage ?? model.pointerMessage {
            let action = model.presentationMessage == nil ? #selector(openSettings) : #selector(openPresentationSettings)
            let notice = NSMenuItem(title: "Open Settings for Details…", action: action, keyEquivalent: "")
            notice.target = self
            notice.toolTip = issue
            menu.addItem(notice)
        }
        menu.addItem(.separator())
        add("Settings…", action: #selector(openSettings), key: ",")
        add("Quit Pokelet", action: #selector(quit), key: "q")
    }

    private func add(_ title: String, action: Selector?, checked: Bool = false, shortcut: String? = nil,
                     key: String = "") {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
        entry.target = self
        entry.state = checked ? .on : .off
        if let shortcut { entry.toolTip = shortcut }
        menu.addItem(entry)
    }

    private func addSubmenu(_ title: String, choices: [String], selected: Int?, action: Selector) {
        let entry = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        for (index, choice) in choices.enumerated() {
            let item = NSMenuItem(title: choice, action: action, keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = index == selected ? .on : .off
            submenu.addItem(item)
        }
        entry.submenu = submenu
        menu.addItem(entry)
    }

    private func refreshStatus(_ mode: InteractionMode) {
        guard let button = status?.button else { return }
        button.image = StatusIcon.image(active: mode.showsPointer, presentation: mode.presentation)
        // Keep the recovery control in the same menu bar slot when clicks pause.
        button.imagePosition = .imageOnly
        button.toolTip = mode.presentation ? "Pokelet · Clicks paused · Click here, Escape or ⌃⌥T to resume"
            : mode.pointer ? "Pokelet · Pointer enabled" : "Pokelet · Pointer off"
        button.setAccessibilityLabel(button.toolTip)
    }

    @objc private func togglePointer() { model.togglePointer() }
    @objc private func toggleSound() { model.update(\.soundEnabled, !model.prefs.soundEnabled) }
    @objc private func togglePresentation() { model.togglePresentation() }
    @objc private func changeStyle(_ sender: NSMenuItem) { model.update(\.style, PointerStyle.allCases[sender.tag]) }
    @objc private func changeIntensity(_ sender: NSMenuItem) { model.update(\.intensity, Intensity.allCases[sender.tag]) }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openPresentationSettings() {
        model.settingsPage = .presentation
        openSettings()
    }

    @objc private func openSettings() {
        if settings == nil {
            let visibleSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 936, height: 598)
            let initialSize = CGSize(width: min(936, visibleSize.width), height: min(598, visibleSize.height))
            let window = NSWindow(contentRect: CGRect(origin: .zero, size: initialSize),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
            window.title = "Pokelet Studio"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.collectionBehavior.insert(.fullScreenPrimary)
            window.contentMinSize = CGSize(width: 540, height: 440)
            window.isReleasedWhenClosed = false
            window.delegate = self
            let hosting = NSHostingController(rootView: SettingsView(model: model))
            hosting.sizingOptions = []
            window.contentViewController = hosting
            window.setContentSize(initialSize)
            let frameName = model.isStudioAcceptance ? "PokeletStudioAcceptance"
                : model.isAcceptanceProfile ? "PokeletSettingsAcceptance" : "PokeletSettings"
            window.setFrameAutosaveName(frameName)
            if !window.setFrameUsingName(frameName) { window.center() }
            settings = window
            model.setReplacementWindow(window)
        }
        NSApp.activate()
        if settings?.isMiniaturized == true { settings?.deminiaturize(nil) }
        settings?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === settings else { return }
        settings = nil
    }

    private func observe(_ name: Notification.Name, center: NotificationCenter,
                         _ callback: @escaping (AppDelegate) -> Void) {
        center.publisher(for: name).sink { [weak self] _ in
            guard let self else { return }
            if Thread.isMainThread { callback(self) }
            else { DispatchQueue.main.async { [weak self] in if let self { callback(self) } } }
        }.store(in: &tokens)
    }

    private func setScreenSleeping(_ sleeping: Bool) {
        screenSleeping = sleeping
        updateSuspension()
    }

    private func setSessionInactive(_ inactive: Bool) {
        sessionInactive = inactive
        updateSuspension()
    }

    private func updateSuspension() {
        if systemSleeping || screenSleeping || sessionInactive { model.pause() }
        else { model.resume() }
    }
}
