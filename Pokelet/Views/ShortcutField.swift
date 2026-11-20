import Carbon.HIToolbox
import SwiftUI

struct ShortcutField: View {
    let label: String
    let shortcut: Shortcut
    let onChange: (Shortcut) -> Void
    @State private var monitor: Any?
    @State private var recordingWindow: NSWindow?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(monitor == nil ? shortcut.title : "Press shortcut…") {
                if monitor == nil { record() }
                else { stop() }
            }
            .frame(minWidth: 108, alignment: .trailing)
            .accessibilityLabel("Change \(label) shortcut")
            .accessibilityValue(monitor == nil ? shortcut.title : "Recording")
        }
        .onDisappear(perform: stop)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { note in
            if note.object as? NSWindow === recordingWindow { stop() }
        }
    }

    private func record() {
        recordingWindow = NSApp.keyWindow
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.window === recordingWindow else { return event }
            if event.keyCode == kVK_Escape { stop(); return nil }
            var modifiers: UInt32 = 0
            if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
            if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
            if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
            if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
            stop()
            onChange(Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers))
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recordingWindow = nil
    }
}
