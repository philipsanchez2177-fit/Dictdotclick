//
//  WaveformView.swift
//  Dictdotclick
//
//  Phase 4 — the bars that move with your voice.
//
//  This exists to answer one question the user has while talking: *is it
//  actually hearing me?* A static "Recording…" label cannot answer it — a
//  muted microphone looks identical to a working one. Bars driven by real
//  amplitude can only move if sound is arriving.
//
//  New samples enter at the right and scroll left, so the shape is a short
//  history rather than a single number. That makes a dropout visible: a flat
//  stretch mid-sentence is a gap you can see.
//

import SwiftUI

struct WaveformView: View {
    /// Newest last. Values 0...1.
    let levels: [Float]
    var barCount: Int = 32

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(.tint)
                    .frame(width: 3, height: height(at: index))
                    .opacity(opacity(at: index))
            }
        }
        .frame(height: 28)
        .animation(.linear(duration: 0.05), value: levels.count)
    }

    private func height(at index: Int) -> CGFloat {
        // Fill from the right: the newest sample is the rightmost bar.
        let offset = barCount - levels.count
        let level: Float = index >= offset ? levels[index - offset] : 0
        // A visible floor, so an idle waveform reads as "listening, hearing
        // nothing" rather than "broken".
        return 3 + CGFloat(level) * 25
    }

    /// Older bars fade slightly, which gives the scroll a direction.
    private func opacity(at index: Int) -> Double {
        let position = Double(index) / Double(max(1, barCount - 1))
        return 0.35 + position * 0.65
    }
}

#Preview {
    WaveformView(levels: (0..<32).map { _ in Float.random(in: 0...1) })
        .padding()
        .frame(width: 200)
}
