import AppKit
import ApplicationServices
import AVFoundation

@main
enum OverlaySmoke {
    static func main() throws {
        NSApplication.shared.setActivationPolicy(.accessory)
        let screens = NSScreen.screens
        precondition(!screens.isEmpty, "A logged-in graphical session is required.")
        let cursor = CursorController()
        var prefs = Preferences()
        prefs.keepNative = true
        cursor.apply(prefs, presentation: false)

        for _ in 0..<3 {
            precondition(cursor.start(), "Could not start the real AppKit overlay.")
            cursor.rebuildScreens()
            let windows = NSApp.windows.compactMap { $0 as? CursorOverlayWindow }.filter(\.isVisible)
            precondition(windows.count == screens.count, "Expected one visible overlay per display.")
            for window in windows {
                precondition(window.ignoresMouseEvents && !window.isOpaque && !window.canBecomeKey)
                precondition(window.collectionBehavior.contains([.canJoinAllSpaces, .fullScreenAuxiliary]))
                precondition(window.sharingType == .readOnly)
                precondition(window.frame == window.display.frame)
            }
            let mouse = NSEvent.mouseLocation
            if let window = windows.first(where: { $0.frame.contains(mouse) }) {
                let layer = window.pointerLayer.root
                precondition(!layer.isHidden)
                precondition(layer.position == CGPoint(x: mouse.x - window.frame.minX, y: mouse.y - window.frame.minY))
                guard let character = layer.sublayers?.last else { fatalError("Character layer missing.") }
                let hotspot = PointerArt.hotspot
                precondition(character.anchorPoint == CGPoint(x: hotspot.x / PointerArt.canvas,
                                                               y: 1 - hotspot.y / PointerArt.canvas))
                for style in PointerStyle.allCases {
                    prefs.style = style
                    cursor.apply(prefs, presentation: false)
                    guard let contents = character.contents else { fatalError("Artwork missing.") }
                    precondition(CFGetTypeID(contents as CFTypeRef) == CGImage.typeID)
                    cursor.tap(secondary: false)
                    let primary = character.animation(forKey: "motion")?.duration
                    cursor.tap(secondary: true)
                    let secondary = character.animation(forKey: "motion")?.duration
                    precondition(primary != nil && secondary != nil && primary != secondary)
                }
                prefs.clickOnly = true
                cursor.apply(prefs, presentation: false)
                precondition(layer.isHidden)
                cursor.tap(secondary: false)
                precondition(!layer.isHidden)
                prefs.clickOnly = false
                cursor.apply(prefs, presentation: false)
            } else {
                fatalError("Mouse is outside the active display frames.")
            }
            cursor.stop()
            precondition(!cursor.isRunning && windows.allSatisfy { !$0.isVisible })
        }
        print("PASS: repeated overlay creation and teardown, screen geometry, click-through flags, hotspot, four rendered styles, both click animation paths and click-only reveal.")

        let tap = PresentationTap()
        let trusted = AXIsProcessTrusted()
        let tapResult = tap.start()
        let active = tap.isActive
        // Release immediately without pumping the event loop or delivering input.
        tap.stop()
        precondition(!tap.isActive && active == (tapResult == .ready))
        if !trusted {
            precondition(tapResult == .accessibilityRequired)
            print("PASS: Presentation Mode refuses to arm without Accessibility.")
        } else if tapResult == .ready {
            print("PASS: the real session tap verified its complete event mask and disarmed.")
        } else {
            print("SKIP: the real session tap was unavailable with the runner's current permissions or secure input.")
        }

        let resources = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for sound in [ClickSound.tap, .pop, .wood, .squeak] {
            let url = resources.appendingPathComponent(sound.rawValue + ".wav")
            let player = try AVAudioPlayer(contentsOf: url)
            precondition(player.numberOfChannels == 1 && player.duration > 0 && player.duration < 0.3)
        }
        let notice = resources.appendingPathComponent("QuietPointer-MIT.txt")
        let citation = try String(contentsOf: notice, encoding: .utf8)
        precondition(citation.contains("Quiet Pointer contributors"))
        print("PASS: four packaged click samples decode with AVFoundation and MIT attribution is bundled.")
    }
}
