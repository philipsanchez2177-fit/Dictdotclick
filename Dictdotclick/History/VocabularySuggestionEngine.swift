//
//  VocabularySuggestionEngine.swift
//  Dictdotclick
//
//  Phase 9 — turning history into candidate vocabulary words.
//
//  Decision 4 requires every suggestion to be user-approved, never learned
//  silently, so this file's only job is to propose — VocabularySuggestionStore
//  is what remembers approvals and dismissals.
//
//  The heuristic: a capitalized word, not the first word of its sentence,
//  recurring across at least two *separate* dictations. Each part rules out
//  a specific false positive:
//
//    • Not the first word of its sentence — Whisper capitalizes every
//      sentence start regardless of whether the word is a proper noun, so
//      that position carries no signal at all.
//    • Recurring across entries, not just repeated in one — a name said
//      three times in one dictation and never again is still one data
//      point; the same word showing up in two unrelated dictations is what
//      makes it look like a real recurring word rather than a one-off
//      mishearing or a phrase that happened to repeat.
//
//  Pure function of its inputs, no disk access, no shared state — easy to
//  reason about even without a Swift toolchain to run it against.
//

import Foundation

enum VocabularySuggestionEngine {
    /// Below this, a word is one data point, not a pattern.
    private static let minimumOccurrences = 2

    static func suggestions(
        from entries: [TranscriptEntry],
        known: [String],
        dismissed: Set<String>
    ) -> [String] {
        let knownLowercased = Set(known.map { $0.lowercased() })

        // Keyed case-insensitively so "Dallas" in one dictation and "dallas"
        // in another count as the same candidate; the first spelling seen
        // is what gets displayed and, if approved, added.
        var display: [String: String] = [:]
        var entryCounts: [String: Int] = [:]

        for entry in entries {
            // A Set per entry: repeating a word five times in one dictation
            // must count as one occurrence, or a single ramble would look
            // like a recurring pattern on its own.
            let candidates = Set(candidateWords(in: entry.heardText))
            for word in candidates {
                let key = word.lowercased()
                guard !knownLowercased.contains(key), !dismissed.contains(key) else { continue }
                entryCounts[key, default: 0] += 1
                if display[key] == nil { display[key] = word }
            }
        }

        return entryCounts
            .filter { $0.value >= minimumOccurrences }
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .compactMap { display[$0.key] }
    }

    /// Capitalized, alphabetic, mid-sentence tokens. Deliberately narrow: an
    /// all-caps acronym or an internally-capitalized word like "McDonald"
    /// is skipped rather than guessed at, because a wrong suggestion costs
    /// Philip a click to dismiss and a right one saves nothing he'd notice —
    /// the asymmetry favors staying conservative.
    private static func candidateWords(in text: String) -> [String] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        var candidates: [String] = []

        for sentence in sentences {
            let words = sentence
                .split(separator: " ")
                .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }

            for (index, word) in words.enumerated() where index > 0 {
                guard word.count >= 2,
                      let first = word.first,
                      first.isUppercase,
                      word.dropFirst().allSatisfy(\.isLowercase)
                else { continue }
                candidates.append(word)
            }
        }
        return candidates
    }
}
