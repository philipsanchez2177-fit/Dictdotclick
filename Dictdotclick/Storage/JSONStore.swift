//
//  JSONStore.swift
//  Dictdotclick
//
//  Phase 3 — saving small amounts of app state to disk.
//
//  Everything this app remembers lives in
//  ~/Library/Application Support/Dictdotclick/ as plain JSON. That location is
//  the macOS convention for app data the user does not open directly, and JSON
//  keeps it readable and hand-fixable — which matters for a file that will
//  later hold snippets containing personal data (BUILD-SPEC privacy posture).
//
//  Deliberately not a database. The largest thing this will ever store is a
//  dictionary of a few hundred words.
//

import Foundation

enum JSONStore {
    /// ~/Library/Application Support/Dictdotclick/, created on first use.
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Dictdotclick", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    /// Reads and decodes, returning nil for "no file yet" as well as for a
    /// file that will not parse. A corrupt settings file should leave the app
    /// running on defaults, not refuse to launch.
    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: filename)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Writes atomically, so an interrupted save cannot leave a half-written
    /// file behind.
    @discardableResult
    static func save<T: Encodable>(_ value: T, to filename: String) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return false }
        do {
            try data.write(to: url(for: filename), options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
