// =============================================================
// RuleConfiguration.swift
// =============================================================

import Foundation

/// Represents a named handicap configuration for a specific player.
/// Each handicap can override certain rule values from the base configuration.
struct PlayerHandicap: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// Custom minimum word length that applies only when this player is active.
    var minWordLength: Int
    /// Optional custom round duration (in seconds). Falls back to the base duration when nil.
    var roundDuration: Int?

    init(id: UUID = UUID(), name: String, minWordLength: Int, roundDuration: Int? = nil) {
        self.id = id
        self.name = name
        self.minWordLength = minWordLength
        self.roundDuration = roundDuration
    }
}

/// Stores the mutable rule configuration for the Boggle game.
/// The configuration is persisted using `AppStorage` so that user preferences
/// survive between launches of the application.
struct RuleConfiguration: Codable, Equatable {
    /// Base minimum word length (applies when no handicap overrides it).
    var baseMinWordLength: Int = 3
    /// Whether duplicate submissions are disallowed.
    var requireUniqueWords: Bool = true
    /// The duration of a round, in seconds.
    var roundDuration: Int = 180
    /// Size of the board (4 for classic, 5 for Big Boggle style).
    var boardSize: Int = 4
    /// Collection of named handicaps for individual players.
    var handicaps: [PlayerHandicap] = []

    static let `default` = RuleConfiguration()
}
