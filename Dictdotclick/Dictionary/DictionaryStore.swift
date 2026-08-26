//
//  DictionaryStore.swift
//  Dictdotclick
//
//  Phase 7 — the dictionary in memory, and on disk.
//
//  One shared instance, like DictationController: the Settings pane edits it
//  and the transcription path reads it, and there must only ever be one
//  answer to "what words does this app know".
//
//  Saves happen on every edit rather than on a Save button. The file is a few
//  kilobytes of JSON written atomically, so the cost is invisible, and the
//  alternative — an unsaved-changes state — is a way to lose a snippet by
//  closing a window.
//

import Foundation
import Observation

@Observable
final class DictionaryStore {
    static let shared = DictionaryStore()

    private static let filename = "dictionary.json"

    /// Words the engine should be biased toward. Editing writes to disk.
    var vocabulary: [VocabularyEntry] {
        didSet { save() }
    }

    /// Spoken phrases swapped for stored text after transcription.
    var snippets: [Snippet] {
        didSet { save() }
    }

    private init() {
        let data = JSONStore.load(DictionaryData.self, from: Self.filename) ?? DictionaryData()
        // Assigned directly so loading cannot trigger didSet and write the
        // file straight back — the same trick DictationController uses.
        vocabulary = data.vocabulary
        snippets = data.snippets
    }

    // MARK: - What the engine gets

    /// Everything passed to the transcriber as a vocabulary hint: the
    /// vocabulary list *plus every snippet trigger*.
    ///
    /// Including the triggers is not a convenience. A snippet only fires if
    /// the trigger phrase survives transcription intact, so a trigger the
    /// engine has never been told about is a snippet that silently never
    /// works. Registering it here means adding a snippet is one action for
    /// the user, not two.
    var hints: [String] {
        let words = vocabulary.map(\.phrase) + snippets.map(\.trigger)
        var seen = Set<String>()
        var result: [String] = []
        for word in words {
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            // Deduplicated case-insensitively; the engine gains nothing from
            // being told the same word twice.
            guard seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    /// Snippets worth running. A half-typed row in the editor is not one.
    var usableSnippets: [Snippet] { snippets.filter(\.isUsable) }

    // MARK: - Editing

    func addVocabulary(_ phrase: String = "") {
        vocabulary.append(VocabularyEntry(phrase: phrase))
    }

    func addSnippet() {
        snippets.append(Snippet())
    }

    func remove(vocabularyID id: VocabularyEntry.ID) {
        vocabulary.removeAll { $0.id == id }
    }

    func remove(snippetID id: Snippet.ID) {
        snippets.removeAll { $0.id == id }
    }

    /// Triggers that appear more than once, so the UI can flag them. Two
    /// snippets with the same trigger is not an error — the first one simply
    /// always wins — but it is always a mistake.
    var duplicateTriggers: Set<String> {
        var counts: [String: Int] = [:]
        for snippet in snippets {
            let key = snippet.trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty else { continue }
            counts[key, default: 0] += 1
        }
        return Set(counts.filter { $0.value > 1 }.keys)
    }

    // MARK: - Persistence

    private func save() {
        JSONStore.save(DictionaryData(vocabulary: vocabulary, snippets: snippets),
                       to: Self.filename)
    }

    /// Where the file lives, for the "stored on this Mac" line in the UI.
    static var fileURL: URL { JSONStore.url(for: filename) }
}
