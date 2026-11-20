import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = AppModel()
    private let menu = NSMenu()
    private var status: NSStatusItem?
    private var tokens: [AnyCancellable] = []
    private var settings: NSWindow?
    private var screenSleeping = false
    private var sessionInactive = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status = item
        menu.delegate = self
        item.menu = menu
        model.$mode.sink { [weak self] mode in self?.refreshStatus(mode) }.store(in: &tokens)
        model.start()
        menuNeedsUpdate(menu)

        let local = NotificationCenter.default
        observe(NSApplication.didChangeScreenParametersNotification, center: local) { $0.model.screensChanged() }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.activeSpaceDidChangeNotification, center: workspace) { $0.model.spaceChanged() }
        observe(NSWorkspace.willSleepNotification, center: workspace) { $0.setScreenSleeping(true) }
        observe(NSWorkspace.didWakeNotification, center: workspace) { $0.setScreenSleeping(false) }
        observe(NSWorkspace.screensDidSleepNotification, center: workspace) { $0.setScreenSleeping(true) }
        observe(NSWorkspace.screensDidWakeNotification, center: workspace) { $0.setScreenSleeping(false) }
        observe(NSWorkspace.sessionDidResignActiveNotification, center: workspace) { $0.setSessionInactive(true) }
        observe(NSWorkspace.sessionDidBecomeActiveNotification, center: workspace) { $0.setSessionInactive(false) }
        if ProcessInfo.processInfo.arguments.contains("--settings") { openSettings() }
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
            action: #selector(togglePointer), shortcut: model.prefs.pointerShortcut.title)
        addSubmenu("Pointer Style", choices: PointerStyle.allCases.map(\.title),
                   selected: PointerStyle.allCases.firstIndex(of: model.prefs.style), action: #selector(changeStyle(_:)))
        addSubmenu("Animation Intensity", choices: Intensity.allCases.map(\.title),
                   selected: model.prefs.intensity.rawValue, action: #selector(changeIntensity(_:)))
        add("Click Sounds", action: #selector(toggleSound), checked: model.prefs.soundEnabled)
        add("Presentation Mode", action: #selector(togglePresentation), checked: model.mode.presentation,
            shortcut: model.prefs.presentationShortcut.title)
        if let issue = model.presentationMessage ?? model.pointerMessage {
            let notice = NSMenuItem(title: "Open Settings for Details…", action: #selector(openSettings), keyEquivalent: "")
            notice.target = self
            notice.toolTip = issue
            menu.addItem(notice)
        }
        menu.addItem(.separator())
        add("Settings…", action: #selector(openSettings), key: ",")
        add("Quit Pokelet", action: #selector(quit), key: "q")
    }

    private func add(_ title: String, action: Selector, checked: Bool = false, shortcut: String? = nil,
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
        button.title = mode.presentation ? "  Clicks Paused" : ""
        button.imagePosition = .imageLeading
        button.toolTip = mode.presentation ? "Pokelet · Clicks paused · Escape or ⌃⌥T resumes"
            : mode.pointer ? "Pokelet · Pointer enabled" : "Pokelet · Pointer off"
        button.setAccessibilityLabel(button.toolTip)
    }

    @objc private func togglePointer() { model.togglePointer() }
    @objc private func toggleSound() { model.update(\.soundEnabled, !model.prefs.soundEnabled) }
    @objc private func togglePresentation() { model.togglePresentation() }
    @objc private func changeStyle(_ sender: NSMenuItem) { model.update(\.style, PointerStyle.allCases[sender.tag]) }
    @objc private func changeIntensity(_ sender: NSMenuItem) { model.update(\.intensity, Intensity.allCases[sender.tag]) }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settings == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 698, height: 525),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
            window.title = "Pokelet Settings"
            window.minSize = CGSize(width: 650, height: 475)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SettingsView(model: model))
            window.setFrameAutosaveName("PokeletSettings")
            if !window.setFrameUsingName("PokeletSettings") { window.center() }
            settings = window
        }
        NSApp.activate()
        settings?.makeKeyAndOrderFront(nil)
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
        if screenSleeping || sessionInactive { model.pause() }
        else { model.resume() }
    }
}
