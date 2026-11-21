import SwiftUI

struct AnimationSettings: View {
    @ObservedObject var model: AppModel
    let wide: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduced: Bool { model.prefs.reducedMotion || systemReduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Animations", detail: "Set the click response and try it with your current character.")
            CharacterPreview(prefs: model.prefs, expanded: false, showsSecondaryClick: true)
            let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 22)) :
                AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
            layout {
                responseControls
                motionControls
                    .frame(width: wide ? 254 : nil, alignment: .leading)
            }
        }
    }

    private var responseControls: some View {
        StudioSection("Click response") {
            Toggle("Animate on click", isOn: model.preference(\.animate))
                .toggleStyle(.switch)
            VStack(alignment: .leading, spacing: 10) {
                intensityPicker
                Toggle("React to fast clicks", isOn: model.preference(\.reactive))
                Toggle("Comic impact effects", isOn: model.preference(\.effects))
                Toggle("Celebration sparkles", isOn: model.preference(\.celebration))
                    .disabled(!model.prefs.effects || reduced)
                StudioNote(responseNote)
            }
            .disabled(!model.prefs.animate)
        }
    }

    private var motionControls: some View {
        StudioSection("Motion and visibility") {
            Toggle("Click-only mode", isOn: model.preference(\.clickOnly))
            Toggle("Reduced Motion", isOn: model.preference(\.reducedMotion))
            StudioNote(systemReduceMotion ? "macOS Reduce Motion is on." :
                "Reduced Motion uses brief fades for click feedback.")
            Toggle("Wobble on sharp turns and stops", isOn: model.preference(\.directionBounce))
                .disabled(reduced)
        }
        .padding(14)
        .studioSurface()
    }

    private var intensityPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: Intensity.allCases.count),
                  spacing: 6) {
            ForEach(Intensity.allCases) { intensity in
                let selected = model.prefs.intensity == intensity
                Button {
                    model.update(\.intensity, intensity)
                } label: {
                    VStack(spacing: 7) {
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(0..<5, id: \.self) { level in
                                Capsule()
                                    .fill(level <= intensity.rawValue ? StudioTheme.accent : StudioTheme.line)
                                    .frame(width: 4, height: CGFloat(5 + level * 3))
                            }
                        }
                        .accessibilityHidden(true)
                        Text(intensity.title)
                            .studioFont(.caption, weight: selected ? .semibold : .medium)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selected ? StudioTheme.selection : StudioTheme.surface,
                                in: RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(StudioTheme.accent)
                                .padding(5)
                                .accessibilityHidden(true)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selected ? StudioTheme.accent : StudioTheme.line)
                            .allowsHitTesting(false)
                    }
                }
                .buttonStyle(StudioButtonStyle(radius: 10))
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("studio.intensity.\(intensity.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Click animation intensity")
    }

    private var responseNote: String {
        if !model.prefs.animate { return "The character stays still when you click." }
        if reduced { return "Click feedback uses a fading ring or a brief change in opacity." }
        if model.prefs.intensity == .barelyThere {
            return "Barely There moves the character gently without comic impact effects."
        }
        return model.prefs.reactive ? "Click in quick succession to build up the response." :
            "Each click uses the selected intensity."
    }
}
