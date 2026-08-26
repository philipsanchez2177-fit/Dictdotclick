//
//  DictionaryModel.swift
//  Dictdotclick
//
//  Phase 7 — what the dictionary *is*.
//
//  Two entry types that look similar in the UI and work nothing alike:
//
//    • A VocabularyEntry is handed to the speech engine *before* it listens,
//      biasing it toward a word it would otherwise mishear.
//    • A Snippet is a find-and-replace run on the finished transcript.
//
//  The order matters and explains a rule enforced in DictionaryStore: a
//  snippet's trigger is also registered as a vocabulary hint. If the engine
//  hears "my address" as "my dress", no amount of find-and-replace can
//  recover it — the replacement never gets a chance to match.
//
//  Pure data, no UI and no disk access, so the rules can be reasoned about on
//  their own.
//

import Foundation

/// A word or name the engine should be biased toward hearing.
struct VocabularyEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var phrase: String = ""

    var isUsable: Bool { !phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// A spoken phrase and the text it expands into.
///
/// `expansion` is deliberately free-form and may contain newlines — a postal
/// address is the obvious case. It may also contain personal data, which is
/// why this file's storage never leaves the Mac (BUILD-SPEC privacy posture).
struct Snippet: Codable, Identifiable, Hashable {
    var id = UUID()
    var trigger: String = ""
    var expansion: String = ""

    var isUsable: Bool {
        !trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !expansion.isEmpty
    }
}

/// The whole dictionary as it sits on disk. A single struct rather than two
/// files, so a save can never leave vocabulary and snippets out of step.
struct DictionaryData: Codable {
    var vocabulary: [VocabularyEntry] = []
    var snippets: [Snippet] = []
}
