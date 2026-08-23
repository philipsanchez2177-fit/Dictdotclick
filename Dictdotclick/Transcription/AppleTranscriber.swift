//
//  AppleTranscriber.swift
//  Dictdotclick
//
//  Phase 5 — transcription using macOS 26's built-in speech engine.
//
//  `SpeechAnalyzer` is Apple's on-device speech-to-text, introduced in
//  macOS 26. It runs locally, the OS manages the language models, and there
//  is nothing for this app to download or ship. That removed the two largest
//  risks in this phase: a C++ dependency and a ~460 MB file that must never
//  reach git.
//
//  ── This file is the least certain in the project ──────────────────────
//  It was written against a framework new enough that exact symbol names may
//  differ. Everything it depends on is confined here, behind `Transcriber`;
//  a compile failure means correcting names in one file, not unpicking the
//  app. If it proves unworkable, whisper.cpp implements the same protocol.
//
//  The engine is stream-oriented, built for dictation as it happens. Phase 5
//  uses it in one shot on a finished recording, which is the simpler case and
//  the right order: prove text comes out at all before adding live preview in
//  Phase 8, which is what streaming is really for.
//

import Foundation
import Speech
import AVFoundation

final class AppleTranscriber: Transcriber {
    let displayName = "macOS built-in (SpeechAnalyzer)"

    /// Unverified against this engine. Left false so the UI tells the truth
    /// instead of promising a feature that may not be working — flipping it
    /// requires evidence, not optimism. See `DEFERRED.md`.
    let supportsVocabularyHints = false

    private let locale: Locale

    init(locale: Locale = Locale.current) {
        self.locale = locale
    }

    // MARK: - Preparation

    /// Asks for permission and makes sure the language model is installed.
    /// Both are one-time and both can take a while, which is why this is
    /// separate from `transcribe`.
    func prepare() async throws {
        try await requestAuthorization()

        // Locales the engine can transcribe at all, versus those whose model
        // is already on disk. The gap between them is a download.
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            throw TranscriptionError.languageUnavailable(locale.identifier)
        }

        let installed = await SpeechTranscriber.installedLocales
        if installed.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
            return
        }

        let transcriber = makeTranscriber()
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
        } catch {
            throw TranscriptionError.modelDownloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Transcription

    func transcribe(samples: [Float], sampleRate: Double, hints: [String]) async throws -> String {
        guard !samples.isEmpty else { throw TranscriptionError.noAudio }

        try await prepare()

        let transcriber = makeTranscriber()
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        // The engine names the format it wants rather than accepting ours,
        // so the recorded 16 kHz mono buffer is converted to match.
        // `bestAvailableAudioFormat` is a static on SpeechAnalyzer, not on
        // the transcriber — it answers for a whole set of modules, since an
        // analyzer can run several at once.
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.engineFailed("no compatible audio format")
        }

        guard let buffer = Self.makeBuffer(samples: samples, sampleRate: sampleRate, target: analyzerFormat) else {
            throw TranscriptionError.engineFailed("could not convert the recording")
        }

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()

        // Results arrive while audio is still being fed, so collection has to
        // run alongside the feed rather than after it.
        let collector = Task { () -> String in
            var text = ""
            for try await result in transcriber.results where result.isFinal {
                text += String(result.text.characters)
            }
            return text
        }

        do {
            try await analyzer.start(inputSequence: stream)
            continuation.yield(AnalyzerInput(buffer: buffer))
            continuation.finish()
            // Flushes anything still buffered and ends the result stream —
            // without it the collector waits forever.
            try await analyzer.finalizeAndFinishThroughEndOfInput()
        } catch {
            collector.cancel()
            throw TranscriptionError.engineFailed(error.localizedDescription)
        }

        let text = try await collector.value
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    /// `.transcription` is the plain preset: a final transcript, no interim
    /// results, no alternates. Phase 8's live preview will want
    /// `.progressiveTranscription` instead — that is the preset that emits
    /// partial results as the audio arrives.
    ///
    /// The framework also offers `DictationTranscriber`, whose presets are
    /// named for this exact use case (`.shortDictation`, `.longDictation`).
    /// Not adopted yet: it is a second unknown, and one is enough per phase.
    /// Recorded in `DEFERRED.md`.
    private func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(locale: locale, preset: .transcription)
    }

    private func requestAuthorization() async throws {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard granted == .authorized else { throw TranscriptionError.notAuthorized }
        default:
            throw TranscriptionError.notAuthorized
        }
    }

    /// Wraps the recorded samples in a buffer of the format the engine asked
    /// for, resampling if the rates differ.
    private static func makeBuffer(samples: [Float], sampleRate: Double, target: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let sourceFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ), let source = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return nil
        }

        source.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { raw in
            source.floatChannelData?[0].update(from: raw.baseAddress!, count: samples.count)
        }

        if sourceFormat == target { return source }

        guard let converter = AVAudioConverter(from: sourceFormat, to: target) else { return nil }
        let ratio = target.sampleRate / sourceFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(samples.count) * ratio).rounded(.up)) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return nil }

        var supplied = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if supplied { status.pointee = .noDataNow; return nil }
            supplied = true
            status.pointee = .haveData
            return source
        }

        return error == nil ? out : nil
    }
}
