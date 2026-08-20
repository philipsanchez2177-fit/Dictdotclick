//
//  HotkeyRecorderField.swift
//  Dictdotclick
//
//  Phase 3 — the control you press a key into.
//
//  While recording, this installs a *local* key monitor: it sees keys only
//  while this app is frontmost, which is all that is needed and avoids
//  claiming anything system-wide just to read one press. The global tap
//  (HotkeyMonitor) stays paused meanwhile, so recording a new hotkey can never
//  trigger dictation.
//

import SwiftUI
import AppKit
import CoreGraphics

struct HotkeyRecorderField: View {
    let binding: HotkeyBinding
    let onRecorded: (HotkeyBinding) -> Void

    @State private var isRecording = false
    @State private var rejection: HotkeyRejection?
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggleRecording) {
                HStack(spacing: 10) {
                    Image(systemName: isRecording ? "record.circle" : "keyboard")
                        .foregroundStyle(isRecording ? .red : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRecording ? "Listening — press your key…" : binding.displayString)
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundStyle(isRecording ? .secondary : .primary)

                        if !isRecording, let hint = binding.displayHint {
                            Text(hint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(isRecording ? "Esc to cancel" : "Click to change")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isRecording ? Color.red.opacity(0.8) : .clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            // Rejections are shown, never silently swallowed. A recorder that
            // ignores a key press is indistinguishable from a broken one.
            if let rejection {
                Label(rejection.message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onDisappear(perform: endRecording)
    }

    // MARK: - Recording

    private func toggleRecording() {
        isRecording ? endRecording() : beginRecording()
    }

    private func beginRecording() {
        rejection = nil
        isRecording = true

        // Pause the global tap so the key being recorded doesn't also fire
        // the hotkey that is currently bound.
        DictationController.shared.stopMonitoring()

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil  // swallow it: this keystroke is UI input, not text
        }
    }

    private func endRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        DictationController.shared.startMonitoring()
    }

    private func handle(_ event: NSEvent) {
        let keyCode = event.keyCode
        let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)).deviceIndependent

        // Escape with no modifiers means "never mind", not "bind Escape".
        if keyCode == KeyCode.escape, flags.isEmpty {
            endRecording()
            return
        }

        switch HotkeyValidator.binding(forKeyCode: keyCode, flags: flags) {
        case .success(let newBinding):
            rejection = nil
            onRecorded(newBinding)
            endRecording()
        case .failure(let why):
            // Stay in recording mode so the next attempt needs no extra click.
            rejection = why
        }
    }
}
