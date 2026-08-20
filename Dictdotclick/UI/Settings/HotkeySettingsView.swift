//
//  HotkeySettingsView.swift
//  Dictdotclick
//
//  Phase 3 — the Hotkey pane: record a key, and watch it work.
//
//  The live indicator is the whole point of this phase. Dictation has no audio
//  yet, so the only way to know the global tap works is to see the state
//  change while typing in some *other* app — which is exactly what this shows.
//

import SwiftUI

struct HotkeySettingsView: View {
    @State private var dictation = DictationController.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if dictation.monitorFailed {
                    permissionWarning
                }

                section("Dictation key") {
                    HotkeyRecorderField(binding: dictation.binding) { newBinding in
                        dictation.setBinding(newBinding)
                    }

                    Text("Press it once to start dictating, again to stop. Not press-and-hold.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                section("Status") {
                    statusRow
                }

                section("What's allowed") {
                    VStack(alignment: .leading, spacing: 6) {
                        rule("Any combination with ⌘, ⌥, ⌃, or ⇧", ok: true)
                        rule("A function key on its own — F1 through F20", ok: true)
                        rule("A double-tap of `", ok: true)
                        rule("A plain letter, number, or symbol", ok: false)
                    }

                    Text("A plain key is refused because claiming it would stop you typing that character anywhere else on your Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pieces

    private var statusRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(dictation.isListening ? Color.red : Color.secondary.opacity(0.4))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(dictation.isListening ? "Listening" : "Idle")
                    .font(.headline)
                Text(dictation.isListening
                     ? "Press \(dictation.binding.displayString) again to stop."
                     : "Press \(dictation.binding.displayString) anywhere to start — you don't need this window open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    private var permissionWarning: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Dictdotclick can't watch the keyboard")
                    .font(.headline)
                Text("Accessibility permission is off, so the hotkey won't work in other apps. Rebuilding the app can reset it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Permissions") {
                    openWindow(id: PermissionsWindow.windowID)
                }
                .controlSize(.small)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func rule(_ text: String, ok: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? .green : .red)
                .font(.caption)
            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    HotkeySettingsView()
        .frame(width: 620, height: 560)
}
