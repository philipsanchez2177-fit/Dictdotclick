//
//  DictionarySettingsView.swift
//  Dictdotclick
//
//  Phase 1 — skeleton. Phase 7 builds the two-list editor: vocabulary hints
//  (fed to Whisper before transcription) and snippets (spoken phrases swapped
//  for stored text afterwards). Different mechanisms, different timing — see
//  BUILD-SPEC decision 4.
//

import SwiftUI

struct DictionarySettingsView: View {
    var body: some View {
        PhasePlaceholder(
            icon: "character.book.closed",
            headline: "Vocabulary and snippets",
            detail: "Teach Dictdotclick names and jargon it mishears, and expand spoken phrases into stored text.",
            arrivesInPhase: 7
        )
    }
}
