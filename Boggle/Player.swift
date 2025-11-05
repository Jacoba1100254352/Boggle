// =============================================================
// Player.swift
// =============================================================

import Foundation

/// Represents a player participating in the Boggle round.
/// Supports optional handicaps such as a personalised minimum
/// word length requirement.
struct Player: Identifiable, Codable, Hashable {
    typealias ID = UUID

    let id: UUID
    var name: String
    var score: Int
    /// Optional override for the minimum word length this player must meet.
    /// `nil` means the global rule applies.
    var minimumWordLengthOverride: Int?

    init(id: UUID = UUID(), name: String, score: Int = 0, minimumWordLengthOverride: Int? = nil) {
        self.id = id
        self.name = name
        self.score = score
        self.minimumWordLengthOverride = minimumWordLengthOverride
    }

    /// Display name used in the UI. Guarantees a non-empty string.
    var displayName: String { name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Player" : name }

    /// Returns the effective minimum word length taking the base rule into account.
    func minimumWordLength(default value: Int) -> Int {
        minimumWordLengthOverride ?? value
    }

    /// Returns a copy of the player with the provided score.
    func with(score newScore: Int) -> Player {
        Player(id: id, name: name, score: newScore, minimumWordLengthOverride: minimumWordLengthOverride)
    }
}
