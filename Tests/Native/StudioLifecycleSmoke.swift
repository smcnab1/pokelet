import AppKit
import ApplicationServices

// Run on an interactive Mac with Accessibility access, against a Studio-only Debug bundle.
@main
enum StudioLifecycleSmoke {
    private static let bundleID = "uk.co.sammcnab.Pokelet.StudioAcceptance"

    static func main() {
        do {
            try run()
        } catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func run() throws {
        guard CommandLine.arguments.count == 2 else { throw Failure("Pass the Studio acceptance bundle path.") }
        let path = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL.path
        guard let bundle = Bundle(path: path), bundle.bundleIdentifier == bundleID,
              let executable = bundle.executableURL else { throw Failure("Use a Debug bundle with ID \(bundleID).") }
        let debugFlag = Data("--studio-acceptance".utf8)
        // Xcode can put Debug code in a dylib beside the executable stub.
        let images = [executable, executable.appendingPathExtension("debug.dylib")]
        guard images.contains(where: { (try? Data(contentsOf: $0, options: .mappedIfSafe).range(of: debugFlag)) != nil })
        else { throw Failure("The bundle is missing the Studio acceptance profile.") }
        guard AXIsProcessTrusted() else { throw Failure("This smoke test requires existing Accessibility access.") }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty else {
            throw Failure("Quit the Studio acceptance bundle before the smoke test.")
        }

        try open(path)
        let app = try waitFor("the acceptance process to launch") {
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                .first { $0.bundleURL?.standardizedFileURL.path == path }
        }
        defer { if !app.isTerminated { app.terminate() } }
        let accessibility = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(accessibility, 1)

        for _ in 0..<3 {
            let studio = try waitFor("one Studio window") {
                let windows = studioWindows(in: accessibility)
                return windows?.count == 1 ? windows?.first : nil
            }
            guard let close = attribute(kAXCloseButtonAttribute, on: studio),
                  AXUIElementPerformAction(close as! AXUIElement, kAXPressAction as CFString) == .success else {
                throw Failure("Could not press Studio’s close button.")
            }
            _ = try waitFor("Studio to close without terminating") {
                studioWindows(in: accessibility)?.isEmpty == true && !app.isTerminated ? true : nil
            }
            try open(path)
            _ = try waitFor("Studio to reopen in the same process") {
                studioWindows(in: accessibility)?.count == 1 &&
                    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                    .map(\.processIdentifier) == [app.processIdentifier] ? true : nil
            }
        }
        guard app.terminate() else { throw Failure("Could not quit the acceptance process.") }
        _ = try waitFor("the acceptance process to quit") { app.isTerminated ? true : nil }
        print("Studio reopened three times in the original process and then quit.")
    }

    private static func open(_ path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw Failure("Launch Services could not open the bundle.") }
    }

    private static func studioWindows(in app: AXUIElement) -> [AXUIElement]? {
        (attribute(kAXWindowsAttribute, on: app) as? [AXUIElement])?.filter {
            attribute(kAXTitleAttribute, on: $0) as? String == "Pokelet Studio"
        }
    }

    private static func attribute(_ name: String, on element: AXUIElement) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }

    private static func waitFor<T>(_ state: String, value: () -> T?) throws -> T {
        let deadline = ProcessInfo.processInfo.systemUptime + 6
        repeat {
            if let result = value() { return result }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        } while ProcessInfo.processInfo.systemUptime < deadline
        throw Failure("Timed out waiting for \(state).")
    }

    private struct Failure: LocalizedError {
        let message: String
        init(_ message: String) { self.message = message }
        var errorDescription: String? { message }
    }
}
