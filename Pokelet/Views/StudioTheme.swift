import SwiftUI

enum StudioTheme {
    static let window = adaptive(light: 0xF8F5F2, dark: 0x1A1622)
    static let surface = adaptive(light: 0xFFFCFA, dark: 0x241E2D)
    static let secondary = adaptive(light: 0x60566B, dark: 0xC6B9D1)
    static let accent = adaptive(light: 0x533299, dark: 0xCFB6FF)
    static let selection = adaptive(light: 0xEDE4FA, dark: 0x423355)
    static let line = adaptive(light: 0xDFD6E3, dark: 0x42364D)
    static let warning = adaptive(light: 0x805314, dark: 0xFFD089)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(colour: isDark ? dark : light)
        })
    }
}

extension NSColor {
    fileprivate convenience init(colour: UInt32) {
        self.init(srgbRed: Double((colour >> 16) & 255) / 255,
                  green: Double((colour >> 8) & 255) / 255,
                  blue: Double(colour & 255) / 255, alpha: 1)
    }
}

extension EnvironmentValues {
    @Entry var studioLargerText = false
}

private struct StudioFont: ViewModifier {
    let style: Font.TextStyle
    let weight: Font.Weight?
    @Environment(\.studioLargerText) private var largerText

    func body(content: Content) -> some View {
        if largerText {
            content.font(.system(size: largeSize, weight: weight ?? (style == .headline ? .semibold : .regular)))
        } else {
            content.font(.system(style, weight: weight))
        }
    }

    private var largeSize: CGFloat {
        switch style {
        case .largeTitle: 32
        case .headline: 17
        case .callout: 15
        case .caption: 13
        default: 16
        }
    }
}

struct StudioHeading: View {
    let title: String
    let detail: String

    init(_ title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .studioFont(.largeTitle, weight: .semibold)
                .tracking(-0.7)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .studioFont(.callout)
                .foregroundStyle(StudioTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StudioSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .studioFont(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 11, content: content)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StudioNote: View {
    let message: String
    var symbol: String? = nil
    var warning = false

    init(_ message: String, symbol: String? = nil, warning: Bool = false) {
        self.message = message
        self.symbol = symbol
        self.warning = warning
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
            Text(message).fixedSize(horizontal: false, vertical: true)
        }
        .studioFont(.callout)
        .foregroundStyle(warning ? StudioTheme.warning : StudioTheme.secondary)
    }
}

struct StudioButtonStyle: ButtonStyle {
    let radius: CGFloat
    var dimWhenDisabled = true

    func makeBody(configuration: Configuration) -> some View {
        StudioButtonLabel(label: configuration.label, pressed: configuration.isPressed,
                          radius: radius, dimWhenDisabled: dimWhenDisabled)
    }

    private struct StudioButtonLabel<Label: View>: View {
        let label: Label
        let pressed: Bool
        let radius: CGFloat
        let dimWhenDisabled: Bool
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var hovered = false

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: radius)
            label
                .background {
                    if enabled && (hovered || pressed) {
                        shape.fill(Color.primary.opacity(pressed ? 0.11 : 0.06))
                    }
                }
                .overlay {
                    if focused { shape.strokeBorder(StudioTheme.accent, lineWidth: 2).allowsHitTesting(false) }
                }
                .contentShape(shape)
                .opacity(enabled || !dimWhenDisabled ? 1 : 0.48)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
        }
    }
}

extension View {
    func studioFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(StudioFont(style: style, weight: weight))
    }

    func studioSurface(radius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        return background(StudioTheme.surface, in: shape)
            .overlay(shape.strokeBorder(StudioTheme.line).allowsHitTesting(false))
    }
}

extension AppModel {
    func preference<T>(_ path: WritableKeyPath<Preferences, T>) -> Binding<T> {
        Binding(get: { self.prefs[keyPath: path] }, set: { self.update(path, $0) })
    }
}
