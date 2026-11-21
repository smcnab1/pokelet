import SwiftUI

struct SoundSettings: View {
    @ObservedObject var model: AppModel
    let wide: Bool

    private var choices: [ClickSound] {
        ClickSound.allCases.filter { $0 != .custom || model.prefs.customSoundName != nil || model.prefs.sound == .custom }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Sounds", detail: "Choose what you hear when you click.")
            StudioColumns(wide: wide) {
                StudioSection("Click sound") {
                    VStack(spacing: 2) {
                        ForEach(choices) { sound in
                            soundChoice(sound)
                        }
                    }
                    .padding(4)
                    .background(StudioTheme.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
                }
                VStack(alignment: .leading, spacing: 17) {
                    StudioSection("Playback") {
                        StudioSwitch("Play click sounds", isOn: model.preference(\.soundEnabled))
                        Picker("Play on", selection: model.preference(\.soundTrigger)) {
                            ForEach(SoundTrigger.allCases) { trigger in
                                Text(trigger.title).tag(trigger)
                            }
                        }
                        if model.prefs.soundTrigger == .interactiveOnly {
                            StudioNote(model.clickSoundAccessibility
                                ? "Sounds play for controls that apps expose to macOS Accessibility."
                                : "Accessibility access is unavailable. Sounds play on every click.")
                        }
                        let volume = Int((model.prefs.volume * 100).rounded())
                        StudioSlider(title: "Volume", accessibilityTitle: "Click sound volume",
                                     displayValue: "\(volume)%", spokenValue: "\(volume) percent",
                                     range: 0...1, value: model.preference(\.volume))
                            .accessibilityIdentifier("studio.sound.volume")
                        Button { model.previewSound() } label: {
                            StudioLabel("Preview sound", symbol: "play.fill")
                        }
                        .disabled(model.prefs.sound == .silent || model.prefs.volume == 0)
                        .help("Play the selected sound once")
                    }
                    Divider()
                    StudioSection("Custom audio") {
                        Text(model.prefs.customSoundName ?? "No file imported")
                            .foregroundStyle(StudioTheme.secondary)
                            .textSelection(.enabled)
                        Button("Import Audio…") { model.chooseCustomSound() }
                        StudioNote("Choose a file up to 3 seconds and 5 MB. Pokelet keeps a local copy.")
                    }
                }
                .frame(width: wide ? 302 : nil, alignment: .leading)
            }
            if let issue = model.audioMessage {
                StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
            }
        }
        .onAppear { model.refreshClickSoundAccessibility() }
    }

    private func soundChoice(_ sound: ClickSound) -> some View {
        let selected = model.prefs.sound == sound
        return Button {
            model.update(\.sound, sound)
        } label: {
            HStack(spacing: 10) {
                StudioLeadingIcon(symbol: sound == .silent ? "speaker.slash" : sound == .custom ? "music.note" : "waveform")
                    .foregroundStyle(selected ? StudioTheme.accent : StudioTheme.secondary)
                Text(sound.title)
                    .studioFont(.body, weight: selected ? .semibold : .regular)
                Spacer(minLength: 4)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(StudioTheme.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
            .background(selected ? StudioTheme.selection : .clear, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(StudioButtonStyle(radius: 9))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("studio.sound.\(sound.rawValue)")
    }
}
