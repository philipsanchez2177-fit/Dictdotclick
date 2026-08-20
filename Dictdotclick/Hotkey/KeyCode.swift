//
//  KeyCode.swift
//  Dictdotclick
//
//  Phase 3 — the handful of raw key codes this app names.
//
//  macOS identifies keys by a number that reflects *physical position*, not
//  the character printed on the cap. Key code 50 is the key left of "1" on
//  every layout; whether it types ` or § depends on the keyboard. Positions
//  are what an app binds to, which is why these are constants rather than
//  characters.
//
//  Only keys the UI needs to name are listed. There is no value in a full
//  table — anything unnamed falls back to a readable placeholder.
//

import Foundation

enum KeyCode {
    static let backtick: UInt16 = 50
    static let escape: UInt16   = 53
    static let tab: UInt16      = 48
    static let returnKey: UInt16 = 36
    static let delete: UInt16   = 51
    static let space: UInt16    = 49
    static let capsLock: UInt16 = 57

    /// F1–F20. Not contiguous, and not in numeric order — the codes were
    /// assigned as Apple added keys to keyboards over the years.
    static let functionKeys: [UInt16: String] = [
        122: "F1",  120: "F2",  99: "F3",  118: "F4",
         96: "F5",   97: "F6",  98: "F7",  100: "F8",
        101: "F9",  109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16",
         64: "F17",  79: "F18",  80: "F19",  90: "F20",
    ]

    static func isFunctionKey(_ code: UInt16) -> Bool {
        functionKeys[code] != nil
    }

    /// A few common keys by name, so the recorder shows "Space" rather than
    /// an invisible character or a bare number.
    private static let named: [UInt16: String] = [
        backtick: "`", escape: "Escape", tab: "Tab",
        returnKey: "Return", delete: "Delete", space: "Space",
        capsLock: "Caps Lock",
        // Letters and digits, enough to describe a rejection clearly.
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
        34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O",
        35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V",
        13: "W", 7: "X", 16: "Y", 6: "Z",
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4",
        23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
    ]

    static func name(for code: UInt16) -> String {
        functionKeys[code] ?? named[code] ?? "Key \(code)"
    }
}
