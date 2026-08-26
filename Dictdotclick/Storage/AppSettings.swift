//
//  AppSettings.swift
//  Dictdotclick
//
//  Phase 7 — small app-wide preferences that aren't the hotkey.
//
//  The hotkey has its own file because it is a type of its own; these are
//  loose switches. One struct on disk means adding the next one is a field,
//  not another file.
//

import Foundation
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private static let filename = "settings.json"

    /// Whether "um", "uh" and friends are dropped from a transcript before
    /// it is delivered.
    ///
    /// Off by default, on purpose. The app's job is to type what was said;
    /// silently editing it is a choice the user should make deliberately.
    var removeFillerWords: Bool {
        didSet { save() }
    }

    private init() {
        let stored = JSONStore.load(Stored.self, from: Self.filename) ?? Stored()
        removeFillerWords = stored.removeFillerWords
    }

    private func save() {
        JSONStore.save(Stored(removeFillerWords: removeFillerWords), to: Self.filename)
    }

    /// The on-disk shape, kept separate from the observable object so the
    /// file format is a plain value type.
    private struct Stored: Codable {
        var removeFillerWords: Bool = false
    }
}
