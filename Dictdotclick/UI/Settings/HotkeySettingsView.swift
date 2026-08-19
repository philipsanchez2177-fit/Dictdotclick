//
//  HotkeySettingsView.swift
//  Dictdotclick
//
//  Phase 1 — skeleton. Phase 3 replaces this with the hotkey recorder that
//  enforces decision 6: no bare character keys, modifier combos and F1–F20
//  only, with conflict detection against system shortcuts.
//

import SwiftUI

struct HotkeySettingsView: View {
    var body: some View {
        PhasePlaceholder(
            icon: "command",
            headline: "Dictation hotkey",
            detail: "Press once to start dictating, press again to stop. Any modifier combination or function key.",
            arrivesInPhase: 3
        )
    }
}
