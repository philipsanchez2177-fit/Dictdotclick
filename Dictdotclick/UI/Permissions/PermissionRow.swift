//
//  PermissionRow.swift
//  Dictdotclick
//
//  Phase 2 — one permission, its live status, and the one button that moves
//  it forward.
//
//  The button changes with the state rather than always saying the same
//  thing, because the two ungranted states have genuinely different remedies:
//  a first ask can show the system prompt, a refusal can only be undone in
//  System Settings.
//

import SwiftUI

struct PermissionRow: View {
    let permission: Permission
    let status: PermissionStatus
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: permission.systemImage)
                .font(.system(size: 22))
                .foregroundStyle(status.isGranted ? Color.green : Color.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(permission.title)
                        .font(.headline)
                    StatusBadge(status: status)
                }

                Text(permission.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !status.isGranted {
                    Text(permission.manualStep)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            actionButton
        }
        .padding(18)
        // Glass on the card, not the window background: floating elements get
        // the material by hand, backgrounds get it from the system.
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .granted:
            // Deliberately not a button. There is nothing useful to do to a
            // permission that is already granted, and offering an action
            // invites people to poke at something that is working.
            Label("Granted", systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityLabel("\(permission.title) granted")

        case .notDetermined:
            Button("Allow…", action: onRequest)
                .buttonStyle(.borderedProminent)

        case .denied:
            // No prompt is available any more, so send them where the switch
            // actually lives.
            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.bordered)
        }
    }
}

/// The coloured pill beside each permission name.
private struct StatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: .capsule)
    }

    private var text: String {
        switch status {
        case .granted:       return "ON"
        case .notDetermined: return "NOT ASKED"
        case .denied:        return "OFF"
        }
    }

    private var color: Color {
        switch status {
        case .granted:       return .green
        case .notDetermined: return .orange
        case .denied:        return .red
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        PermissionRow(permission: .microphone, status: .granted, onRequest: {}, onOpenSettings: {})
        PermissionRow(permission: .accessibility, status: .notDetermined, onRequest: {}, onOpenSettings: {})
        PermissionRow(permission: .accessibility, status: .denied, onRequest: {}, onOpenSettings: {})
    }
    .padding()
    .frame(width: 620)
}
