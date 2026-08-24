//
//  GeneralSettingsView.swift
//  Dictdotclick
//
//  Phase 5 — the transcript debug panel.
//
//  Phase 5 deliberately shows the text here rather than typing it into the
//  focused app. Delivery is Phase 6's job, and separating them means a wrong
//  transcript and a failure to type it can never be confused for each other.
//

import SwiftUI

struct GeneralSettingsView: View {
    @State private var dictation = DictationController.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("Last transcript") {
                    transcriptCard
                }

                section("Speech engine") {
                    engineCard
                }

                section("Coming later") {
                    Text("Launch at login and the filler-word cleanup toggle arrive with the features they control — Phase 7.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .frame(maxWidth: 620, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if dictation.isTranscribing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Transcribing…")
                        .foregroundStyle(.secondary)
                }
            } else if dictation.lastTranscript.isEmpty {
                Text("Press \(dictation.binding.displayString), say something, then press it again.")
                    .foregroundStyle(.secondary)
            } else {
                Text(dictation.lastTranscript)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if dictation.capturedSecondsLastRun > 0 {
                HStack(spacing: 6) {
                    Text(String(format: "%.1f seconds of audio", dictation.capturedSecondsLastRun))
                    if let delivery = dictation.lastDelivery {
                        Text("·")
                        deliveryLabel(delivery)
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private func deliveryLabel(_ outcome: DeliveryOutcome) -> some View {
        switch outcome {
        case .inserted:
            Label("pasted into the focused app", systemImage: "checkmark")
                .labelStyle(.titleAndIcon)
        case .clipboardOnly:
            Label("copied only — press ⌘V", systemImage: "doc.on.clipboard")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.orange)
        }
    }

    private var engineCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dictation.transcriberName)
                .font(.headline)

            Text("Runs entirely on this Mac. Audio is never sent anywhere.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Stated rather than hidden: decision 4's vocabulary feature
            // depends on this, and a UI that implies it works when it does
            // not would be worse than one that admits the gap.
            if !dictation.transcriberSupportsHints {
                Label("Vocabulary hints are not yet wired to this engine — see Dictionary.",
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}

#Preview {
    GeneralSettingsView().frame(width: 620, height: 560)
}
