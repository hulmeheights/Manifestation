//
//  Phrase.swift
//  Lumen
//
//  Comparing what was typed against what was meant. Forgiving about case,
//  punctuation and spacing — the point is the writing, not the proofreading.
//

import Foundation

enum Phrase {

    /// Lowercased, punctuation stripped, split on anything non-alphanumeric.
    static func words(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// How many leading words of `typed` exactly match `target`.
    static func matchedCount(typed: String, target: String) -> Int {
        let a = words(typed)
        let b = words(target)
        var count = 0
        while count < a.count, count < b.count, a[count] == b[count] {
            count += 1
        }
        return count
    }

    static func isComplete(typed: String, target: String) -> Bool {
        !target.isEmpty && words(typed) == words(target)
    }

    /// True while what's been typed is still a valid beginning of the target,
    /// including a half-finished final word. Drives the "you're on track" tint.
    static func isOnTrack(typed: String, target: String) -> Bool {
        let a = words(typed)
        let b = words(target)
        guard !a.isEmpty else { return true }
        guard a.count <= b.count else { return false }

        for index in 0..<(a.count - 1) where a[index] != b[index] {
            return false
        }

        let lastIndex = a.count - 1
        // The final word may still be mid-typing, so a prefix is enough —
        // unless the user has already typed a separator after it.
        let endedWord = typed.last.map { !$0.isLetter && !$0.isNumber } ?? false
        return endedWord ? a[lastIndex] == b[lastIndex] : b[lastIndex].hasPrefix(a[lastIndex])
    }

    /// The target split for display, keeping original punctuation, with a
    /// running count of how many normalised words each token accounts for.
    struct Token: Identifiable {
        let id: Int
        let text: String
        /// Number of normalised words covered once this token is complete.
        let cumulative: Int
    }

    static func tokens(_ target: String) -> [Token] {
        let pieces = target
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var running = 0
        return pieces.enumerated().map { index, piece in
            running += words(piece).count
            return Token(id: index, text: piece, cumulative: running)
        }
    }
}
