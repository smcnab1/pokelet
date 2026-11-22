import AppKit
import ApplicationServices
import Carbon.HIToolbox

// Run against the foreground Debug acceptance app with its Presentation pane open.
// The driver needs existing event-posting and Accessibility access.
// Keep the candidate without an Accessibility grant so suppression cannot start.
@main
enum PresentationRecoverySmoke {
    private static let bundleID = "uk.co.sammcnab.Pokelet.PresentationAcceptance"
    private static let startMessage = "Grant Accessibility access in Presentation settings, then try again."

    static func main() {
        do {
            try verifyIdleRecoveryShortcut()
        } catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func verifyIdleRecoveryShortcut() throws {
        guard CommandLine.arguments.count == 2 else { throw Failure("Pass the Debug acceptance bundle path.") }
        let path = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL.path
        guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            throw Failure("The test driver needs existing Accessibility and event-posting access.")
        }
        guard let app = NSWorkspace.shared.frontmostApplication, app.bundleIdentifier == bundleID,
              app.bundleURL?.standardizedFileURL.path == path else {
            throw Failure("The exact isolated Debug acceptance app must be frontmost.")
        }
        let accessibility = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(accessibility, 1)
        try checkUnarmed(accessibility)

        for _ in 0..<2 {
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier else {
                throw Failure("The acceptance app lost focus.")
            }
            for isDown in [true, false] {
                guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_T), keyDown: isDown) else {
                    throw Failure("Could not create the test keyboard event.")
                }
                event.flags = [.maskControl, .maskAlternate]
                event.post(tap: .cghidEventTap)
                Thread.sleep(forTimeInterval: 0.08)
            }
            // Carbon delivers the shortcut asynchronously. Check throughout the delivery window.
            for _ in 0..<6 {
                Thread.sleep(forTimeInterval: 0.05)
                try checkUnarmed(accessibility)
            }
        }
        print("Two Control–Option–T presses left the candidate idle without attempting activation.")
    }

    private static func checkUnarmed(_ app: AXUIElement) throws {
        let rows = elements(in: app, under: kAXWindowsAttribute)
        guard rows.contains(where: { hasText("Accessibility", on: $0) }),
              rows.contains(where: { hasText("Required", on: $0) }),
              rows.contains(where: {
                  hasText("Start Presentation Mode", on: $0) && attribute(kAXEnabledAttribute, on: $0) as? Bool == false
              }) else {
            throw Failure("The Presentation pane must show Accessibility Required and a disabled Start button.")
        }
        guard !rows.contains(where: { hasText(startMessage, on: $0) }) else {
            throw Failure("The candidate attempted to start Presentation Mode.")
        }
    }

    private static func elements(in element: AXUIElement, under key: String) -> [AXUIElement] {
        let children = attribute(key, on: element) as? [AXUIElement] ?? []
        return children.flatMap { [$0] + elements(in: $0, under: kAXChildrenAttribute) }
    }

    private static func hasText(_ text: String, on element: AXUIElement) -> Bool {
        [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute].contains {
            attribute($0, on: element) as? String == text
        }
    }

    private static func attribute(_ key: String, on element: AXUIElement) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }
        return result
    }

    private struct Failure: LocalizedError {
        let message: String
        init(_ message: String) { self.message = message }
        var errorDescription: String? { message }
    }
}
