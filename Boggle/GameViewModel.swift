// =============================================================
// GameViewModel.swift
// =============================================================

import Combine
import SwiftUI

// UserMessage: A simple structure to hold messages for the user (e.g., errors or alerts).
// Conforms to Identifiable so it can be used for SwiftUI alerts, and Equatable for comparisons.
struct UserMessage: Identifiable, Equatable {
    let id = UUID() // Unique identifier for SwiftUI
    let message: String // The actual message to show
}

/// Stores a single scoring event so the UI can present a round history.
struct WordEntry: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let playerName: String
    let points: Int
}

// =============================================================
// GameViewModel: Core logic and state-holder for the Boggle game.
// Handles game state, rules, timer, score, and dictionary lookups.
// MainActor: Ensures updates happen on the main/UI thread.
// =============================================================
@MainActor final class GameViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published var grid: [[BoggleTile]] = []
    @Published var currentWord = ""
    @Published var wordLog: [WordEntry] = []
    @Published var timeRemaining: Int
    @Published var configuration: RuleConfiguration
    @Published var players: [Player]
    @Published var activePlayerID: Player.ID
    @Published var userMessage: UserMessage? = nil
    @Published var isRoundActive = false
    @Published var highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)

    // MARK: - Private helpers
    private var timer: AnyCancellable?
    private var dictionary = Set<String>()
    private var ruleEngine: RuleEngine
    private var playedWords = Set<String>()

    private static let configKey = "ruleConfiguration"
    private static let playersKey = "playersConfiguration"
    private static let highScoreKey = "HighScore"

    // Classic 4x4 Boggle dice (1992 edition) for authentic gameplay.
    private let dice: [[String]] = [
        ["A", "A", "E", "E", "G", "N"],
        ["A", "B", "B", "J", "O", "O"],
        ["A", "C", "H", "O", "P", "S"],
        ["A", "F", "F", "K", "P", "S"],
        ["A", "O", "O", "T", "T", "W"],
        ["C", "I", "M", "O", "T", "U"],
        ["D", "E", "I", "L", "R", "X"],
        ["D", "E", "L", "R", "V", "Y"],
        ["D", "I", "S", "T", "T", "Y"],
        ["E", "E", "G", "H", "N", "W"],
        ["E", "E", "I", "N", "S", "U"],
        ["E", "H", "R", "T", "V", "W"],
        ["E", "I", "O", "S", "S", "T"],
        ["E", "L", "R", "T", "T", "Y"],
        ["H", "I", "M", "N", "QU", "U"],
        ["H", "L", "N", "N", "R", "Z"]
    ]

    // MARK: - Init (setup)
    init() {
        configuration = Self.loadConfiguration()
        players = Self.loadPlayers()
        if players.isEmpty {
            players = [Player(name: "Player 1")]
        }
        activePlayerID = players.first!.id
        timeRemaining = configuration.roundDuration
        ruleEngine = RuleEngine([])

        rebuildRules()
        loadDictionary()
    }

    // MARK: - Persistence helpers
    private static func loadConfiguration() -> RuleConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(RuleConfiguration.self, from: data) else {
            return RuleConfiguration()
        }
        return config.clamped()
    }

    private func persistConfiguration() {
        guard let data = try? JSONEncoder().encode(configuration.clamped()) else { return }
        UserDefaults.standard.set(data, forKey: Self.configKey)
    }

    private static func loadPlayers() -> [Player] {
        guard let data = UserDefaults.standard.data(forKey: playersKey),
              let stored = try? JSONDecoder().decode([Player].self, from: data) else {
            return []
        }
        // Reset scores when loading a new session to avoid carrying over previous rounds.
        return stored.map { Player(id: $0.id, name: $0.name, score: 0, minimumWordLengthOverride: $0.minimumWordLengthOverride) }
    }

    private func persistPlayers() {
        guard let data = try? JSONEncoder().encode(players) else { return }
        UserDefaults.standard.set(data, forKey: Self.playersKey)
    }

    // MARK: - Game control (main game logic)
    func startGame() {
        timer?.cancel()
        generateGrid()
        resetRound()
        startTimer()
        isRoundActive = true
    }

    func resetRound() {
        currentWord = ""
        wordLog.removeAll()
        playedWords.removeAll()
        timeRemaining = configuration.roundDuration
        isRoundActive = false
        players = players.map { $0.with(score: 0) }
        persistPlayers()
    }

    func submitWord(selectedLetters: [Position]) {
        guard isRoundActive else {
            userMessage = UserMessage(message: "Start a round to submit words")
            return
        }

        let trimmed = currentWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let word = trimmed.lowercased()

        guard var activePlayer = players.first(where: { $0.id == activePlayerID }) else {
            userMessage = UserMessage(message: "Please add a player")
            return
        }

        let path: [Position]
        if selectedLetters.isEmpty {
            guard let resolved = findPath(for: word) else {
                userMessage = UserMessage(message: "\(trimmed.uppercased()) is not on the board")
                return
            }
            path = resolved
        } else {
            path = selectedLetters
        }

        let ctx = GameContext(
            grid: grid,
            previousWords: playedWords,
            minimumWordLength: activePlayer.minimumWordLength(default: configuration.minimumWordLength),
            activePlayer: activePlayer
        )

        switch ruleEngine.evaluate(word: word, path: path, in: ctx) {
        case .success:
            guard dictionary.contains(word) else {
                userMessage = UserMessage(message: "Not in dictionary")
                return
            }
            let points = calculateScore(for: word)
            if let index = players.firstIndex(where: { $0.id == activePlayer.id }) {
                activePlayer = players[index]
                players[index].score += points
                if players[index].score > highScore {
                    highScore = players[index].score
                    UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
                }
            }
            playedWords.insert(word)
            wordLog.insert(WordEntry(word: trimmed.uppercased(), playerName: activePlayer.displayName, points: points), at: 0)
        case .failure(let why):
            userMessage = UserMessage(message: why)
        }

        currentWord = ""
    }

    // MARK: - Rule & settings updates
    func updateConfiguration(_ newConfiguration: RuleConfiguration) {
        configuration = newConfiguration.clamped()
        persistConfiguration()
        rebuildRules()
        if !isRoundActive {
            timeRemaining = configuration.roundDuration
        }
    }

    func updatePlayers(_ updatedPlayers: [Player]) {
        let filtered = updatedPlayers.isEmpty ? [Player(name: "Player 1")] : updatedPlayers
        players = filtered
        if !players.contains(where: { $0.id == activePlayerID }) {
            activePlayerID = players.first!.id
        }
        persistPlayers()
    }

    func addPlayer() {
        let nextNumber = players.count + 1
        players.append(Player(name: "Player \(nextNumber)"))
        persistPlayers()
    }

    func removePlayers(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        if players.isEmpty {
            players = [Player(name: "Player 1")]
        }
        if !players.contains(where: { $0.id == activePlayerID }) {
            activePlayerID = players.first!.id
        }
        persistPlayers()
    }

    // MARK: - Utility
    private func loadDictionary() {
        guard let path = Bundle.main.path(forResource: "dictionary", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else { return }
        dictionary = Set(content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }

    private func generateGrid() {
        var shuffledDice = dice.shuffled()
        var newGrid: [[BoggleTile]] = []
        for row in 0..<4 {
            var rowTiles: [BoggleTile] = []
            for col in 0..<4 {
                let die = shuffledDice.removeFirst()
                let face = die.randomElement() ?? ""
                rowTiles.append(BoggleTile(face: face))
            }
            newGrid.append(rowTiles)
        }
        grid = newGrid
    }

    private func calculateScore(for word: String) -> Int {
        switch word.count {
        case 0...2: return 0
        case 3, 4: return 1
        case 5: return 2
        case 6: return 3
        case 7: return 5
        default: return 11
        }
    }

    // MARK: - Timer logic
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            timer?.cancel()
            if isRoundActive {
                isRoundActive = false
                userMessage = UserMessage(message: "Time's up!")
            }
            return
        }
        timeRemaining -= 1
    }

    // MARK: - Path helpers
    private func findPath(for word: String) -> [Position]? {
        guard !word.isEmpty else { return nil }
        for row in grid.indices {
            for col in grid[row].indices {
                var visited: Set<Position> = []
                let start = Position(row: row, col: col)
                if let result = search(from: start, target: word, visited: &visited, index: word.startIndex) {
                    return result
                }
            }
        }
        return nil
    }

    private func search(from position: Position, target: String, visited: inout Set<Position>, index: String.Index) -> [Position]? {
        guard !visited.contains(position) else { return nil }
        guard grid.indices.contains(position.row), grid[position.row].indices.contains(position.col) else { return nil }

        let tile = grid[position.row][position.col]
        guard let nextIndex = target.index(index, offsetBy: tile.value.count, limitedBy: target.endIndex) else { return nil }
        guard target[index..<nextIndex] == tile.value else { return nil }

        visited.insert(position)
        defer { visited.remove(position) }

        if nextIndex == target.endIndex {
            return [position]
        }

        for neighbour in neighbours(of: position) {
            if let remainder = search(from: neighbour, target: target, visited: &visited, index: nextIndex) {
                return [position] + remainder
            }
        }
        return nil
    }

    private func neighbours(of position: Position) -> [Position] {
        let deltas = [-1, 0, 1]
        var result: [Position] = []
        for dr in deltas {
            for dc in deltas {
                guard !(dr == 0 && dc == 0) else { continue }
                let row = position.row + dr
                let col = position.col + dc
                if grid.indices.contains(row), grid[row].indices.contains(col) {
                    result.append(Position(row: row, col: col))
                }
            }
        }
        return result
    }

    private func rebuildRules() {
        var rules: [GameRule] = [PathRule(), MinLengthRule()]
        if configuration.enforceUniqueWords {
            rules.append(UniqueWordRule())
        }
        ruleEngine = RuleEngine(rules)
    }
}
