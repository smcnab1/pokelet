import AVFoundation
import Foundation

final class SoundPlayer {
    private var preparedSound: ClickSound?
    private var voices: [AVAudioPlayer] = []
    private var nextVoice = 0
    private let fileManager = FileManager.default

    func prepare(_ sound: ClickSound) throws {
        guard sound != preparedSound else { return }
        stop()
        guard sound != .silent else { return }
        guard let url = try url(for: sound) else { throw AudioError.missing }
        let customData = sound == .custom ? try Data(contentsOf: url) : nil
        let pool = try (0..<3).map { _ in
            if let customData { return try AVAudioPlayer(data: customData) }
            return try AVAudioPlayer(contentsOf: url)
        }
        guard pool.allSatisfy({ $0.prepareToPlay() }) else { throw AudioError.output }
        voices = pool
        preparedSound = sound
    }

    @discardableResult
    func play(volume: Double) -> Bool {
        guard !voices.isEmpty, volume > 0 else { return false }
        let index = voices.firstIndex(where: { !$0.isPlaying }) ?? nextVoice
        let player = voices[index]
        nextVoice = (index + 1) % voices.count
        player.currentTime = 0
        player.volume = Float(volume)
        return player.play()
    }

    func stop() {
        voices.forEach { $0.stop() }
        voices.removeAll()
        preparedSound = nil
        nextVoice = 0
    }

    func importSound(from source: URL) throws {
        let attributes = try source.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard attributes.isRegularFile == true, let size = attributes.fileSize,
              (1...5_000_000).contains(size) else { throw AudioError.limit }
        let data = try Data(contentsOf: source)
        guard (1...5_000_000).contains(data.count) else { throw AudioError.limit }
        let url = try customURL()
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let imported = try AVAudioPlayer(data: data)
        guard imported.duration.isFinite, imported.duration > 0, imported.duration <= 3,
              imported.prepareToPlay() else { throw AudioError.limit }
        try data.write(to: url, options: .atomic)
        stop()
    }

    func removeCustomSound() throws {
        let url = try customURL()
        if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
    }

    private func customURL() throws -> URL {
        try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                            appropriateFor: nil, create: false)
        .appendingPathComponent("Pokelet", isDirectory: true)
        .appendingPathComponent("Custom Click.audio")
    }

    private func url(for sound: ClickSound) throws -> URL? {
        if sound == .custom { return try customURL() }
        return Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
    }

    private enum AudioError: LocalizedError {
        case missing, limit, output
        var errorDescription: String? {
            switch self {
            case .missing: "The selected click sound is missing."
            case .output: "macOS could not prepare the selected sound for playback."
            case .limit: "Choose an audio file no larger than 5 MB and no longer than 3 seconds."
            }
        }
    }
}
