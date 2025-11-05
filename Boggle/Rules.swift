// =============================================================
// Rules.swift – Rule definitions & engine
// =============================================================

import Foundation

// =============================================================
// RuleOptions: Describes which rules are enabled in the game.
// Uses OptionSet so you can combine multiple rule flags efficiently (bitmasking).
// Persisted by @AppStorage so user's rule choices save between runs.
// =============================================================
struct RuleOptions: OptionSet {
    let rawValue: Int
    // Rule: Words must have a minimum length
    static let minLength     = RuleOptions(rawValue: 1 << 0)
    // Rule: Each word can only be played once
    static let uniqueWords   = RuleOptions(rawValue: 1 << 1)
    // Shortcut for all rules enabled
    static let all: RuleOptions = [.minLength, .uniqueWords]
}

// =============================================================
// GameContext: Supplies extra info to rules during validation.
// Holds the current grid and all words found so far.
// =============================================================
struct GameContext {
    let grid: [[String]]
    let previousWords: Set<String>
}

// =============================================================
// ValidationResult: Tells if a word passed a rule or not.
// .success optionally returns a score bonus; .failure has a reason message.
// =============================================================
enum ValidationResult {
    case success(score: Int = 0)
    case failure(reason: String)
}

// =============================================================
// GameRule protocol: All game rules implement this.
// A rule checks if a word is valid in a specific way.
// =============================================================
protocol GameRule {
    // Returns .success or .failure for a word, given its tile path and context.
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult
}

// MARK: – Concrete Rules

// =============================================================
// MinLengthRule: Ensures the word is at least a certain number of letters.
// =============================================================
struct MinLengthRule: GameRule {
    let minLen: Int
    let owner: String?
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        guard word.count >= minLen else {
            if let owner {
                return .failure(reason: "\(owner) must play words at least \(minLen) letters long")
            }
            return .failure(reason: "Word must be at least \(minLen) letters")
        }
        return .success()
    }
}

// =============================================================
// UniqueWordRule: Ensures the word hasn't been used already.
// =============================================================
struct UniqueWordRule: GameRule {
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        context.previousWords.contains(word) ? .failure(reason: "Word already played") : .success()
    }
}

// =============================================================
// PathMatchesWordRule: Verifies the submitted word follows a valid path
// on the board and that the entered word matches the selected tiles.
// =============================================================
struct PathMatchesWordRule: GameRule {
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        guard !path.isEmpty else {
            return .failure(reason: "Select letters on the board first")
        }

        // Ensure every position is on the board.
        for pos in path {
            guard context.grid.indices.contains(pos.row),
                  context.grid[pos.row].indices.contains(pos.col) else {
                return .failure(reason: "Selection contains an invalid tile")
            }
        }

        // Ensure no die is reused.
        if Set(path).count != path.count {
            return .failure(reason: "You can't reuse the same die")
        }

        // Ensure each step is adjacent (including diagonals).
        for (first, second) in zip(path, path.dropFirst()) {
            let dRow = abs(first.row - second.row)
            let dCol = abs(first.col - second.col)
            guard dRow <= 1 && dCol <= 1 else {
                return .failure(reason: "Letters must be adjacent")
            }
        }

        // Ensure the selected letters match the submitted word.
        let assembled = path.map { context.grid[$0.row][$0.col].lowercased() }.joined()
        guard assembled == word else {
            return .failure(reason: "Selected letters don't match the word")
        }

        return .success()
    }
}

// =============================================================
// RuleEngine: Collects all enabled rules and checks each word.
// Calls each rule; if any rule fails, validation stops and fails fast.
// If a rule returns a score bonus, that is returned early as well.
// =============================================================
final class RuleEngine {
    var rules: [GameRule]
    // Initialize with a list of rules (can be empty or many)
    init(_ rules: [GameRule]) { self.rules = rules }

    // Calls 'validate' for each rule in order
    func evaluate(word: String, path: [Position], in ctx: GameContext) -> ValidationResult {
        for rule in rules {
            switch rule.validate(word: word, path: path, context: ctx) {
            case .success(let pts):
                // If a rule gives bonus points, return early with that bonus
                if pts > 0 { return .success(score: pts) }
            case .failure(let why):
                // If a rule fails, return the failure reason immediately
                return .failure(reason: why)
            }
        }
        // If all rules pass (and no bonuses), return .success
        return .success()
    }
}
