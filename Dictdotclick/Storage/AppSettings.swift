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

    /// Phase 8 — whether the pill shows text while you're still talking.
    ///
    /// On by default: decision 3 named live preview as part of the design,
    /// not an experiment. The switch exists as an escape hatch, not because
    /// the feature is expected to need it — turning it off falls back to
    /// exactly Phase 7's pill (waveform and timer only). It has no effect on
    /// reliability either way: `DictationController` always falls back to a
    /// full one-shot transcription if the live session comes back empty or
    /// fails, on or off.
    var enableLivePreview: Bool {
        didSet { save() }
    }

    private init() {
        let stored = JSONStore.load(Stored.self, from: Self.filename)
            ?? Stored(removeFillerWords: false, enableLivePreview: true)
        removeFillerWords = stored.removeFillerWords
        enableLivePreview = stored.enableLivePreview
    }

    private func save() {
        JSONStore.save(
            Stored(removeFillerWords: removeFillerWords, enableLivePreview: enableLivePreview),
            to: Self.filename
        )
    }

    /// The on-disk shape, kept separate from the observable object so the
    /// file format is a plain value type.
    ///
    /// Decoding is hand-written rather than synthesized. A settings.json
    /// written before this field existed has no `enableLivePreview` key, and
    /// synthesized `Decodable` treats a missing key on a non-optional
    /// property as a decode failure for the *whole* struct — which would
    /// silently reset `removeFillerWords` back to its default too, discarding
    /// whatever the user had chosen. `decodeIfPresent` lets each field fall
    /// back independently.
    private struct Stored: Codable {
        var removeFillerWords: Bool = false
        var enableLivePreview: Bool = true

        init(removeFillerWords: Bool, enableLivePreview: Bool) {
            self.removeFillerWords = removeFillerWords
            self.enableLivePreview = enableLivePreview
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            removeFillerWords = try container.decodeIfPresent(Bool.self, forKey: .removeFillerWords) ?? false
            enableLivePreview = try container.decodeIfPresent(Bool.self, forKey: .enableLivePreview) ?? true
        }
    }
}
