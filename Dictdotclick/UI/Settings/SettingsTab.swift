//
//  SettingsTab.swift
//  Dictdotclick
//
//  Phase 1 — the list of sections in the Settings window sidebar.
//
//  Kept as an enum (a fixed list of named options) rather than loose strings
//  so the sidebar, the selection state, and the detail pane can never drift
//  out of sync: adding a case here forces every switch over it to be updated.
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case general
    case hotkey
    case dictionary
    case history

    var id: String { rawValue }

    /// Label shown in the sidebar.
    var title: String {
        switch self {
        case .general:    return "General"
        case .hotkey:     return "Hotkey"
        case .dictionary: return "Dictionary"
        case .history:    return "History"
        }
    }

    /// SF Symbol shown beside the label. SF Symbols ship with macOS, so
    /// there are no image assets to add or keep in sync.
    var systemImage: String {
        switch self {
        case .general:    return "gearshape"
        case .hotkey:     return "command"
        case .dictionary: return "character.book.closed"
        case .history:    return "clock.arrow.circlepath"
        }
    }

    /// One line under the window title, so each pane says what it is for.
    var subtitle: String {
        switch self {
        case .general:    return "Startup, cleanup, and how text is delivered."
        case .hotkey:     return "Choose the key that starts and stops dictation."
        case .dictionary: return "Vocabulary hints and spoken-phrase snippets."
        case .history:    return "Past transcripts, stored only on this Mac."
        }
    }
}
