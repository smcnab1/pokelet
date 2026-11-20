import Foundation
import XCTest
@testable import PokeletCore

final class AudioTests: XCTestCase {
    func testValidAudioIsStoredLocallyAndInvalidReplacementPreservesIt() throws {
        try withFixtures { directory in
            let destination = directory.appendingPathComponent("library/Custom Click.audio")
            let service = SoundPlayer(customLocation: destination)
            let valid = directory.appendingPathComponent("valid.wav")
            let invalid = directory.appendingPathComponent("invalid.wav")
            let bytes = wav(seconds: 1)
            try bytes.write(to: valid)
            try Data("not audio".utf8).write(to: invalid)

            try service.importSound(from: valid)
            XCTAssertEqual(try Data(contentsOf: destination), bytes)
            XCTAssertThrowsError(try service.importSound(from: invalid))
            XCTAssertEqual(try Data(contentsOf: destination), bytes)
            try service.removeCustomSound()
            try service.removeCustomSound()
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
    }

    func testImportRejectsDurationSizeAndNonRegularFiles() throws {
        try withFixtures { directory in
            let destination = directory.appendingPathComponent("Custom Click.audio")
            let service = SoundPlayer(customLocation: destination)
            let long = directory.appendingPathComponent("long.wav")
            let large = directory.appendingPathComponent("large.wav")
            try wav(seconds: 4).write(to: long)
            try Data(count: 5_000_001).write(to: large)
            for url in [long, large, directory, directory.appendingPathComponent("missing.wav")] {
                XCTAssertThrowsError(try service.importSound(from: url), url.lastPathComponent)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
    }

    private func withFixtures(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    private func wav(seconds: Int) -> Data {
        let rate = 8_000
        let bytes = rate * seconds * 2
        var result = Data()
        func header(_ text: String) { result.append(contentsOf: text.utf8) }
        func append<T: FixedWidthInteger>(_ number: T) {
            var little = number.littleEndian
            withUnsafeBytes(of: &little) { result.append(contentsOf: $0) }
        }
        header("RIFF")
        append(UInt32(bytes + 36))
        header("WAVEfmt ")
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(UInt32(rate))
        append(UInt32(rate * 2))
        append(UInt16(2))
        append(UInt16(16))
        header("data")
        append(UInt32(bytes))
        result.append(Data(count: bytes))
        return result
    }
}
