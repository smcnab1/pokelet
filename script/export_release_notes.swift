import Foundation

@main
enum ExportReleaseNotes {
    static func main() throws {
        guard CommandLine.arguments.count == 4 else {
            fail("Usage: export_release_notes path/to/CHANGELOG.md TAG BUILD")
        }
        let changelog = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        let releases = ReleaseNote.parse(changelog)
        let publishedHeadings = changelog.split(whereSeparator: \.isNewline).filter { $0.hasPrefix("## [") }
        guard releases.count == publishedHeadings.count,
              Set(releases.map(\.tag)).count == releases.count,
              zip(releases, releases.dropFirst()).allSatisfy({ $0.build > $1.build }) else {
            fail("Check the changelog metadata, unique tags and strictly decreasing builds.")
        }
        guard let note = releases.first, note.tag == CommandLine.arguments[2],
              String(note.build) == CommandLine.arguments[3] else {
            fail("The newest changelog entry must match this release tag and build.")
        }
        let output = ["date": note.date, "markdown": note.notesMarkdown]
        FileHandle.standardOutput.write(try JSONEncoder().encode(output))
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(1)
    }
}
