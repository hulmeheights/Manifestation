//
//  Backup.swift
//  Moonwrit
//
//  The whole practice is one local JSON file. That is deliberate — nothing
//  leaves the phone — but it means deleting the app takes every rep and every
//  piece of evidence with it, and there is no server to get it back from.
//
//  So: a plain export, written to a file you can put in iCloud Drive, send to
//  yourself, or keep anywhere. And an import that reads one back.
//

import Foundation

enum Backup {

    /// Writes the current practice out and returns the file to share.
    static func export(_ state: ManifestState) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(state) else { return nil }

        let stamp = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Moonwrit-\(stamp).json")

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Reads one back. Returns nil rather than throwing, because the only
    /// sensible response to a bad file is to say so and change nothing.
    static func load(from url: URL) -> ManifestState? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ManifestState.self, from: data)
    }
}
