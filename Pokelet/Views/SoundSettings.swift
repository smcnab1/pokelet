import SwiftUI

struct SoundSettings: View {
    @ObservedObject var model: AppModel

    private var choices: [ClickSound] {
        ClickSound.allCases.filter { $0 != .custom || model.prefs.customSoundName != nil || model.prefs.sound == .custom }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            StudioHeading("Sounds", detail: "Choose what you hear when you click.")
            VStack(spacing: 0) {
                HStack {
                    Label("Play click sounds", systemImage: model.prefs.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                        .studioFont(.headline)
                        .accessibilityHidden(true)
                    Spacer()
                    Toggle("Play click sounds", isOn: model.preference(\.soundEnabled))
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                .padding(14)
                Divider()
                VStack(spacing: 4) {
                    ForEach(choices) { sound in
                        soundChoice(sound)
                    }
                }
                .padding(6)
                Divider()
                HStack(spacing: 12) {
                    Text("Volume").accessibilityHidden(true)
                    Slider(value: model.preference(\.volume), in: 0...1) { Text("Click sound volume") }
                        .labelsHidden()
                        .accessibilityIdentifier("studio.sound.volume")
                        .accessibilityValue("\(Int(model.prefs.volume * 100)) percent")
                    Text("\(Int(model.prefs.volume * 100))%")
                        .monospacedDigit()
                        .foregroundStyle(StudioTheme.secondary)
                        .accessibilityHidden(true)
                    Button { model.previewSound() } label: {
                        Label("Preview sound", systemImage: "play.fill")
                    }
                    .disabled(model.prefs.sound == .silent || model.prefs.volume == 0)
                    .help("Play the selected sound once")
                }
                .padding(14)
            }
            .studioSurface()

            StudioSection("Custom audio") {
                LabeledContent("Imported file") {
                    Text(model.prefs.customSoundName ?? "No file imported")
                        .foregroundStyle(StudioTheme.secondary)
                        .textSelection(.enabled)
                }
                Button("Import Audio…") { model.chooseCustomSound() }
                StudioNote("Choose a file up to 3 seconds and 5 MB. Pokelet keeps a local copy.", symbol: "waveform")
            }
            if let issue = model.audioMessage {
                StudioNote(issue, symbol: "exclamationmark.circle", warning: true)
            }
        }
    }

    private func soundChoice(_ sound: ClickSound) -> some View {
        let selected = model.prefs.sound == sound
        return Button {
            model.update(\.sound, sound)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: sound == .silent ? "speaker.slash" : sound == .custom ? "music.note" : "waveform")
                    .frame(width: 22)
                    .foregroundStyle(selected ? StudioTheme.accent : StudioTheme.secondary)
                    .accessibilityHidden(true)
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
            .padding(.vertical, 7)
            .background(selected ? StudioTheme.selection : .clear, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(StudioButtonStyle(radius: 9))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("studio.sound.\(sound.rawValue)")
    }
}
