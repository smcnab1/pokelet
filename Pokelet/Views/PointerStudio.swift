import SwiftUI

struct PointerStudio: View {
    @ObservedObject var model: AppModel
    let wide: Bool
    let windowHeight: CGFloat
    @Environment(\.studioLargerText) private var largerText

    var body: some View {
        VStack(alignment: .leading, spacing: wide ? 15 : 11) {
            StudioHeading("Your pointer")
            StudioColumns(wide: wide) {
                VStack(alignment: .leading, spacing: wide ? 14 : 9) {
                    CharacterPreview(prefs: model.prefs, stageHeight: stageHeight)
                    if !wide {
                        presenterSettings
                            .padding(12)
                            .background(StudioTheme.surface.opacity(0.57), in: RoundedRectangle(cornerRadius: 12))
                    }
                    CharacterPicker(selection: model.preference(\.style))
                        .disabled(model.prefs.presenterEffects.normal)
                }
                .frame(maxWidth: .infinity)
                inspector
                    .frame(width: wide ? 278 : nil)
            }
        }
    }

    private var stageHeight: CGFloat {
        if wide { return max(260, windowHeight - 236) }
        let offset: CGFloat = largerText ? 295 : 283
        return max(145, min(294, windowHeight - offset))
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 18) {
            if wide {
                presenterSettings
                Divider()
            }
            StudioSection("Appearance") {
                if !model.prefs.presenterEffects.normal { PalettePicker(model: model) }
                StudioSlider(title: "Size", accessibilityTitle: "Pointer size",
                             displayValue: "\(Int(model.prefs.size)) pt",
                             spokenValue: "\(Int(model.prefs.size)) points",
                             range: Preferences.sizeRange, value: size)
                    .accessibilityIdentifier("studio.pointer.size")
                if !model.prefs.presenterEffects.normal {
                    StudioSwitch("Contrasting outline", isOn: model.preference(\.outline))
                }
                StudioSwitch("Soft shadow", isOn: model.preference(\.shadow))
            }
            Divider()
            StudioSection("Behaviour") {
                VStack(alignment: .leading, spacing: 6) {
                    if !model.prefs.presenterEffects.normal {
                        Picker("Display mode", selection: model.preference(\.keepNative)) {
                            Text("Companion").tag(true)
                            Text("Replace in Studio").tag(false)
                        }
                        .disabled(model.prefs.clickOnly)
                    }
                    StudioNote(displayDescription)
                }
                StudioSwitch("Animate on click", isOn: model.preference(\.animate))
                StudioSwitch("Play click sounds", isOn: model.preference(\.soundEnabled))
            }
        }
        .padding(15)
        .background(StudioTheme.surface.opacity(0.57), in: RoundedRectangle(cornerRadius: 16))
    }

    private var presenterSettings: some View {
        StudioSection("Presenter effects") {
            StudioSwitch("Enable Presenter Arm", isOn: model.preference(\.presenterEffects.normal))
            StudioNote("A pointing glove extends from the bottom edge. Try it with the pointer off.")
        }
    }

    private var size: Binding<Double> {
        Binding(get: { model.prefs.size }, set: { model.update(\.size, $0.rounded()) })
    }

    private var displayDescription: String {
        if model.prefs.presenterEffects.normal { return "Presenter Arm keeps the Mac pointer visible." }
        if model.prefs.clickOnly { return "Click-only mode keeps the Mac pointer visible." }
        return model.prefs.keepNative ? "The character sits beside the Mac pointer." :
            "Replaces the pointer inside this window. In other apps it stays beside the Mac pointer."
    }
}

private struct CharacterPicker: View {
    @Binding var selection: PointerStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        StudioSection("Characters") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4),
                      spacing: 3) {
                ForEach(PointerStyle.allCases) { style in
                    let selected = selection == style
                    Button { selection = style } label: {
                        VStack(spacing: 1) {
                            CharacterThumbnail(style: style)
                                .frame(height: 46)
                                .scaleEffect(selected && !reduceMotion ? 1.09 : 1)
                            Text(style.title)
                                .studioFont(.caption, weight: selected ? .semibold : .medium)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 5)
                        .foregroundStyle(selected ? StudioTheme.accent : StudioTheme.secondary)
                        .background(selected ? StudioTheme.selection : .clear,
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
                    }
                    .buttonStyle(StudioButtonStyle(radius: 12))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("studio.character.\(style.rawValue)")
                }
            }
            .padding(4)
            .background(StudioTheme.surface.opacity(0.66), in: RoundedRectangle(cornerRadius: 15))
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(maximum: 32), spacing: 1),
                                     count: Palette.allCases.count), spacing: 4) {
                ForEach(Palette.allCases) { palette in
                    let selected = model.prefs.palette == palette
                    Button { model.update(\.palette, palette) } label: {
                        swatch(palette)
                            .frame(width: 21, height: 21)
                            .padding(4)
                            .overlay {
                                if selected {
                                    Circle().strokeBorder(StudioTheme.accent, lineWidth: 1.5)
                                } else {
                                    Circle().strokeBorder(StudioTheme.line)
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
                .fill(colour(inks.primary))
                .overlay(alignment: .bottomTrailing) {
                    Circle().fill(colour(inks.secondary))
                        .frame(width: 9, height: 9)
                        .padding(2)
                }
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.15)))
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
