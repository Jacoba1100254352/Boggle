// =============================================================
// Rules.swift – Rule definitions & engine
// =============================================================

import Foundation

// =============================================================
// GameContext: Supplies extra info to rules during validation.
// Holds the current grid and all words found so far.
// =============================================================
struct GameContext {
    let grid: [[BoggleTile]]
    let previousWords: Set<String>
    let minimumWordLength: Int
    let activePlayer: Player?
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
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        let minLen = context.minimumWordLength
        return word.count >= minLen ? .success() : .failure(reason: "Word must be at least \(minLen) letters")
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
// PathRule: Verifies the supplied path forms the requested word.
// Ensures tiles are adjacent, unique, and match the provided grid letters.
// =============================================================
struct PathRule: GameRule {
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        guard !path.isEmpty else { return .failure(reason: "Select letters from the board") }
        guard Set(path).count == path.count else { return .failure(reason: "Tiles cannot be reused") }

        var built = ""

        for index in path.indices {
            let current = path[index]

            if index > 0 {
                let previous = path[index - 1]
                guard abs(previous.row - current.row) <= 1 && abs(previous.col - current.col) <= 1 else {
                    return .failure(reason: "Letters must touch")
                }
            }

            guard context.grid.indices.contains(current.row),
                  context.grid[current.row].indices.contains(current.col) else {
                return .failure(reason: "Invalid tile selection")
            }

            built += context.grid[current.row][current.col].value
        }

        return built == word ? .success() : .failure(reason: "Selection does not match \(word.uppercased())")
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
