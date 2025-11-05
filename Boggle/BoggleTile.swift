// =============================================================
// BoggleTile.swift
// =============================================================

import Foundation

/// Represents a single die face on the Boggle grid.
/// Handles special faces such as "Qu" that occupy one cube
/// but count as two letters when forming a word.
struct BoggleTile: Hashable {
    /// Text shown to the user (e.g. "A" or "Qu").
    let text: String
    /// The lowercase value contributed to a word (e.g. "a" or "qu").
    let value: String

    init(face: String) {
        let trimmed = face.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("qu") == .orderedSame {
            text = "Qu"
            value = "qu"
        } else {
            text = trimmed.uppercased()
            value = trimmed.lowercased()
        }
    }
}
