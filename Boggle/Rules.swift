// =============================================================
// Rules.swift - Rule definitions, settings, and validation engine
// =============================================================

import Foundation

// =============================================================
// RuleOptions: Describes which toggle-style rules are enabled in the game.
// Uses OptionSet so the choices can be stored efficiently as a bitmask.
// =============================================================
struct RuleOptions: OptionSet, Equatable {
    let rawValue: Int

    static let minLength = RuleOptions(rawValue: 1 << 0)
    static let uniqueWords = RuleOptions(rawValue: 1 << 1)

    static let standard: RuleOptions = [.minLength, .uniqueWords]
}

// =============================================================
// BoardSize: Supported grid sizes for the game board.
// =============================================================
enum BoardSize: Int, CaseIterable, Identifiable {
    case four = 4
    case five = 5

    var id: Int { rawValue }

    var dimension: Int { rawValue }

    var title: String { "\(rawValue)x\(rawValue)" }

    var subtitle: String {
        switch self {
        case .four:
            return "Classic balance"
        case .five:
            return "More space, longer paths"
        }
    }
}

// =============================================================
// RoundDuration: Supported round timers in seconds.
// =============================================================
enum RoundDuration: Int, CaseIterable, Identifiable {
    case threeMinutes = 180
    case fiveMinutes = 300
    case sevenMinutes = 420

    var id: Int { rawValue }

    var seconds: Int { rawValue }

    var title: String { "\(rawValue / 60) min" }

    var subtitle: String {
        switch self {
        case .threeMinutes:
            return "Classic pace"
        case .fiveMinutes:
            return "More breathing room"
        case .sevenMinutes:
            return "Long-form round"
        }
    }
}

// =============================================================
// GameSettings: Aggregates the user's saved setup preferences.
// =============================================================
struct GameSettings: Equatable {
    var options: RuleOptions
    var minimumWordLength: Int
    var boardSize: BoardSize
    var roundDuration: RoundDuration

    static let classic = GameSettings(
        options: .standard,
        minimumWordLength: 3,
        boardSize: .four,
        roundDuration: .threeMinutes
    )

    var summaryText: String {
        let minimum = options.contains(.minLength)
            ? "\(minimumWordLength)-letter minimum"
            : "No minimum length"
        let unique = options.contains(.uniqueWords)
            ? "Unique words only"
            : "Repeated words allowed"
        return "\(boardSize.title) board / \(roundDuration.title) / \(minimum) / \(unique)"
    }

    var activeRuleCount: Int {
        var count = 0
        if options.contains(.minLength) { count += 1 }
        if options.contains(.uniqueWords) { count += 1 }
        return count
    }

    mutating func set(_ flag: RuleOptions, enabled: Bool) {
        if enabled {
            options.insert(flag)
        } else {
            options.remove(flag)
        }
    }
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
    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult
}

// MARK: - Concrete Rules

// =============================================================
// MinLengthRule: Ensures the word is at least a certain number of letters.
// =============================================================
struct MinLengthRule: GameRule {
    let minLen: Int

    func validate(word: String, path: [Position], context: GameContext) -> ValidationResult {
        word.count >= minLen ? .success() : .failure(reason: "Word must be at least \(minLen) letters")
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
// RuleEngine: Collects all enabled rules and checks each word.
// Calls each rule; if any rule fails, validation stops and fails fast.
// If a rule returns a score bonus, that is returned early as well.
// =============================================================
final class RuleEngine {
    var rules: [GameRule]

    init(_ rules: [GameRule]) {
        self.rules = rules
    }

    func evaluate(word: String, path: [Position], in ctx: GameContext) -> ValidationResult {
        for rule in rules {
            switch rule.validate(word: word, path: path, context: ctx) {
            case .success(let pts):
                if pts > 0 { return .success(score: pts) }
            case .failure(let why):
                return .failure(reason: why)
            }
        }
        return .success()
    }
}
