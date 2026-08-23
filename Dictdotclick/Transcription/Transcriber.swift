//
//  Transcriber.swift
//  Dictdotclick
//
//  Phase 5 — the swap point.
//
//  Speech-to-text is the one part of this app most likely to be replaced.
//  macOS 26's built-in `SpeechAnalyzer` is the current choice: no model to
//  download, no C++ dependency, and it is already on the machine. But it is
//  new, and one requirement is unproven against it — decision 4 needs a way
//  to bias recognition toward rare words ("Dictdotclick", coworkers' names),
//  which whisper.cpp does with an initial prompt.
//
//  So transcription lives behind this protocol. If vocabulary hints turn out
//  to be too weak in Phase 7, a whisper.cpp implementation drops in here and
//  nothing around it changes.
//

import Foundation

/// Audio in, text out. Implementations must not send audio off the machine.
protocol Transcriber: AnyObject {
    /// Shown in Settings so it is always clear which engine produced a
    /// transcript — the whole point of keeping this swappable.
    var displayName: String { get }

    /// Whether `hints` in `transcribe` actually influences recognition.
    /// False means decision 4's vocabulary feature is degraded, and the UI
    /// should say so rather than implying it works.
    var supportsVocabularyHints: Bool { get }

    /// Downloads or warms whatever the engine needs. Separate from
    /// `transcribe` because the first run may take a while and the user
    /// deserves to see that happening rather than a stalled transcript.
    func prepare() async throws

    /// - Parameters:
    ///   - samples: mono 32-bit float PCM at `sampleRate`.
    ///   - hints: words to bias toward. Ignored when unsupported.
    func transcribe(samples: [Float], sampleRate: Double, hints: [String]) async throws -> String
}

/// Failures worth telling the user about in plain language. A transcription
/// that fails silently is indistinguishable from one that heard nothing.
enum TranscriptionError: LocalizedError {
    case notAuthorized
    case languageUnavailable(String)
    case modelDownloadFailed(String)
    case noAudio
    case engineFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition permission is off. Turn it on in System Settings → Privacy & Security → Speech Recognition."
        case .languageUnavailable(let name):
            return "macOS has no on-device speech model for \(name)."
        case .modelDownloadFailed(let why):
            return "The speech model couldn't be installed: \(why)"
        case .noAudio:
            return "No audio was recorded."
        case .engineFailed(let why):
            return "Transcription failed: \(why)"
        }
    }
}
