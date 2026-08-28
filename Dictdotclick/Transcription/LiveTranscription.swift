//
//  LiveTranscription.swift
//  Dictdotclick
//
//  Phase 8 — the shape of a transcript that is still being written.
//
//  Every earlier phase treated a transcript as a finished string. Live preview
//  breaks that: while you are still talking, part of what the engine has
//  produced is settled and part of it is a guess it intends to revise. Those
//  two halves need different handling and different rendering, so they get
//  different fields rather than being flattened into one string.
//
//  Apple's engine does the genuinely hard part. `SpeechTranscriber` emits each
//  result marked final or not, and a final result supersedes the volatile ones
//  covering the same audio. So the reconciliation this file owes is small:
//
//      final    -> append to `finalized`, clear `volatile`
//      volatile -> replace `volatile` wholesale
//
//  Being small is the point. Anything cleverer here — diffing, merging,
//  guessing at overlaps — would be second-guessing the engine with less
//  information than it has.
//

import Foundation

/// A transcript in progress: the part that is settled, and the part that is not.
struct LiveTranscript: Equatable {
    /// Results the engine marked final. This text will not change.
    var finalized: String = ""

    /// The engine's current guess at the audio it has heard but not yet
    /// committed. Expect this to be replaced repeatedly, and to be replaced by
    /// something quite different — that is the engine improving, not failing.
    var volatile: String = ""

    var isEmpty: Bool {
        finalized.isEmpty && volatile.isEmpty
    }

    /// Folds one result from the engine in.
    ///
    /// Final pieces are concatenated **raw**, with no separator inserted. That
    /// is deliberate: it is exactly what the verified one-shot path in
    /// `AppleTranscriber.transcribe` does, and that path produced correct
    /// spacing and punctuation on real speech. Adding a space here would make
    /// live and one-shot transcripts differ in a way that only shows up in
    /// use, which is the worst place to find it.
    mutating func apply(_ piece: String, isFinal: Bool) {
        if isFinal {
            finalized += piece
            volatile = ""
        } else {
            volatile = piece
        }
    }

    /// Everything heard so far, as one string. Used for display, never for
    /// delivery — what gets typed comes from `finalized` after the engine has
    /// been told the audio is over.
    var display: String {
        (finalized + volatile).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The finalized half, trimmed for display. Split out so the pill can draw
    /// the two halves in different colours without re-deriving where the seam
    /// is.
    var finalizedForDisplay: String {
        // Leading whitespace only: a trailing space is the join between this
        // and the volatile tail, and eating it would run the two together.
        String(finalized.drop(while: \.isWhitespace))
    }

    var volatileForDisplay: String {
        volatile
    }

    /// Keeps the last `maxCharacters` or so, cutting at a word boundary.
    ///
    /// Purely a layout guard. The pill shows two lines, so laying out a
    /// thousand characters to display twenty is wasted work on every single
    /// result — and results arrive several times a second.
    static func tail(of text: String, maxCharacters: Int) -> String {
        guard text.count > maxCharacters else { return text }
        let cut = text.index(text.endIndex, offsetBy: -maxCharacters)
        let window = text[cut...]
        // Prefer starting at a word boundary so the visible text does not
        // begin mid-word.
        if let space = window.firstIndex(where: { $0 == " " }) {
            return String(window[window.index(after: space)...])
        }
        return String(window)
    }
}

// MARK: - Engine capability

/// An engine that can transcribe while the audio is still arriving.
///
/// Separate from `Transcriber` rather than folded into it, because live
/// preview is optional and the app must work without it. A replacement engine
/// (whisper.cpp, if it ever comes back) can implement `Transcriber` alone and
/// the only thing lost is the preview.
protocol StreamingTranscriber: Transcriber {
    /// Opens a session and starts the engine. The session is live on return:
    /// audio can be appended immediately.
    ///
    /// - Parameter inputSampleRate: the rate of the samples that will be
    ///   appended. Fixed for a session — the engine's converter is built once
    ///   and reused, which matters because a fresh converter per chunk loses
    ///   its resampling state at every boundary.
    func makeLiveSession(hints: [String], inputSampleRate: Double) async throws -> LiveTranscriptionSession
}

/// One dictation's worth of streaming transcription.
///
/// Lifetime is start → append × N → finish. There is no reuse; a second
/// dictation gets a second session, because the engine's committed text is
/// session state and carrying it over would prepend the previous dictation to
/// this one.
protocol LiveTranscriptionSession: AnyObject {
    /// Fires on every revision. Finishes when `finish()` completes or the
    /// session fails.
    var updates: AsyncStream<LiveTranscript> { get }

    /// Feeds audio. Safe to call from a background queue; must not be called
    /// on the audio render thread.
    func append(samples: [Float])

    /// Tells the engine the audio is over, waits for it to flush, and returns
    /// the committed transcript.
    ///
    /// Throwing here is not fatal to a dictation — the caller still holds the
    /// full recording and can fall back to a one-shot transcription.
    func finish() async throws -> String
}
