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

    /// Confirmed 2026-08-22 by reading the framework's own interface:
    /// `AnalysisContext.contextualStrings` takes a list of words that bias
    /// recognition, and `SpeechAnalyzer.setContext` applies it. That is the
    /// mechanism decision 4 needs, so the earlier `false` no longer tells the
    /// truth.
    ///
    /// This says the hints are *passed to the engine*, which is now true.
    /// Whether they measurably improve recognition of a rare word is a Phase 7
    /// test with real vocabulary.
    let supportsVocabularyHints = true

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

        // Vocabulary hints. `.general` is the untagged bucket — tags exist so
        // different sets can be swapped independently later (say, per-app
        // jargon), which is not needed yet.
        //
        // Only the lightweight path is used. The framework also offers
        // `SFCustomLanguageModelData`, with custom pronunciations and phrase
        // weighting; that is a bigger hammer than a word list and is recorded
        // in DEFERRED rather than reached for now.
        if !hints.isEmpty {
            let context = AnalysisContext()
            context.contextualStrings = [.general: hints]
            try await analyzer.setContext(context)
        }

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
    /// results, no alternates. The one-shot path above uses it because a
    /// finished recording has no use for partial results.
    ///
    /// The framework also offers `DictationTranscriber`, whose presets are
    /// named for this exact use case (`.shortDictation`, `.longDictation`).
    /// Not adopted: it is a second unknown, and one is enough per phase.
    /// Recorded in `DEFERRED.md`.
    private func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(locale: locale, preset: .transcription)
    }

    /// Phase 8's preset: emits volatile results as audio arrives, not just a
    /// final one at the end. Same engine, same locale — only the preset
    /// differs from the one-shot path.
    private func makeStreamingTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
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

// MARK: - Streaming (Phase 8)

extension AppleTranscriber: StreamingTranscriber {
    /// Opens a live session. `prepare()` is called first for the same reason
    /// the one-shot path calls it: the language model must be installed
    /// before anything is fed to the engine, and a session opened against a
    /// missing model would fail on the first `append`, mid-dictation, which
    /// is a far worse place to discover it than at start time.
    func makeLiveSession(hints: [String], inputSampleRate: Double) async throws -> LiveTranscriptionSession {
        try await prepare()

        let transcriber = makeStreamingTranscriber()
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        if !hints.isEmpty {
            let context = AnalysisContext()
            context.contextualStrings = [.general: hints]
            try await analyzer.setContext(context)
        }

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.engineFailed("no compatible audio format")
        }

        guard let sourceFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw TranscriptionError.engineFailed("could not describe the input format")
        }

        return AppleLiveSession(
            analyzer: analyzer,
            transcriber: transcriber,
            sourceFormat: sourceFormat,
            analyzerFormat: analyzerFormat
        )
    }
}

/// One dictation's worth of streaming state.
///
/// Everything that must survive across `append` calls lives here rather than
/// as free functions: the converter in particular carries internal filter
/// state between chunks, and rebuilding it per chunk (the one-shot path's
/// approach, correct there because it converts exactly once) would introduce
/// a small resampling discontinuity at every buffer boundary — inaudible on
/// its own, but this runs on every chunk of a long dictation.
private final class AppleLiveSession: LiveTranscriptionSession {
    private let analyzer: SpeechAnalyzer
    private let transcriber: SpeechTranscriber
    private let sourceFormat: AVAudioFormat
    private let analyzerFormat: AVAudioFormat
    private let converter: AVAudioConverter?

    private let inputStream: AsyncStream<AnalyzerInput>
    private let inputContinuation: AsyncStream<AnalyzerInput>.Continuation

    private let (updateStream, updateContinuation) = AsyncStream<LiveTranscript>.makeStream()
    private var transcript = LiveTranscript()

    /// Consumes `transcriber.results` and folds each one into `transcript`.
    /// Started eagerly in `init` so no result arriving before the first
    /// `append` is missed.
    private var resultTask: Task<Void, Never>?
    private var startError: Error?

    var updates: AsyncStream<LiveTranscript> { updateStream }

    init(analyzer: SpeechAnalyzer, transcriber: SpeechTranscriber, sourceFormat: AVAudioFormat, analyzerFormat: AVAudioFormat) {
        self.analyzer = analyzer
        self.transcriber = transcriber
        self.sourceFormat = sourceFormat
        self.analyzerFormat = analyzerFormat
        self.converter = sourceFormat == analyzerFormat ? nil : AVAudioConverter(from: sourceFormat, to: analyzerFormat)

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputStream = stream
        self.inputContinuation = continuation

        // Started eagerly, before the analyzer itself: `transcriber.results`
        // is a stream that must be listening before results can arrive, and
        // `analyzer.start` below can begin producing them immediately.
        beginConsumingResults()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.analyzer.start(inputSequence: self.inputStream)
            } catch {
                self.startError = error
                self.updateContinuation.finish()
            }
        }
    }

    private func beginConsumingResults() {
        resultTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in self.transcriber.results {
                    let piece = String(result.text.characters)
                    self.transcript.apply(piece, isFinal: result.isFinal)
                    self.updateContinuation.yield(self.transcript)
                }
            } catch {
                // Reported through `finish()`'s throw, not here — a result
                // stream failing mid-dictation should not silently truncate
                // what was already shown.
            }
            self.updateContinuation.finish()
        }
    }

    func append(samples: [Float]) {
        guard !samples.isEmpty else { return }

        guard let source = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        source.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { raw in
            source.floatChannelData?[0].update(from: raw.baseAddress!, count: samples.count)
        }

        guard let converter else {
            inputContinuation.yield(AnalyzerInput(buffer: source))
            return
        }

        let ratio = analyzerFormat.sampleRate / sourceFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(samples.count) * ratio).rounded(.up)) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: analyzerFormat, frameCapacity: capacity) else { return }

        var supplied = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if supplied { status.pointee = .noDataNow; return nil }
            supplied = true
            status.pointee = .haveData
            return source
        }

        guard error == nil, out.frameLength > 0 else { return }
        inputContinuation.yield(AnalyzerInput(buffer: out))
    }

    func finish() async throws -> String {
        inputContinuation.finish()
        do {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
        } catch {
            if let startError { throw startError }
            throw TranscriptionError.engineFailed(error.localizedDescription)
        }

        // Give the result task a moment to drain the last results the flush
        // above produced — `finalizeAndFinishThroughEndOfInput` returning
        // does not guarantee `transcriber.results` has yielded its last item
        // yet.
        _ = await resultTask?.value

        return transcript.finalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
