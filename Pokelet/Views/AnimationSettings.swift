import SwiftUI

struct AnimationSettings: View {
    @ObservedObject var model: AppModel
    let wide: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.studioLargerText) private var largerText

    private var reduced: Bool { model.prefs.reducedMotion || systemReduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Animations", detail: "Set the click response and try it with your current character.")
            StudioColumns(wide: wide) {
                CharacterPreview(prefs: model.prefs, stageHeight: wide ? 325 : 226,
                                 livePointer: model.mode.showsPointer, showsSecondaryClick: true)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 16) {
                    responseControls
                    Divider()
                    motionControls
                }
                .frame(width: wide ? 330 : nil, alignment: .leading)
            }
        }
    }

    private var responseControls: some View {
        StudioSection("Click response") {
            StudioSwitch("Animate on click", isOn: model.preference(\.animate))
            VStack(alignment: .leading, spacing: 10) {
                intensityPicker
                StudioSwitch("React to fast clicks", isOn: model.preference(\.reactive))
                StudioSwitch("Comic impact effects", isOn: model.preference(\.effects))
                StudioSwitch("Celebration sparkles", isOn: model.preference(\.celebration))
                    .disabled(!model.prefs.effects || reduced)
                StudioNote(responseNote)
            }
            .disabled(!model.prefs.animate)
        }
    }

    private var motionControls: some View {
        StudioSection("Motion and visibility") {
            StudioSwitch("Click-only mode", isOn: model.preference(\.clickOnly))
                .disabled(model.prefs.presenterEffects.normal)
            StudioSwitch("Reduced Motion", isOn: model.preference(\.reducedMotion))
            StudioNote(systemReduceMotion ? "macOS Reduce Motion is on." :
                "Reduced Motion uses brief fades for click feedback.")
            StudioSwitch("Wobble on sharp turns and stops", isOn: model.preference(\.directionBounce))
                .disabled(reduced || model.prefs.presenterEffects.normal)
        }
    }

    private var intensityPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: largerText ? 3 : Intensity.allCases.count),
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
                            .frame(minHeight: largerText ? 32 : 28, alignment: .top)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selected ? StudioTheme.selection : .clear,
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
                }
                .buttonStyle(StudioButtonStyle(radius: 10))
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("studio.intensity.\(intensity.rawValue)")
            }
        }
        .padding(4)
        .background(StudioTheme.surface.opacity(0.66), in: RoundedRectangle(cornerRadius: 12))
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
