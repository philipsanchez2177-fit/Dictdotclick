//
//  RecordingPillView.swift
//  Dictdotclick
//
//  Phase 4 — what the floating pill actually shows.
//
//  Three things, in priority order: that it is recording (the dot), that it
//  can hear you (the waveform), and how long you have been talking (the
//  timer). Nothing else — this sits over the user's real work and every extra
//  pixel is in the way.
//
//  `.glassEffect` is applied by hand because this is a floating element above
//  other content, which is exactly what Liquid Glass is for.
//

import SwiftUI

struct RecordingPillView: View {
    @State private var audio = AudioCapture.shared
    /// Rolling history of levels, newest last. Fixed length so the view never
    /// grows without bound during a long dictation.
    @State private var levels: [Float] = []

    private let historyLength = 32

    var body: some View {
        HStack(spacing: 12) {
            recordingDot

            WaveformView(levels: levels, barCount: historyLength)

            Text(timeString)
                .font(.system(.callout, design: .monospaced).weight(.medium))
                .foregroundStyle(.secondary)
                // Monospaced digits alone aren't enough — the string gets
                // wider at 10 seconds. A fixed width stops the waveform
                // jumping sideways mid-sentence.
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .fixedSize()
        // Sampling here rather than in the audio layer keeps the history a
        // display concern: the capture object publishes one number, this view
        // decides how much past to remember.
        .onChange(of: audio.level) { _, newValue in
            levels.append(newValue)
            if levels.count > historyLength { levels.removeFirst(levels.count - historyLength) }
        }
        .onDisappear { levels.removeAll() }
    }

    private var recordingDot: some View {
        Circle()
            .fill(.red)
            .frame(width: 9, height: 9)
            // A steady dot reads as a decoration; a pulsing one reads as
            // live. Cheap, and it keeps meaning something if the microphone
            // goes silent.
            .opacity(audio.isCapturing ? 1 : 0.4)
            .scaleEffect(audio.isCapturing ? 1 : 0.8)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                       value: audio.isCapturing)
    }

    private var timeString: String {
        let total = Int(audio.duration)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

#Preview {
    RecordingPillView()
        .padding(40)
}
