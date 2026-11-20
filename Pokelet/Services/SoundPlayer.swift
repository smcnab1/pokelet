import AVFoundation
import Foundation

final class SoundPlayer {
    private static let maximumBytes = 5_000_000
    private var voices: [AVAudioPlayer] = []
    private var nextVoice = 0
    private var preview: AVAudioPlayer?
    private var previewCleanup: DispatchWorkItem?
    private let customLocation: URL?
    private let supportDirectory: String
    private let fileManager = FileManager.default

    init(customLocation: URL? = nil, supportDirectory: String = "Pokelet") {
        self.customLocation = customLocation
        self.supportDirectory = supportDirectory
    }

    func prepare(_ sound: ClickSound) throws {
        stop()
        guard sound != .silent else { return }
        let makePlayer = try playerFactory(for: sound)
        let pool = try (0..<3).map { _ in try makePlayer() }
        guard pool.allSatisfy({ $0.prepareToPlay() }) else { throw AudioError.output }
        voices = pool
    }

    func play(volume: Double) -> Bool {
        guard !voices.isEmpty, volume > 0 else { return false }
        let index = voices.firstIndex(where: { !$0.isPlaying }) ?? nextVoice
        let player = voices[index]
        nextVoice = (index + 1) % voices.count
        return play(player, volume: volume)
    }

    func preview(_ sound: ClickSound, volume: Double) throws {
        stopPreview()
        let makePlayer = try playerFactory(for: sound)
        let player = try makePlayer()
        guard play(player, volume: volume) else { throw AudioError.output }
        preview = player
        let cleanup = DispatchWorkItem { [weak self] in self?.stopPreview() }
        previewCleanup = cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.15, execute: cleanup)
    }

    func stop() {
        voices.forEach { $0.stop() }
        voices.removeAll()
        nextVoice = 0
    }

    func stopPreview() {
        previewCleanup?.cancel()
        previewCleanup = nil
        preview?.stop()
        preview = nil
    }

    func importSound(from source: URL) throws {
        let attributes = try source.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard attributes.isRegularFile == true, let size = attributes.fileSize,
              (1...Self.maximumBytes).contains(size) else { throw AudioError.limit }
        let handle = try FileHandle(forReadingFrom: source)
        defer { try? handle.close() }
        guard let data = try handle.read(upToCount: Self.maximumBytes + 1),
              (1...Self.maximumBytes).contains(data.count) else { throw AudioError.limit }

        let imported: AVAudioPlayer
        do { imported = try AVAudioPlayer(data: data) }
        catch { throw AudioError.unreadable }
        guard imported.duration.isFinite, imported.duration > 0, imported.duration <= 3 else { throw AudioError.limit }

        let url = try customURL()
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func removeCustomSound() throws {
        let url = try customURL()
        if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
    }

    private func play(_ player: AVAudioPlayer, volume: Double) -> Bool {
        player.currentTime = 0
        player.volume = Float(volume)
        return player.play()
    }

    private func playerFactory(for sound: ClickSound) throws -> () throws -> AVAudioPlayer {
        if sound == .custom {
            let url = try customURL()
            guard fileManager.fileExists(atPath: url.path) else { throw AudioError.missing }
            let data = try Data(contentsOf: url)
            return { try AVAudioPlayer(data: data) }
        }
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            throw AudioError.missing
        }
        return { try AVAudioPlayer(contentsOf: url) }
    }

    private func customURL() throws -> URL {
        if let customLocation { return customLocation }
        return try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                   appropriateFor: nil, create: false)
            .appendingPathComponent(supportDirectory, isDirectory: true)
            .appendingPathComponent("Custom Click.audio")
    }

    private enum AudioError: LocalizedError {
        case missing, limit, unreadable, output
        var errorDescription: String? {
            switch self {
            case .missing: "The selected click sound is missing. Choose another sound or import it again."
            case .output: "macOS could not play the selected sound. Check the audio output and try again."
            case .unreadable: "macOS could not read this audio file."
            case .limit: "Choose an audio file no larger than 5 MB and no longer than 3 seconds."
            }
        }
    }
}
