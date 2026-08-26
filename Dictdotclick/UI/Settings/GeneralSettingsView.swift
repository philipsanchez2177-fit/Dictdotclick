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
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("Last transcript") {
                    transcriptCard
                }

                section("Speech engine") {
                    engineCard
                }

                section("Cleanup") {
                    cleanupCard
                }

                section("Coming later") {
                    Text("Launch at login arrives with the features it controls.")
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

                // Shown only when the dictionary actually changed something.
                // Without it, a snippet that failed to match and a word the
                // engine misheard look identical — and they have opposite
                // fixes.
                if dictation.lastTranscriptWasProcessed {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heard before the dictionary was applied")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                        Text(dictation.lastHeardTranscript)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
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

    private var cleanupCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Remove filler words", isOn: $settings.removeFillerWords)

            Text("Drops \u{201C}um\u{201D}, \u{201C}uh\u{201D}, \u{201C}er\u{201D} and \u{201C}hmm\u{201D}, then tidies the spacing. Off by default \u{2014} words like \u{201C}like\u{201D} and \u{201C}so\u{201D} are left alone, because they are usually real.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
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
