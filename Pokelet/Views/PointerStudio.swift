import SwiftUI

struct PointerStudio: View {
    @ObservedObject var model: AppModel
    let wide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Your pointer", detail: "Pick a character, then make it your own.")
            let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 22)) :
                AnyLayout(VStackLayout(alignment: .leading, spacing: 22))
            layout {
                previewAndCharacters
                inspector
                    .frame(minWidth: wide ? 254 : nil, idealWidth: wide ? 290 : nil,
                           maxWidth: wide ? 332 : .infinity, alignment: .leading)
            }
        }
    }

    private var previewAndCharacters: some View {
        let layout = wide ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18)) :
            AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            CharacterPreview(prefs: model.prefs, expanded: wide)
                .frame(maxWidth: .infinity)
            CharacterPicker(selection: model.preference(\.style), compact: !wide)
                .frame(width: wide ? nil : 176)
        }
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 15) {
            StudioSection("Appearance") {
                PalettePicker(model: model)
                VStack(spacing: 5) {
                    HStack {
                        Text("Size")
                        Spacer()
                        Text("\(Int(model.prefs.size)) pt")
                            .monospacedDigit()
                            .foregroundStyle(StudioTheme.secondary)
                    }
                    .accessibilityHidden(true)
                    Slider(value: size, in: Preferences.sizeRange) { Text("Pointer size") }
                        .labelsHidden()
                        .accessibilityValue("\(Int(model.prefs.size)) points")
                        .accessibilityIdentifier("studio.pointer.size")
                }
                Toggle("Contrasting outline", isOn: model.preference(\.outline))
                Toggle("Soft shadow", isOn: model.preference(\.shadow))
            }
            Divider()
            StudioSection("Behaviour") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display mode").studioFont(.callout, weight: .medium).accessibilityHidden(true)
                    Picker("Display mode", selection: model.preference(\.keepNative)) {
                        Text("Companion").tag(true)
                        Text("Replace in Pokelet Studio").tag(false)
                    }
                    .labelsHidden()
                    .disabled(model.prefs.clickOnly)
                    StudioNote(displayDescription)
                }
                Toggle("Animate on click", isOn: model.preference(\.animate))
                Toggle("Play click sounds", isOn: model.preference(\.soundEnabled))
            }
        }
        .padding(16)
        .studioSurface()
    }

    private var size: Binding<Double> {
        Binding(get: { model.prefs.size }, set: { model.update(\.size, $0.rounded()) })
    }

    private var displayDescription: String {
        if model.prefs.clickOnly { return "Click-only mode keeps the Mac pointer visible." }
        return model.prefs.keepNative ? "The character sits beside the Mac pointer." :
            "Replaces the pointer inside this window. In other apps it stays beside the Mac pointer."
    }
}

private struct CharacterPicker: View {
    @Binding var selection: PointerStyle
    let compact: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        StudioSection("Characters") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: compact ? 2 : 4),
                      spacing: 7) {
                ForEach(PointerStyle.allCases) { style in
                    let selected = selection == style
                    Button { selection = style } label: {
                        VStack(spacing: 1) {
                            CharacterThumbnail(style: style)
                                .frame(height: 55)
                                .scaleEffect(selected && !reduceMotion ? 1.09 : 1)
                            Text(style.title)
                                .studioFont(.caption, weight: selected ? .semibold : .medium)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 7)
                        .foregroundStyle(selected ? StudioTheme.accent : StudioTheme.secondary)
                        .background(selected ? StudioTheme.selection : StudioTheme.surface,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(StudioTheme.accent)
                                    .padding(6)
                                    .accessibilityHidden(true)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selected ? StudioTheme.accent : StudioTheme.line)
                                .allowsHitTesting(false)
                        }
                    }
                    .buttonStyle(StudioButtonStyle(radius: 12))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("studio.character.\(style.rawValue)")
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.82), value: selection)
        }
    }
}

private struct PalettePicker: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Colour")
                Spacer()
                Text(model.prefs.palette.title).foregroundStyle(StudioTheme.secondary)
            }
            .accessibilityHidden(true)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(maximum: 33), spacing: 2),
                                     count: Palette.allCases.count), spacing: 4) {
                ForEach(Palette.allCases) { palette in
                    let selected = model.prefs.palette == palette
                    Button { model.update(\.palette, palette) } label: {
                        swatch(palette)
                            .frame(width: 22, height: 22)
                            .padding(3)
                            .overlay {
                                if selected {
                                    Circle().strokeBorder(StudioTheme.accent, lineWidth: 1.5)
                                }
                            }
                    }
                    .buttonStyle(StudioButtonStyle(radius: 14))
                    .help(palette.title)
                    .accessibilityLabel("\(palette.title) colour")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("studio.colour.\(palette.rawValue)")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Pointer colour")
            if model.prefs.palette == .custom {
                ColorPicker("Custom colour", selection: customColour, supportsOpacity: false)
            }
        }
    }

    @ViewBuilder private func swatch(_ palette: Palette) -> some View {
        if palette == .custom {
            Image(systemName: "eyedropper")
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(StudioTheme.selection, in: Circle())
        } else {
            let inks = paletteInks(palette)
            Circle()
                .fill(LinearGradient(colors: [colour(inks.primary), colour(inks.secondary)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.18)))
        }
    }

    private func paletteInks(_ palette: Palette) -> PointerArt.Inks {
        var prefs = model.prefs
        prefs.palette = palette
        return PointerArt.inks(for: prefs)
    }

    private var customColour: Binding<Color> {
        Binding {
            colour(PointerArt.RGB(model.prefs.customColour ?? Preferences.defaultCustomColour))
        } set: { value in
            guard let rgb = NSColor(value).usingColorSpace(.sRGB) else { return }
            func byte(_ component: CGFloat) -> UInt32 { UInt32((min(1, max(0, component)) * 255).rounded()) }
            model.update(\.customColour, byte(rgb.redComponent) << 16 | byte(rgb.greenComponent) << 8 | byte(rgb.blueComponent))
        }
    }

    private func colour(_ rgb: PointerArt.RGB) -> Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}
