//
//  TranscriptPostProcessor.swift
//  Dictdotclick
//
//  Phase 7 — everything that happens to a transcript between the engine and
//  the focused app.
//
//  Two passes, in this order:
//
//    1. Filler cleanup  — drop "um", "uh", "erm" and tidy what's left.
//    2. Snippet expansion — swap a spoken trigger for stored text.
//
//  Cleanup runs first for two reasons. A filler word inside a spoken trigger
//  ("my, uh, address") would otherwise stop the snippet matching; and running
//  it second would let it rewrite the *inserted* text, which the user typed
//  by hand and did not ask to have edited.
//
//  Matching is done on word boundaries with punctuation and capitalisation
//  ignored, because a transcript is punctuated prose: a trigger stored as
//  "my address" has to match "My address." without the user thinking about it.
//
//  Pure functions over strings — no engine, no disk, no UI. That is
//  deliberate: this is the part most likely to be subtly wrong, and it can be
//  reasoned about (and later tested) in isolation.
//

import Foundation

enum TranscriptPostProcessor {

    /// Words removed when cleanup is on.
    ///
    /// Deliberately short and unambiguous. "like", "so" and "you know" are
    /// real words far more often than they are filler, and an app that eats
    /// them is an app that quietly changes what you said.
    static let fillerWords: Set<String> = [
        "um", "umm", "uhm", "uh", "uhh", "er", "erm", "hmm", "mmm", "mhm"
    ]

    /// The whole pipeline. `text` in, deliverable text out.
    static func apply(to text: String, snippets: [Snippet], removeFillers: Bool) -> String {
        var result = text
        if removeFillers {
            result = strippingFillers(from: result)
        }
        result = expanding(result, with: snippets)
        return result
    }

    // MARK: - Filler cleanup

    static func strippingFillers(from text: String) -> String {
        let fillers = wordRanges(in: text).filter {
            fillerWords.contains(normalized(String(text[$0])))
        }
        guard !fillers.isEmpty else { return text }

        // Built by copying the gaps between the filler words rather than by
        // deleting from the original. Nothing is mutated while its own
        // positions are still being used, which is the way this kind of code
        // usually goes wrong.
        var result = ""
        var cursor = text.startIndex
        for range in fillers {
            result.append(contentsOf: text[cursor ..< range.lowerBound])
            cursor = range.upperBound
        }
        result.append(contentsOf: text[cursor...])

        return restoringLeadingCapital(of: tidied(result), matching: text)
    }

    /// Removing an opening "Um," leaves the sentence starting on a lower-case
    /// word. Restores the capital when the original had one, so cleanup does
    /// not visibly damage the first word of every tidied sentence.
    private static func restoringLeadingCapital(of text: String, matching original: String) -> String {
        guard let originalFirst = original.first(where: { $0.isLetter }), originalFirst.isUppercase,
              let firstIndex = text.firstIndex(where: { $0.isLetter }),
              text[firstIndex].isLowercase
        else { return text }

        var result = text
        result.replaceSubrange(firstIndex ... firstIndex,
                               with: String(text[firstIndex]).uppercased())
        return result
    }

    // MARK: - Snippets

    static func expanding(_ text: String, with snippets: [Snippet]) -> String {
        // Longest trigger first, so "my work address" is not swallowed by
        // "my address" — the more specific phrase should win.
        let active = snippets
            .filter(\.isUsable)
            .sorted { triggerWords($0).count > triggerWords($1).count }
        guard !active.isEmpty else { return text }

        var result = text
        // Scanning resumes past each insertion, so an expansion containing
        // its own trigger cannot loop forever. The counter is a second belt
        // for the same braces.
        var searchStart = result.startIndex
        var replacements = 0

        while replacements < 200 {
            let words = wordRanges(in: result).filter { $0.lowerBound >= searchStart }
            let forms = words.map { normalized(String(result[$0])) }
            var matched = false

            search: for start in words.indices {
                for snippet in active {
                    let trigger = triggerWords(snippet)
                    guard !trigger.isEmpty, start + trigger.count <= words.count else { continue }
                    guard Array(forms[start ..< (start + trigger.count)]) == trigger else { continue }

                    let range = words[start].lowerBound ..< words[start + trigger.count - 1].upperBound
                    let resumeOffset = result.distance(from: result.startIndex, to: range.lowerBound)
                        + snippet.expansion.count
                    result.replaceSubrange(range, with: snippet.expansion)
                    searchStart = result.index(result.startIndex, offsetBy: resumeOffset)
                    matched = true
                    replacements += 1
                    break search
                }
            }

            if !matched { break }
        }

        return result
    }

    private static func triggerWords(_ snippet: Snippet) -> [String] {
        wordRanges(in: snippet.trigger).map { normalized(String(snippet.trigger[$0])) }
    }

    // MARK: - Words

    /// The ranges of the words in a string — a word being a run of letters,
    /// digits or apostrophes. Everything else (spaces, commas, full stops) is
    /// a separator, which is what makes "address." match "address".
    static func wordRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var start: String.Index?
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            let isWord = character.isLetter || character.isNumber
                || character == "'" || character == "\u{2019}"
            if isWord {
                if start == nil { start = index }
            } else if let began = start {
                ranges.append(began ..< index)
                start = nil
            }
            index = text.index(after: index)
        }
        if let began = start { ranges.append(began ..< text.endIndex) }
        return ranges
    }

    /// Comparison form of a word: lower-cased, apostrophes dropped, so
    /// "Dont" and "don't" are the same word to a trigger.
    static func normalized(_ word: String) -> String {
        word.lowercased().filter { $0 != "'" && $0 != "\u{2019}" }
    }

    // MARK: - Tidying

    /// Repairs the damage removing a word does to the text around it:
    /// doubled spaces, a space left sitting before a comma, and a sentence
    /// that now starts with the punctuation that used to follow the filler.
    static func tidied(_ text: String) -> String {
        var out = ""
        var lastWasSpace = false
        for character in text {
            if character == " " || character == "\t" {
                if lastWasSpace { continue }
                lastWasSpace = true
                out.append(" ")
            } else {
                // A space immediately before punctuation is always wrong.
                if lastWasSpace, ",.!?;:)".contains(character) {
                    out.removeLast()
                }
                lastWasSpace = false
                out.append(character)
            }
        }

        // Leading punctuation left behind by a removed opening filler
        // ("Um, hello" becoming ", hello").
        while let first = out.first, first == " " || ",.!?;:".contains(first) {
            out.removeFirst()
        }

        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
