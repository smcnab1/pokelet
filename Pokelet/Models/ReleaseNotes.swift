import Foundation

struct ReleaseNote: Identifiable {
    struct Section: Identifiable {
        let title: String
        var items: [String] = []

        var id: String { title }
    }

    let tag: String
    let date: String
    let build: Int
    let title: String
    let sections: [Section]

    var id: String { tag }
    var version: String { tag.dropFirst().split(separator: "-", maxSplits: 1)[0].description }
    var isPrerelease: Bool { tag.contains("-") }

    var notesMarkdown: String {
        sections.map { section in
            "### \(section.title)\n\n" + section.items.map { "- \($0)\n" }.joined()
        }.joined(separator: "\n")
    }

    static func parse(_ changelog: String) -> [Self] {
        changelog.components(separatedBy: "\n## ").dropFirst().compactMap { entry in
            var lines = entry.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
            guard lines.count >= 4 else { return nil }
            let heading = lines.removeFirst().components(separatedBy: "] - ")
            guard heading.count == 2, heading[0].hasPrefix("[") else { return nil }
            let tag = String(heading[0].dropFirst())
            let date = heading[1]
            let buildLine = lines.removeFirst()
            let titleLine = lines.removeFirst()
            guard tag.range(of: #"^v[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$"#,
                            options: .regularExpression) != nil,
                  date.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"#, options: .regularExpression) != nil,
                  buildLine.hasPrefix("Build: "), let build = Int(buildLine.dropFirst("Build: ".count)), build > 0,
                  titleLine.hasPrefix("Title: "), titleLine.count > "Title: ".count else { return nil }

            var sections: [Section] = []
            for line in lines {
                if line.hasPrefix("### ") {
                    sections.append(Section(title: String(line.dropFirst(4))))
                } else if line.hasPrefix("- "), let index = sections.indices.last {
                    sections[index].items.append(String(line.dropFirst(2)))
                }
            }
            sections.removeAll { $0.items.isEmpty }
            guard !sections.isEmpty else { return nil }
            return Self(tag: tag, date: date, build: build, title: String(titleLine.dropFirst("Title: ".count)),
                        sections: sections)
        }
    }
}

struct ReleaseHistory {
    private static let lastSeenBuild = "PokeletLastSeenReleaseBuild"
    let defaults: UserDefaults

    func shouldOffer(build: Int, hasNotes: Bool, hasLegacyPreferences: Bool = false) -> Bool {
        guard build > 0 else { return false }
        let seen = defaults.integer(forKey: Self.lastSeenBuild)
        if seen == 0, !hasLegacyPreferences { markSeen(build: build) }
        return hasNotes && (seen > 0 || hasLegacyPreferences) && build > seen
    }

    func markSeen(build: Int) {
        // A temporary downgrade must not cause a second offer on return.
        if build > defaults.integer(forKey: Self.lastSeenBuild) {
            defaults.set(build, forKey: Self.lastSeenBuild)
        }
    }
}
