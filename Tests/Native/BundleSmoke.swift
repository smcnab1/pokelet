// Command-line bundle inspection only. No NSApplication, playback or event tap.
import AVFoundation
import Foundation

@main
enum BundleSmoke {
    static func main() throws {
        let app = URL(fileURLWithPath: CommandLine.arguments[1])
        let resources = app.appendingPathComponent("Contents/Resources")
        for sound in ["tap", "pop", "wood", "squeak"] {
            let url = resources.appendingPathComponent(sound + ".wav")
            let file = try AVAudioFile(forReading: url)
            guard file.length > 0, file.length < 3 * Int64(file.processingFormat.sampleRate),
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                frameCapacity: AVAudioFrameCount(file.length)) else {
                throw CheckError.badAudio(sound)
            }
            try file.read(into: buffer)
            guard Int64(buffer.frameLength) == file.length else { throw CheckError.badAudio(sound) }
        }
        guard FileManager.default.fileExists(atPath: resources.appendingPathComponent("AppIcon.icns").path) else {
            throw CheckError.missingIcon
        }
        print("Bundle audio decoded and app icon present.")

        let changelog = try String(contentsOf: resources.appendingPathComponent("CHANGELOG.md"), encoding: .utf8)
        guard let bundle = Bundle(url: app), let note = ReleaseNote.parse(changelog).first,
              bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == note.version,
              bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String == String(note.build) else {
            throw CheckError.missingCurrentReleaseNotes
        }
        print("Bundled release notes match \(note.tag), build \(note.build).")
    }

    enum CheckError: Error { case badAudio(String), missingIcon, missingCurrentReleaseNotes }
}
