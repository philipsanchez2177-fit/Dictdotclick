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
//  Phase 8 adds a fourth thing, conditionally: the live transcript, as a
//  second line below the waveform row. It is a fixed-size row whenever it's
//  shown at all — never conditionally inserted mid-dictation — because
//  `RecordingHUD` sizes the panel once, when it appears, from whatever the
//  view's fitting size is at that moment. A row that grows with the
//  transcript would make the panel resize while the user is still talking,
//  which is worse than not showing the text at all.
//

import SwiftUI

struct RecordingPillView: View {
    @State private var audio = AudioCapture.shared
    @State private var dictation = DictationController.shared
    @State private var settings = AppSettings.shared

    /// Rolling history of levels, newest last. Fixed length so the view never
    /// grows without bound during a long dictation.
    @State private var levels: [Float] = []

    private let historyLength = 32
    /// Fixed width for the live-text row. Capped independently of the
    /// waveform row so a long sentence can't widen the pill mid-dictation.
    private let previewWidth: CGFloat = 260
    /// How much of the transcript to keep on screen. Kept short deliberately
    /// — `LiveTranscript.tail` truncating a long dictation to its last few
    /// words is a display concern, not a data-loss one; the full transcript
    /// is still what gets delivered.
    private let previewCharacterBudget = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            if settings.enableLivePreview {
                livePreviewRow
            }
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

    /// Settled words in the normal text colour, the engine's current guess
    /// dimmed below it — so revision reads as "still listening" rather than
    /// as a glitch. Reserves its row whether or not there's anything to show
    /// yet (opacity, not `if`), which is what keeps the panel from resizing
    /// the instant the first word lands.
    private var livePreviewRow: some View {
        let transcript = dictation.liveTranscript
        let finalTail = LiveTranscript.tail(of: transcript.finalizedForDisplay, maxCharacters: previewCharacterBudget)
        let volatileTail = LiveTranscript.tail(of: transcript.volatileForDisplay, maxCharacters: previewCharacterBudget)

        return (Text(finalTail).foregroundStyle(.primary) + Text(volatileTail).foregroundStyle(.secondary))
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.head)
            .frame(width: previewWidth, height: 16, alignment: .leading)
            .opacity(transcript.isEmpty ? 0 : 1)
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
