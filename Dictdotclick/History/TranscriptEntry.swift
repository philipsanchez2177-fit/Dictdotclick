//
//  TranscriptEntry.swift
//  Dictdotclick
//
//  Phase 9 — one finished dictation, as kept in history.
//
//  Both texts are kept for the same reason DictationController keeps them
//  live (see lastHeardTranscript there): `heardText` is what the engine
//  actually heard, `deliveredText` is what went into the focused app after
//  snippets and filler cleanup ran. Keeping both is what lets the
//  suggestion engine read raw engine output without the dictionary's own
//  replacements feeding back into what it suggests adding to the dictionary.
//
//  Pure data, no disk access — TranscriptHistoryStore owns persistence.
//

import Foundation

struct TranscriptEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let heardText: String
    let deliveredText: String

    init(id: UUID = UUID(), date: Date = Date(), heardText: String, deliveredText: String) {
        self.id = id
        self.date = date
        self.heardText = heardText
        self.deliveredText = deliveredText
    }

    /// True when the dictionary changed something, so the history row can
    /// show the raw version only when there is something to compare.
    var wasProcessed: Bool { heardText != deliveredText }
}
