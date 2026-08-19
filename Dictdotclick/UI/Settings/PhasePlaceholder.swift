//
//  PhasePlaceholder.swift
//  Dictdotclick
//
//  Phase 1 — a shared "this pane is not built yet" card.
//
//  This is the one place in the Settings window where Liquid Glass is applied
//  by hand. `.glassEffect` is a macOS 26 API: it renders the view as a lensing,
//  light-bending material rather than a flat fill. It belongs on floating
//  elements that sit *above* content — a card like this one, or the recording
//  pill in Phase 4 — not on backgrounds, which get glass from the system.
//
//  Every use of it is a Liquid Glass smoke test: if the window opens and this
//  card looks like frosted glass, the material pipeline works, and Phase 4 can
//  rely on it.
//

import SwiftUI

struct PhasePlaceholder: View {
    let icon: String
    let headline: String
    let detail: String
    /// Which build phase fills this pane in. Shown so the window is honest
    /// about what is and isn't wired up yet.
    let arrivesInPhase: Int

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tint)

            Text(headline)
                .font(.headline)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Arrives in Phase \(arrivesInPhase)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .glassEffect(.regular, in: .capsule)
        }
        .padding(28)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    PhasePlaceholder(
        icon: "command",
        headline: "Hotkey recorder",
        detail: "Press a key combination and Dictdotclick will listen for it everywhere.",
        arrivesInPhase: 3
    )
}
