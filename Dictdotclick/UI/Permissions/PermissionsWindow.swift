//
//  PermissionsWindow.swift
//  Dictdotclick
//
//  Phase 2 — the permissions walkthrough.
//
//  Layout follows the rules Phase 1 paid for: a plain VStack with explicit
//  frames, no adaptive container deciding on its own what to show. Nothing
//  here can collapse at a small window size.
//
//  This window polls while it is open (see PermissionsModel.startPolling).
//  The user will leave it on screen, grant permission in System Settings, and
//  come back expecting the dot to have turned green.
//

import SwiftUI

struct PermissionsWindow: View {
    static let windowID = "permissions"

    /// The shared model, so this window and the menu bar always agree.
    @State private var permissions = PermissionsModel.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(spacing: 12) {
                ForEach(Permission.allCases) { permission in
                    PermissionRow(
                        permission: permission,
                        status: permissions.status(of: permission),
                        onRequest: { permissions.request(permission) },
                        onOpenSettings: { permissions.openSystemSettings(for: permission) }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            footer
        }
        .frame(minWidth: 620, idealWidth: 660, minHeight: 520, idealHeight: 560)
        .navigationTitle("Permissions")
        .navigationSubtitle(permissions.allGranted
                            ? "Everything Dictdotclick needs is granted."
                            : "\(permissions.missing.count) still needed.")
        // Poll only while visible. A menu-bar app runs all day; it has no
        // business waking on a timer once this window is closed.
        .task {
            permissions.startPolling()
        }
        .onDisappear {
            permissions.stopPolling()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(permissions.allGranted ? "You're all set" : "Two switches to flip")
                .font(.title2.weight(.semibold))

            Text(permissions.allGranted
                 ? "Dictdotclick has everything it needs from macOS. Nothing else to do here."
                 : "macOS requires your permission before any app can listen to the microphone or watch the keyboard. Dictdotclick can't turn these on for you — only you can, in System Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)

                // Stated up front because it is the single most confusing
                // thing about Accessibility permission during development:
                // the grant is tied to the exact build that was approved, so
                // rebuilding in Xcode can silently revoke it.
                Text("Granting these is a one-time step. During development, rebuilding the app can reset Accessibility — if the hotkey stops working after a rebuild, come back here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            HStack {
                Text(permissions.allGranted
                     ? "Dictation arrives in Phase 4."
                     : "Nothing breaks if you grant these later — they're first used in Phases \(Permission.accessibility.neededByPhase) and \(Permission.microphone.neededByPhase).")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

#Preview {
    PermissionsWindow()
        .frame(width: 660, height: 560)
}
