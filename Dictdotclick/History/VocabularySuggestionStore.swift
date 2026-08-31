//
//  VocabularySuggestionStore.swift
//  Dictdotclick
//
//  Phase 9 — the approve/dismiss half of decision 4's "user-approved
//  suggestions". VocabularySuggestionEngine proposes; this remembers what
//  Philip has already said no to, so a dismissed word doesn't keep coming
//  back every time it recurs in a new dictation.
//
//  Only "no" needs remembering here. "Yes" is remembered by DictionaryStore
//  itself — once a word is added, it shows up in DictionaryStore.hints and
//  the engine excludes it from suggestions on that basis, so there is no
//  separate "approved" list to keep in sync with the dictionary.
//

import Foundation
import Observation

@Observable
final class VocabularySuggestionStore {
    static let shared = VocabularySuggestionStore()

    private static let filename = "suggestion-dismissals.json"

    /// Lowercased words Philip has dismissed. Assigned directly in `init`,
    /// same reasoning as DictionaryStore: loading must not trigger `didSet`
    /// and write the file straight back.
    private var dismissed: Set<String> {
        didSet { save() }
    }

    private init() {
        dismissed = JSONStore.load(Set<String>.self, from: Self.filename) ?? []
    }

    /// Recomputed on every access rather than cached. Cheap at this scale —
    /// a few hundred history entries at most — and it means a fresh
    /// dictation or a dictionary edit made elsewhere is reflected the next
    /// time the Settings pane reads this, with nothing to invalidate.
    var suggestions: [String] {
        VocabularySuggestionEngine.suggestions(
            from: TranscriptHistoryStore.shared.entries,
            known: DictionaryStore.shared.hints,
            dismissed: dismissed
        )
    }

    /// Adds the word to the dictionary. Nothing to record here beyond that —
    /// see the type-level comment on why approval needs no state of its own.
    func approve(_ word: String) {
        DictionaryStore.shared.addVocabulary(word)
    }

    func dismiss(_ word: String) {
        dismissed.insert(word.lowercased())
    }

    private func save() {
        JSONStore.save(dismissed, to: Self.filename)
    }
}
