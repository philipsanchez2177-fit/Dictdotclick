//
//  TranscriptHistoryStore.swift
//  Dictdotclick
//
//  Phase 9 — every finished dictation, kept on this Mac only.
//
//  Same shape as DictionaryStore: one shared instance, saves on every
//  change, loaded once at init without triggering its own didSet (assigned
//  directly rather than through the property's setter).
//
//  DictationController appends here after a dictation is delivered — never
//  for a recording that produced no text, since an empty entry would only
//  be noise in the list and would feed the suggestion engine nothing useful.
//

import Foundation
import Observation

@Observable
final class TranscriptHistoryStore {
    static let shared = TranscriptHistoryStore()

    private static let filename = "history.json"

    /// Oldest entries drop off past this count. A dictation every few
    /// minutes all day is still a small file; this is a ceiling against
    /// unbounded growth over months of use, not a target to hit.
    static let maxEntries = 500

    /// Newest first — the order the Settings pane shows them in.
    private(set) var entries: [TranscriptEntry] {
        didSet { save() }
    }

    private init() {
        entries = JSONStore.load([TranscriptEntry].self, from: Self.filename) ?? []
    }

    func add(heardText: String, deliveredText: String) {
        entries.insert(TranscriptEntry(heardText: heardText, deliveredText: deliveredText), at: 0)
        if entries.count > Self.maxEntries {
            entries.removeLast(entries.count - Self.maxEntries)
        }
    }

    func remove(id: TranscriptEntry.ID) {
        entries.removeAll { $0.id == id }
    }

    func clear() {
        entries.removeAll()
    }

    private func save() {
        JSONStore.save(entries, to: Self.filename)
    }

    /// Where the file lives, for the "stored on this Mac" line in the UI.
    static var fileURL: URL { JSONStore.url(for: filename) }
}
