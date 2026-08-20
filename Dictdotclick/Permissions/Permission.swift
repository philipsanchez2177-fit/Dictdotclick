//
//  Permission.swift
//  Dictdotclick
//
//  Phase 2 — the two macOS permissions this app cannot work without.
//
//  Kept as an enum so the walkthrough, the status checks, and the deep links
//  can never drift apart: adding a case forces every switch over it to be
//  updated.
//

import Foundation

enum Permission: String, CaseIterable, Identifiable, Hashable {
    /// Required to hear anything at all.
    case microphone
    /// Required BOTH to watch for the hotkey app-wide and to type the
    /// transcript into another app. One switch, two features — which is why
    /// there is no lighter-weight version of this app that avoids it.
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .microphone:    return "Microphone"
        case .accessibility: return "Accessibility"
        }
    }

    var systemImage: String {
        switch self {
        case .microphone:    return "mic"
        case .accessibility: return "accessibility"
        }
    }

    /// Plain-English reason, shown in the walkthrough. Users are far more
    /// likely to grant a permission when told what it buys them.
    var reason: String {
        switch self {
        case .microphone:
            return "So Dictdotclick can hear you. Audio is transcribed on this Mac and never leaves it."
        case .accessibility:
            return "So Dictdotclick can notice your hotkey in any app, and type the transcript where you're working."
        }
    }

    /// What the user has to do once System Settings opens. Deep links land on
    /// the right pane but cannot flip the switch, so the last step is manual.
    var manualStep: String {
        switch self {
        case .microphone:
            return "Turn on the switch next to Dictdotclick."
        case .accessibility:
            return "Find Dictdotclick in the list and turn it on. If it's already listed but won't stay on, select it, click \u{2212} to remove it, then use Request Access."
        }
    }

    /// Deep link into the correct System Settings pane.
    ///
    /// `x-apple.systempreferences:` is Apple's URL scheme for this. It is not
    /// formally documented, so treat a link that stops working as a macOS
    /// change rather than a bug here — `PermissionsModel.openSystemSettings`
    /// falls back to opening System Settings at its top level.
    var systemSettingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
        }
    }

    /// Which build phase actually starts using this permission. Shown so the
    /// walkthrough is honest that nothing breaks if it is granted later.
    var neededByPhase: Int {
        switch self {
        case .microphone:    return 4
        case .accessibility: return 3
        }
    }
}

/// Where a single permission currently stands.
///
/// `notDetermined` is a genuinely distinct state from `denied`, not a
/// nicety: the system will show its own prompt exactly once, on first ask.
/// After a denial that prompt never appears again and the only route is
/// System Settings. The walkthrough offers a different button for each.
enum PermissionStatus: Equatable {
    case notDetermined
    case granted
    case denied

    var isGranted: Bool { self == .granted }
}
