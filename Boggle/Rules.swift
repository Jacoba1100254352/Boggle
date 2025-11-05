// =============================================================
// Rules.swift – Rule definitions & engine
// =============================================================

import Foundation

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
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        guard word.count >= minLen else {
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
// PathContinuityRule: Ensures the selected tiles form a continuous, non-repeating path.
// =============================================================
struct PathContinuityRule: GameRule {
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        guard !path.isEmpty else { return .failure(reason: "Select tiles to form a word") }
        var visited = Set<Position>()
        var previous: Position?
        for pos in path {
            guard !visited.contains(pos) else { return .failure(reason: "Tiles cannot be reused in a single word") }
            if let prev = previous {
                let rowDelta = abs(prev.row - pos.row)
                let colDelta = abs(prev.col - pos.col)
                guard rowDelta <= 1 && colDelta <= 1 else {
                    return .failure(reason: "Tiles must touch horizontally, vertically, or diagonally")
                }
            }
            visited.insert(pos)
            previous = pos
        }
        return .success()
    }
}

// =============================================================
// PathWordMatchRule: Ensures the chosen path spells the submitted word,
// properly accounting for digraph tiles such as "Qu".
// =============================================================
struct PathWordMatchRule: GameRule {
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        var built = ""
        for pos in path {
            guard pos.row >= 0, pos.row < context.grid.count else { return .failure(reason: "Selection outside of grid") }
            let row = context.grid[pos.row]
            guard pos.col >= 0, pos.col < row.count else { return .failure(reason: "Selection outside of grid") }
            built += row[pos.col]
        }
        return built.lowercased() == word ? .success() : .failure(reason: "Selected tiles spell \(built.uppercased()), not \(word.uppercased())")
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
