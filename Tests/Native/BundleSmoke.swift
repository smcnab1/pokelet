// Command-line bundle inspection only. No NSApplication, playback or event tap.
import AVFoundation
import Foundation

@main
enum BundleSmoke {
    static func main() throws {
        let resources = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("Contents/Resources")
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
    }

    enum CheckError: Error { case badAudio(String), missingIcon }
}
