//
//  HotkeyBinding.swift
//  Dictdotclick
//
//  Phase 3 — what a hotkey *is*, and which ones are legal.
//
//  BUILD-SPEC decision 6: no bare character keys, because an app that claims
//  one makes that key untypable everywhere, forever. Three shapes are allowed:
//
//    • a combo containing at least one modifier      ⌃⌥D
//    • a standalone function-row key                 F13
//    • a double-tap of `                             `` (the named exception)
//
//  This file is pure data and pure logic — no AppKit, no event taps. That is
//  deliberate: the rules are the part most likely to be wrong, and keeping
//  them free of system calls means they can be reasoned about (and later
//  tested) on their own.
//

import Foundation
import CoreGraphics

/// A key the user can bind dictation to.
enum HotkeyBinding: Codable, Equatable, Hashable {
    /// A modifier combination, e.g. ⌃⌥D. `modifiers` is never empty.
    case combo(keyCode: UInt16, modifiers: UInt64)
    /// A function-row key pressed on its own, e.g. F13.
    case functionKey(keyCode: UInt16)
    /// Two quick presses of a key that would otherwise type a character.
    /// Only `` ` `` is permitted — see `isDoubleTappable`.
    case doubleTap(keyCode: UInt16)

    /// Ships as the out-of-box default (decision 6, settled 2026-08-19).
    static let `default` = HotkeyBinding.doubleTap(keyCode: KeyCode.backtick)

    var keyCode: UInt16 {
        switch self {
        case .combo(let k, _), .functionKey(let k), .doubleTap(let k): return k
        }
    }

    /// The modifier flags this binding requires, as `CGEventFlags`.
    var flags: CGEventFlags {
        switch self {
        case .combo(_, let raw): return CGEventFlags(rawValue: raw)
        case .functionKey, .doubleTap: return []
        }
    }

    /// Human-readable form for the UI, e.g. "⌃⌥D" or "` `" (double-tap).
    var displayString: String {
        switch self {
        case .combo(let key, let raw):
            return CGEventFlags(rawValue: raw).symbolString + KeyCode.name(for: key)
        case .functionKey(let key):
            return KeyCode.name(for: key)
        case .doubleTap(let key):
            return "\(KeyCode.name(for: key)) \(KeyCode.name(for: key))"
        }
    }

    /// Extra line under the field, so a double-tap doesn't look like a typo.
    var displayHint: String? {
        switch self {
        case .doubleTap: return "Press twice, quickly"
        case .combo, .functionKey: return nil
        }
    }
}

// MARK: - Validation

/// Why a key press was refused. Each case carries what to tell the user —
/// a rejection with no explanation reads as a broken recorder.
enum HotkeyRejection: Equatable {
    case bareCharacterKey(name: String)
    case modifiersOnly
    case reserved(name: String)

    var message: String {
        switch self {
        case .bareCharacterKey(let name):
            return "\(name) on its own would stop you typing \(name) anywhere else. Add ⌘, ⌥, ⌃, or ⇧ — or use a function key."
        case .modifiersOnly:
            return "That's only modifier keys. Hold them and press one more key."
        case .reserved(let name):
            return "\(name) is reserved by macOS. Pick something else."
        }
    }
}

enum HotkeyValidator {
    /// Keys macOS owns outright. Binding these would either fail silently or
    /// break something the user needs more than dictation.
    private static let reserved: Set<UInt16> = [
        KeyCode.escape, KeyCode.tab, KeyCode.returnKey, KeyCode.delete,
        KeyCode.space, KeyCode.capsLock,
    ]

    /// Decides what a recorded key press should become — or why it can't be
    /// used. `.doubleTap` is only offered for keys in `isDoubleTappable`.
    static func binding(forKeyCode keyCode: UInt16, flags: CGEventFlags) -> Result<HotkeyBinding, HotkeyRejection> {
        let modifiers = flags.deviceIndependent

        if reserved.contains(keyCode), modifiers.isEmpty {
            return .failure(.reserved(name: KeyCode.name(for: keyCode)))
        }

        // A combo: at least one modifier plus a real key.
        if !modifiers.isEmpty {
            return .success(.combo(keyCode: keyCode, modifiers: modifiers.rawValue))
        }

        // Bare key. Only two kinds are acceptable on their own.
        if KeyCode.isFunctionKey(keyCode) {
            return .success(.functionKey(keyCode: keyCode))
        }
        if isDoubleTappable(keyCode) {
            return .success(.doubleTap(keyCode: keyCode))
        }

        return .failure(.bareCharacterKey(name: KeyCode.name(for: keyCode)))
    }

    /// The double-tap exception, deliberately narrow.
    ///
    /// Backtick only. Widening this is a real decision, not a convenience:
    /// every double-tappable key pays a ~200 ms delay on its normal use, and
    /// that is only tolerable for a key most people press rarely.
    static func isDoubleTappable(_ keyCode: UInt16) -> Bool {
        keyCode == KeyCode.backtick
    }
}

// MARK: - Flags

extension CGEventFlags {
    /// Just the four modifiers a user can meaningfully bind, with the
    /// left/right and hardware bits stripped. Without this, ⌃ pressed on the
    /// left would not match ⌃ pressed on the right.
    var deviceIndependent: CGEventFlags {
        intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift])
    }

    /// Symbols in the order macOS shows them in menus.
    var symbolString: String {
        var out = ""
        if contains(.maskControl)   { out += "⌃" }
        if contains(.maskAlternate) { out += "⌥" }
        if contains(.maskShift)     { out += "⇧" }
        if contains(.maskCommand)   { out += "⌘" }
        return out
    }
}
