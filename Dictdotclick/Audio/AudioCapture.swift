//
//  AudioCapture.swift
//  Dictdotclick
//
//  Phase 4 — listening to the microphone.
//
//  Two jobs, and they run at very different speeds:
//
//  1. Collect audio in the format Whisper needs — 16 kHz, mono, 32-bit float.
//     The microphone almost never produces that natively (48 kHz stereo is
//     typical), so every buffer is converted on the way in. Doing it here
//     rather than in Phase 5 means the transcriber receives exactly what it
//     expects and the conversion is proven before anything depends on it.
//
//  2. Report loudness for the waveform. That has to reach the UI ~20 times a
//     second to look alive, but the audio callback fires far more often than
//     that and runs on a real-time thread where UI work is forbidden.
//
//  So the audio thread does arithmetic and appends to an array; a throttled
//  hop to the main thread publishes the level. Anything heavier on that
//  thread produces audible glitches.
//

import Foundation
import Observation
import AVFoundation

@Observable
final class AudioCapture {
    /// One shared instance. The pill and the controller must observe the same
    /// capture session, and there is only ever one microphone in use.
    static let shared = AudioCapture()

    /// Whisper's required input format.
    static let targetSampleRate: Double = 16_000

    /// Current loudness, 0...1, already smoothed for display.
    private(set) var level: Float = 0
    private(set) var isCapturing = false

    /// Seconds of audio collected in the current session.
    private(set) var duration: TimeInterval = 0

    /// Set when the engine refuses to start. Almost always a missing
    /// microphone permission or a device that vanished mid-session.
    private(set) var lastError: String?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var converter: AVAudioConverter?
    @ObservationIgnored private var targetFormat: AVAudioFormat?

    /// Collected 16 kHz mono samples. Phase 4 discards these on stop; Phase 5
    /// hands them to the transcriber as a whole recording. Phase 8 keeps
    /// collecting the same buffer even while a live session is running,
    /// because the one-shot path is still the fallback if streaming fails.
    @ObservationIgnored private var samples: [Float] = []
    @ObservationIgnored private let samplesLock = NSLock()

    @ObservationIgnored private var lastPublish = Date.distantPast
    @ObservationIgnored private let publishInterval: TimeInterval = 1.0 / 20.0

    /// Phase 8 — set while a live transcription session wants every chunk as
    /// it's converted. Read and written under `samplesLock`, same as
    /// `samples`, so a chunk always lands in exactly one of "already in the
    /// snapshot `beginLiveFeed` returned" or "delivered to this handler" —
    /// never both, never neither.
    @ObservationIgnored private var liveChunkHandler: (([Float]) -> Void)?

    /// Hops live chunks off the audio render thread before calling the
    /// handler. `process()` runs on a real-time thread where anything beyond
    /// arithmetic and an array append risks an audible glitch; a streaming
    /// session's `append` does format conversion and stream I/O, neither of
    /// which belongs there.
    @ObservationIgnored private let liveQueue = DispatchQueue(label: "click.dict.Dictdotclick.livefeed", qos: .userInitiated)

    private init() {}

    // MARK: - Control

    @discardableResult
    func start() -> Bool {
        guard !isCapturing else { return true }
        lastError = nil

        let input = engine.inputNode
        // The hardware's own format. Asking for anything else here fails on
        // many devices — the tap must match what the node actually produces,
        // and conversion happens afterwards.
        let inputFormat = input.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            lastError = "No microphone input is available."
            return false
        }

        guard let target = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.targetSampleRate,
            channels: 1,
            interleaved: false
        ), let conv = AVAudioConverter(from: inputFormat, to: target) else {
            lastError = "Could not set up audio conversion."
            return false
        }

        targetFormat = target
        converter = conv

        samplesLock.lock(); samples.removeAll(keepingCapacity: true); samplesLock.unlock()
        duration = 0

        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            lastError = error.localizedDescription
            return false
        }

        isCapturing = true
        return true
    }

    /// Stops capture and hands back everything collected.
    @discardableResult
    func stop() -> [Float] {
        guard isCapturing else { return [] }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        level = 0

        samplesLock.lock()
        let collected = samples
        samples.removeAll(keepingCapacity: false)
        samplesLock.unlock()

        return collected
    }

    // MARK: - Live feed (Phase 8)

    /// Atomically hands back everything captured so far and starts routing
    /// every subsequent chunk to `onChunk`. One lock covers both halves on
    /// purpose: a streaming session's setup (`makeLiveSession`) is async and
    /// takes a moment, and audio keeps arriving the whole time. Splitting the
    /// snapshot and the subscribe into two separate locked calls would leave
    /// a window where a chunk converted in between is lost — heard by
    /// neither the snapshot nor the handler.
    func beginLiveFeed(onChunk: @escaping ([Float]) -> Void) -> [Float] {
        samplesLock.lock()
        let collectedSoFar = samples
        liveChunkHandler = onChunk
        samplesLock.unlock()
        return collectedSoFar
    }

    /// Detaches the handler. Safe to call even after `stop()` has already
    /// torn down the engine — there is nothing left to detach from, and this
    /// just clears the reference so it isn't held longer than needed.
    func endLiveFeed() {
        samplesLock.lock()
        liveChunkHandler = nil
        samplesLock.unlock()
    }

    // MARK: - Audio thread

    /// Runs on the audio thread. No allocation beyond the append, no locks
    /// held longer than necessary, no UI work.
    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let converter, let targetFormat else { return }

        // Output capacity scales with the sample-rate ratio. Rounding up
        // avoids a short buffer when the ratio isn't a whole number.
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1

        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var supplied = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            // The converter pulls until satisfied. Handing the same buffer
            // twice would duplicate audio, so the second call reports "no
            // more data" instead.
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }

        guard error == nil, out.frameLength > 0,
              let channel = out.floatChannelData?[0] else { return }

        let count = Int(out.frameLength)

        // RMS — the standard measure of "how loud is this chunk", closer to
        // perceived volume than peak, which spikes on a single click.
        var sumOfSquares: Float = 0
        for i in 0..<count { sumOfSquares += channel[i] * channel[i] }
        let rms = (sumOfSquares / Float(count)).squareRoot()

        let chunk = Array(UnsafeBufferPointer(start: channel, count: count))

        samplesLock.lock()
        samples.append(contentsOf: chunk)
        let total = samples.count
        let handler = liveChunkHandler
        samplesLock.unlock()

        if let handler {
            liveQueue.async { handler(chunk) }
        }

        publish(rms: rms, totalSamples: total)
    }

    /// Throttled hop to the main thread. Speech RMS sits around 0.01–0.2, so
    /// the raw value would barely move a bar — it is scaled and eased before
    /// display, and smoothed so the waveform glides instead of flickering.
    private func publish(rms: Float, totalSamples: Int) {
        let now = Date()
        guard now.timeIntervalSince(lastPublish) >= publishInterval else { return }
        lastPublish = now

        let scaled = min(1, rms * 6)
        let eased = scaled.squareRoot()
        let seconds = Double(totalSamples) / Self.targetSampleRate

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Rise fast so a word registers immediately, fall slowly so the
            // bars don't collapse between syllables.
            let smoothing: Float = eased > self.level ? 0.5 : 0.15
            self.level += (eased - self.level) * smoothing
            self.duration = seconds
        }
    }
}
