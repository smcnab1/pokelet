import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSMenuItemValidation, NSWindowDelegate {
    private let model = AppModel()
    private lazy var updates = UpdateService(defaults: updateHistoryDefaults)
    private let menu = NSMenu()
    private var status: NSStatusItem?
    private var statusVisibility: NSKeyValueObservation?
    private var tokens: [AnyCancellable] = []
    private var studioWindow: NSWindow?
    private var systemSleeping = false
    private var screenSleeping = false
    private var sessionInactive = false

    private var updateHistoryDefaults: UserDefaults? {
        #if DEBUG
        if Bundle.main.bundleIdentifier == UpdateService.acceptanceBundleID { return .standard }
        #endif
        return model.isAcceptanceProfile ? nil : .standard
    }

    private var studioFrameName: String {
        #if DEBUG || POKELET_UPDATE_ACCEPTANCE
        if Bundle.main.bundleIdentifier == UpdateService.acceptanceBundleID { return "PokeletUpdateAcceptance" }
        #endif
        if model.isStudioAcceptance { return "PokeletStudioAcceptance" }
        return model.isAcceptanceProfile ? "PokeletSettingsAcceptance" : "PokeletSettings"
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Pokelet")
        appMenu.delegate = self
        menuNeedsUpdate(appMenu)
        mainMenu.addItem(appItem)
        mainMenu.setSubmenu(appMenu, for: appItem)

        let windowMenu = NSMenu(title: "Window")
        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        mainMenu.addItem(windowItem)
        mainMenu.setSubmenu(windowMenu, for: windowItem)
        add("Close Studio", to: windowMenu, action: #selector(closeStudio), key: "w")
        add("Minimise Studio", to: windowMenu, action: #selector(minimiseStudio), key: "m")
        let fullScreen = windowMenu.addItem(withTitle: "Toggle Full Screen",
                                            action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.command, .control]
        NSApp.mainMenu = mainMenu
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.delegate = self
        model.isMenuBarExit = { [weak self] point in
            guard let button = self?.status?.button, let window = button.window, window.isVisible else { return false }
            return window.convertToScreen(button.convert(button.bounds, to: nil)).contains(point)
        }
        model.$mode.sink { [weak self] mode in self?.refreshStatus(mode) }.store(in: &tokens)
        model.$prefs.map(\.applicationBehaviour).removeDuplicates().sink { [weak self] behaviour in
            self?.updateApplicationBehaviour(behaviour)
        }.store(in: &tokens)
        model.start()

        let local = NotificationCenter.default
        observe(NSApplication.didChangeScreenParametersNotification, center: local) {
            $0.model.screensChanged()
            $0.updateDockVisibility($0.model.prefs.applicationBehaviour)
        }
        observe(NSWindow.didBecomeKeyNotification, center: local) { $0.model.keyWindowChanged() }
        observe(NSWindow.didResignKeyNotification, center: local) { $0.model.keyWindowChanged() }
        observe(NSMenu.didBeginTrackingNotification, center: local) { $0.model.menuTrackingChanged(started: true) }
        observe(NSMenu.didEndTrackingNotification, center: local) { $0.model.menuTrackingChanged(started: false) }
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification, NSWindow.didChangeOcclusionStateNotification] {
            local.publisher(for: name).sink { [weak self] note in
                guard let self, let window = note.object as? NSWindow else { return }
                if window === self.status?.button?.window { self.scheduleDockUpdate() }
                if window === self.studioWindow { self.model.keyWindowChanged() }
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
        updates.start()
        if ProcessInfo.processInfo.arguments.contains("--settings") ||
            (model.isStudioAcceptance && !ProcessInfo.processInfo.arguments.contains("--background")) { openStudio() }
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // AppKit dispatches the launch Apple event here for a regular user launch.
        let launchEvent = NSAppleEventManager.shared().currentAppleEvent
        let loginItem = launchEvent?.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?
            .enumCodeValue == OSType(keyAELaunchedAsLogInItem)
        if !loginItem && !ProcessInfo.processInfo.arguments.contains("--background") { openStudio() }
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if sender.isHidden { sender.unhide(nil) }
        openStudio()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDidBecomeActive(_ notification: Notification) { model.appBecameActive() }
    func applicationWillResignActive(_ notification: Notification) { model.appWillResignActive() }

    func applicationWillTerminate(_ notification: Notification) {
        tokens.removeAll()
        model.shutDown()
        removeStatusItem()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        add("Open Pokelet Studio", to: menu, action: #selector(openStudio), key: ",")
        if updates.isAvailable {
            add(updates.pendingVersion == nil ? "Check for Updates…" : "Update Available…",
                to: menu, action: #selector(checkForUpdates))
        } else {
            add("Updates…", to: menu, action: #selector(openUpdateSettings))
        }
        menu.addItem(.separator())
        if model.mode.presentation {
            let active = NSMenuItem(title: "Clicks paused · Esc or ⌃⌥T to exit", action: nil, keyEquivalent: "")
            menu.addItem(active)
        }
        add(model.mode.pointer ? "Disable Pointer" : "Enable Pointer", to: menu,
            action: model.isStudioAcceptance ? nil : #selector(togglePointer), shortcut: model.prefs.pointerShortcut.title)
        addSubmenu("Pointer Style", to: menu, choices: PointerStyle.allCases.map(\.title),
                   selected: PointerStyle.allCases.firstIndex(of: model.prefs.style), action: #selector(changeStyle(_:)))
        addSubmenu("Animation Intensity", to: menu, choices: Intensity.allCases.map(\.title),
                   selected: model.prefs.intensity.rawValue, action: #selector(changeIntensity(_:)))
        add("Click Sounds", to: menu, action: #selector(toggleSound), checked: model.prefs.soundEnabled)
        if model.mode.presentation {
            add("End Presentation Mode", to: menu, action: #selector(endPresentation), shortcut: Shortcut.presentationDefault.title)
        } else if model.presentationAvailable {
            add("Start Presentation Mode", to: menu, action: #selector(startPresentation))
        } else {
            add("Presentation Settings…", to: menu, action: #selector(openPresentationSettings))
        }
        if let issue = model.presentationMessage ?? model.pointerMessage {
            let action = model.presentationMessage == nil ? #selector(openStudio) : #selector(openPresentationSettings)
            let notice = NSMenuItem(title: "Open Settings for Details…", action: action, keyEquivalent: "")
            notice.target = self
            notice.toolTip = issue
            menu.addItem(notice)
        }
        menu.addItem(.separator())
        add("Quit Pokelet", to: menu, action: #selector(quit), key: "q")
    }

    private func add(_ title: String, to menu: NSMenu, action: Selector?, checked: Bool = false, shortcut: String? = nil,
                     key: String = "") {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
        entry.target = self
        entry.state = checked ? .on : .off
        if let shortcut { entry.toolTip = shortcut }
        menu.addItem(entry)
    }

    private func addSubmenu(_ title: String, to menu: NSMenu, choices: [String], selected: Int?, action: Selector) {
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

    private func updateApplicationBehaviour(_ behaviour: ApplicationBehaviour) {
        if behaviour.showInMenuBar, status == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.autosaveName = "Pokelet"
            item.menu = menu
            status = item
            refreshStatus(model.mode)
            statusVisibility = item.observe(\.isVisible) { [weak self] _, _ in
                self?.scheduleDockUpdate()
            }
            scheduleDockUpdate()
        }
        // Provide a Dock route before removing the user's menu bar route.
        updateDockVisibility(behaviour)
        if !behaviour.showInMenuBar, NSApp.activationPolicy() == .regular { removeStatusItem() }
    }

    private func removeStatusItem() {
        statusVisibility = nil
        if let status { NSStatusBar.system.removeStatusItem(status) }
        status = nil
    }

    nonisolated private func scheduleDockUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.status != nil else { return }
            self.updateDockVisibility(self.model.prefs.applicationBehaviour)
        }
    }

    private func updateDockVisibility(_ behaviour: ApplicationBehaviour) {
        let showsDock = behaviour.showsDock(studioOpen: studioWindow != nil, menuBarAvailable: menuBarAvailable)
        let policy: NSApplication.ActivationPolicy = showsDock ? .regular : .accessory
        if NSApp.activationPolicy() != policy { NSApp.setActivationPolicy(policy) }
    }

    private var menuBarAvailable: Bool {
        guard let status, status.isVisible, let window = status.button?.window, window.isVisible,
              window.frame.height > 0 else { return false }
        // AppKit can report isVisible even when the system gives the item no space.
        return NSScreen.screens.contains { $0.frame.intersects(window.frame) }
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
    @objc private func startPresentation() { model.startPresentation() }
    @objc private func endPresentation() { model.endPresentation(nil) }
    @objc private func changeStyle(_ sender: NSMenuItem) { model.update(\.style, PointerStyle.allCases[sender.tag]) }
    @objc private func changeIntensity(_ sender: NSMenuItem) { model.update(\.intensity, Intensity.allCases[sender.tag]) }
    @objc private func checkForUpdates() { updates.checkForUpdates() }
    @objc private func openUpdateSettings() {
        model.settingsPage = .updates
        openStudio()
    }

    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func closeStudio() { studioWindow?.performClose(nil) }
    @objc private func minimiseStudio() { studioWindow?.miniaturize(nil) }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(checkForUpdates): updates.canCheck && !model.mode.presentation
        case #selector(closeStudio): studioWindow != nil
        case #selector(minimiseStudio): studioWindow?.isMiniaturized == false
        default: true
        }
    }

    @objc private func openPresentationSettings() {
        model.settingsPage = .presentation
        openStudio()
    }

    @objc private func openStudio() {
        if studioWindow == nil {
            let preferredSize = SettingsView.defaultWindowSize(largerText: model.prefs.largerStudioText == true)
            let visibleSize = NSScreen.main?.visibleFrame.size ?? preferredSize
            let initialSize = CGSize(width: min(preferredSize.width, visibleSize.width),
                                     height: min(preferredSize.height, visibleSize.height))
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
            let hosting = NSHostingController(rootView: SettingsView(model: model, updates: updates))
            hosting.sizingOptions = []
            window.contentViewController = hosting
            window.setContentSize(initialSize)
            window.setFrameAutosaveName(studioFrameName)
            if !window.setFrameUsingName(studioFrameName) { window.center() }
            studioWindow = window
            model.setReplacementWindow(window)
        }
        updateDockVisibility(model.prefs.applicationBehaviour)
        NSApp.activate()
        if studioWindow?.isMiniaturized == true { studioWindow?.deminiaturize(nil) }
        studioWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === studioWindow else { return }
        studioWindow = nil
        model.setReplacementWindow(nil)
        updateDockVisibility(model.prefs.applicationBehaviour)
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
