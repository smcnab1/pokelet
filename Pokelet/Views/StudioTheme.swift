import SwiftUI

enum StudioTheme {
    static let window = adaptive(light: 0xF8F4F1, dark: 0x19141F)
    static let surface = adaptive(light: 0xF0E9ED, dark: 0x241C2E)
    static let secondary = adaptive(light: 0x60566B, dark: 0xC6B9D1)
    static let accent = adaptive(light: 0x533299, dark: 0xCFB6FF)
    static let selection = adaptive(light: 0xEDE2F6, dark: 0x3D2D50)
    static let line = adaptive(light: 0xE1D6E2, dark: 0x3A3044)
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
    let detail: String?

    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .studioFont(.largeTitle, weight: .semibold)
                .tracking(-0.7)
                .accessibilityAddTraits(.isHeader)
            if let detail { StudioNote(detail) }
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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let symbol { StudioLeadingIcon(symbol: symbol) }
            Text(message).fixedSize(horizontal: false, vertical: true)
        }
        .studioFont(.callout)
        .foregroundStyle(warning ? StudioTheme.warning : StudioTheme.secondary)
    }
}

struct StudioButtonStyle: ButtonStyle {
    let radius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        StudioButtonLabel(label: configuration.label, pressed: configuration.isPressed,
                          radius: radius)
    }

    private struct StudioButtonLabel<Label: View>: View {
        let label: Label
        let pressed: Bool
        let radius: CGFloat
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var hovered = false

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: radius)
            label
                .overlay {
                    if enabled && (hovered || pressed) {
                        shape.fill(Color.primary.opacity(pressed ? 0.11 : 0.06))
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    if focused { shape.strokeBorder(StudioTheme.accent, lineWidth: 2).allowsHitTesting(false) }
                }
                .contentShape(shape)
                .opacity(enabled ? 1 : 0.48)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
        }
    }
}

struct StudioSwitch: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .frame(minHeight: 22)
    }
}

struct StudioSlider: View {
    let title: String
    let accessibilityTitle: String
    let displayValue: String
    let spokenValue: String
    let range: ClosedRange<Double>
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .studioFont(.caption, weight: .semibold)
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(StudioTheme.selection, in: RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(StudioTheme.accent)
            }
            .accessibilityHidden(true)
            Slider(value: $value, in: range) { Text(accessibilityTitle) }
                .labelsHidden()
                .controlSize(.small)
                .accessibilityValue(spokenValue)
        }
    }
}

struct StudioColumns<Content: View>: View {
    let wide: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 30)) :
            AnyLayout(VStackLayout(alignment: .leading, spacing: 22))
        layout(content)
    }
}

extension View {
    func studioFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(StudioFont(style: style, weight: weight))
    }
}

@MainActor
extension AppModel {
    func preference<T>(_ path: WritableKeyPath<Preferences, T>) -> Binding<T> {
        Binding(get: { self.prefs[keyPath: path] }, set: { self.update(path, $0) })
    }
}

struct StudioLeadingIcon: View {
    let symbol: String
    @Environment(\.studioLargerText) private var largerText

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: largerText ? 15 : 13, weight: .medium))
            .frame(width: 22)
            .accessibilityHidden(true)
    }
}

struct StudioLabel: View {
    let title: String
    let symbol: String
    var detail: String?

    init(_ title: String, symbol: String, detail: String? = nil) {
        self.title = title
        self.symbol = symbol
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            StudioLeadingIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .studioFont(.callout, weight: .regular)
                        .foregroundStyle(StudioTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
