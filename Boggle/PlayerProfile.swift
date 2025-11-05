// =============================================================
// PlayerProfile.swift
// =============================================================

import Foundation

/// Represents a single player taking part in a round of Boggle.
/// Stores persisted preferences (like handicaps) as well as runtime state
/// (score and the list of words they've successfully submitted).
struct PlayerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Optional per-player minimum word length override. If `nil`, the
    /// global base minimum length is used instead. This enables handicaps.
    var minimumLengthOverride: Int?
    /// The score accumulated during the active round.
    var score: Int
    /// Words successfully found by this player in the current round.
    var words: [String]

    init(id: UUID = UUID(),
         name: String,
         minimumLengthOverride: Int? = nil,
         score: Int = 0,
         words: [String] = []) {
        self.id = id
        self.name = name
        self.minimumLengthOverride = minimumLengthOverride
        self.score = score
        self.words = words
    }

    /// Convenience helper that returns the effective minimum length once the
    /// global base value has been taken into account.
    func minimumLength(using base: Int) -> Int {
        max(2, minimumLengthOverride ?? base)
    }
}

extension Array where Element == PlayerProfile {
    /// Returns the index for the player with the provided identifier.
    func indexOfPlayer(id: PlayerProfile.ID) -> Int? {
        firstIndex { $0.id == id }
    }
}
