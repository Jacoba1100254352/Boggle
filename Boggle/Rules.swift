// =============================================================
// Rules.swift – Shared configuration & dice definitions
// =============================================================

import Foundation

/// Encapsulates the configurable global rules for a round of Boggle.
struct GameSettings: Codable, Equatable {
    /// Number of seconds on the round timer.
    var roundLength: Int = 180
    /// Minimum length a word must reach in order to score.
    var minimumWordLength: Int = 3
    /// When `true` all players share a global "one and done" word pool.
    var enforceUniqueWords: Bool = true
    /// When `true` the UI highlights the most recently validated path on the grid.
    var highlightLastWord: Bool = true
}

/// Describes an individual player's preferences and handicaps.
struct PlayerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Optional player-specific override for the minimum word length requirement.
    var minWordLengthOverride: Int?

    init(id: UUID = UUID(), name: String, minWordLengthOverride: Int? = nil) {
        self.id = id
        self.name = name
        self.minWordLengthOverride = minWordLengthOverride
    }
}

/// Mutable state tracked for each player during an active round.
struct PlayerState: Identifiable, Equatable {
    var profile: PlayerProfile
    var score: Int = 0
    var words: [String] = []

    var id: UUID { profile.id }

    /// Convenience accessor returning either the player override or `nil`.
    var minimumWordLengthOverride: Int? { profile.minWordLengthOverride }

    /// Resets per-round bookkeeping while preserving the player's identity.
    mutating func resetForNewRound() {
        score = 0
        words.removeAll(keepingCapacity: true)
    }
}

extension Array where Element == PlayerState {
    /// Returns the maximum score amongst all players (or zero if empty).
    func highestScore() -> Int {
        map(\.score).max() ?? 0
    }
}

/// Represents a single physical die used to generate the grid.
struct BoggleDie {
    let faces: [String]

    func randomFace() -> String { faces.randomElement() ?? "" }
}

/// Provides factory helpers for classic Boggle dice sets.
enum BoggleDice {
    /// Classic 4×4 Boggle dice faces sourced from Hasbro's 2008 rulebook.
    static let classic4x4: [BoggleDie] = [
        BoggleDie(faces: ["A", "A", "E", "E", "G", "N"]),
        BoggleDie(faces: ["E", "L", "R", "T", "T", "Y"]),
        BoggleDie(faces: ["A", "O", "O", "T", "T", "W"]),
        BoggleDie(faces: ["A", "B", "B", "J", "O", "O"]),
        BoggleDie(faces: ["E", "H", "R", "T", "V", "W"]),
        BoggleDie(faces: ["C", "I", "M", "O", "T", "U"]),
        BoggleDie(faces: ["D", "I", "S", "T", "T", "Y"]),
        BoggleDie(faces: ["E", "I", "O", "S", "S", "T"]),
        BoggleDie(faces: ["D", "E", "L", "R", "V", "Y"]),
        BoggleDie(faces: ["A", "C", "H", "O", "P", "S"]),
        BoggleDie(faces: ["H", "I", "M", "N", "Qu", "U"]),
        BoggleDie(faces: ["E", "E", "I", "N", "S", "U"]),
        BoggleDie(faces: ["E", "E", "G", "H", "N", "W"]),
        BoggleDie(faces: ["A", "F", "F", "K", "P", "S"]),
        BoggleDie(faces: ["H", "L", "N", "N", "R", "Z"]),
        BoggleDie(faces: ["D", "E", "I", "L", "R", "X"])
    ]

    /// Generates a randomised grid using the classic 4×4 dice.
    static func classicBoard() -> [[String]] {
        let shuffledDice = classic4x4.shuffled()
        var faces: [String] = shuffledDice.map { $0.randomFace() }
        // Convert the flattened array into a 4×4 matrix.
        var grid: [[String]] = []
        for row in 0..<4 {
            let start = row * 4
            let end = start + 4
            grid.append(Array(faces[start..<end]))
        }
        return grid
    }
}

/// Default player roster used when the user has not configured any players yet.
let defaultPlayers: [PlayerProfile] = [
    PlayerProfile(name: "Player 1")
]

/// Default game settings used for brand-new installations.
let defaultSettings = GameSettings()
