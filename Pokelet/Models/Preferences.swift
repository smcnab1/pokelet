import Carbon.HIToolbox
import Foundation

enum PointerStyle: String, Codable, CaseIterable, Identifiable {
    case finger, catPaw, foamFinger, comicArrow
    var id: Self { self }
    var title: String {
        switch self {
        case .finger: "The Finger"
        case .catPaw: "Cat Paw"
        case .foamFinger: "Foam Finger"
        case .comicArrow: "Comic Arrow"
        }
    }
}

enum Palette: String, Codable, CaseIterable, Identifiable {
    case original, white, black, custom, peach, mint, lilac, ice
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

enum Intensity: Int, Codable, CaseIterable, Identifiable {
    case barelyThere, polite, playful, dramatic, unhinged
    var id: Self { self }
    var title: String {
        switch self {
        case .barelyThere: "Barely There"
        case .polite: "Polite"
        case .playful: "Playful"
        case .dramatic: "Dramatic"
        case .unhinged: "Unhinged"
        }
    }

    func energy(clicks: Int, reactive: Bool) -> Double {
        let base = [0.15, 0.34, 0.56, 0.76, 1.0][rawValue]
        let boost = reactive ? Double(min(max(clicks, 1) - 1, 5)) * 0.105 : 0
        return base * (1 + boost)
    }
}

enum ClickSound: String, Codable, CaseIterable, Identifiable {
    case tap, pop, wood, squeak, silent, custom
    var id: Self { self }
    var title: String {
        switch self {
        case .tap: "Soft Tap"
        case .pop: "Cartoon Pop"
        case .wood: "Wooden Knock"
        case .squeak: "Rubber Squeak"
        case .silent: "Silent"
        case .custom: "Custom"
        }
    }
}

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let pointerDefault = Self(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(controlKey | optionKey))
    static let presentationDefault = Self(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(controlKey | optionKey))

    var title: String {
        let symbols: [(Int, String)] = [(controlKey, "⌃"), (optionKey, "⌥"), (shiftKey, "⇧"), (cmdKey, "⌘")]
        return symbols.filter { modifiers & UInt32($0.0) != 0 }.map(\.1).joined()
            + KeyCodeNames.name(for: keyCode)
    }

    var isAssignable: Bool {
        keyCode < 128 && keyCode != kVK_Escape &&
            modifiers & UInt32(cmdKey | controlKey | optionKey) != 0 &&
            modifiers & ~UInt32(cmdKey | controlKey | optionKey | shiftKey) == 0
    }
}

struct Preferences: Codable, Equatable {
    static let defaultCustomColour: UInt32 = 0xE58B51
    static let sizeRange: ClosedRange<Double> = 44...132
    var style = PointerStyle.finger
    var palette = Palette.original
    var customColour: UInt32?
    var size: Double = 76
    var outline = true
    var shadow = true
    var clickOnly = false
    var keepNative = true
    var intensity = Intensity.playful
    var animate = true
    var effects = true
    var reactive = true
    var reducedMotion = false
    var celebration = true
    var directionBounce = false
    var soundEnabled = false
    var sound = ClickSound.tap
    var volume = 0.35
    var customSoundName: String?
    var restoreEnabled = false
    var lastEnabled = false
    var largerStudioText: Bool?
    var pointerShortcut = Shortcut.pointerDefault
    var presentationShortcut = Shortcut.presentationDefault
}

struct PreferenceStore {
    static let key = "PokeletPreferences.v1"
    let defaults: UserDefaults

    func load() -> Preferences {
        guard let data = defaults.data(forKey: Self.key),
              var prefs = try? JSONDecoder().decode(Preferences.self, from: data) else {
            return Preferences()
        }
        prefs.size = min(max(prefs.size, Preferences.sizeRange.lowerBound), Preferences.sizeRange.upperBound)
        if let colour = prefs.customColour, colour > 0xFFFFFF { prefs.customColour = nil }
        prefs.volume = min(max(prefs.volume, 0), 1)
        if !prefs.pointerShortcut.isAssignable || prefs.pointerShortcut == .presentationDefault {
            prefs.pointerShortcut = .pointerDefault
        }
        if !prefs.presentationShortcut.isAssignable || prefs.presentationShortcut == prefs.pointerShortcut {
            prefs.presentationShortcut = .presentationDefault
        }
        return prefs
    }

    func save(_ prefs: Preferences) {
        if let data = try? JSONEncoder().encode(prefs) { defaults.set(data, forKey: Self.key) }
    }

    func reset() { defaults.removeObject(forKey: Self.key) }
}
