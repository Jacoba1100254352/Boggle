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

// =============================================================
// GameViewModel: Core logic and state-holder for the Boggle game.
// Handles game state, rules, timer, score, dictionary lookups, and rule customisation.
// MainActor: Ensures updates happen on the main/UI thread.
// =============================================================
@MainActor final class GameViewModel: ObservableObject {
    // MARK: - UI-bound state (Published so SwiftUI updates automatically)
    /// The current letter grid for the game. Each entry can represent more than one
    /// character (e.g. "Qu") so we store strings.
    @Published var grid: [[String]] = []
    /// The word the user is currently building/selecting (display form).
    @Published var currentWord = ""
    /// Words discovered by the active player in the running round.
    @Published var foundWords: [String] = []
    /// Convenience mirror of the active player's score for quick binding in the UI.
    @Published var score = 0
    /// Time left in the round (in seconds).
    @Published var timeRemaining = 180
    /// Highest score ever achieved (across games).
    @Published var highScore = 0
    /// List of players participating in the session.
    @Published var players: [PlayerProfile] = [] {
        didSet { persistPlayers() }
    }
    /// Identifier for the currently active player.
    @Published var activePlayerID: PlayerProfile.ID {
        didSet { syncActivePlayerState(); rebuildRules() }
    }
    /// Whether the round timer is currently ticking.
    @Published private(set) var isRoundRunning = false
    /// Configurable round length (seconds).
    @Published private(set) var roundDuration: Int
    /// Base minimum word length applied when the min-length rule is enabled.
    @Published private(set) var baseMinimumLength: Int
    /// Holds a message to present to the user, e.g., invalid word, end of game, etc.
    @Published var userMessage: UserMessage? = nil

    // MARK: - Private helpers (not exposed to the view)
    private var timer: AnyCancellable?
    private var dictionary = Set<String>()
    private var ruleEngine: RuleEngine!

    // MARK: - Persisted rule bit‑mask (stores the user's rule preferences)
    // @AppStorage persists the value using UserDefaults, so rule options are saved between app launches.
    // 'private' so only this class changes the value directly.
    @AppStorage("ruleOptions") private var optionsRaw = RuleOptions.all.rawValue
    @AppStorage("roundDuration") private var storedRoundDuration = 180
    @AppStorage("baseMinimumLength") private var storedBaseMinimumLength = 3

    /// Exposes the current rule options for use in the settings view (read-only).
    var currentOptions: RuleOptions { RuleOptions(rawValue: optionsRaw) }

    /// Returns true if a specific rule is currently enabled.
    func isRuleEnabled(_ option: RuleOptions) -> Bool { currentOptions.contains(option) }

    /// Enables or disables a rule explicitly.
    func setRule(_ option: RuleOptions, enabled: Bool) {
        if enabled {
            optionsRaw |= option.rawValue
        } else {
            optionsRaw &= ~option.rawValue
        }
        rebuildRules()
    }

    // MARK: - Init (setup)
    init() {
        let storedPlayers = Self.loadPersistedPlayers()
        _players = Published(initialValue: storedPlayers)
        let defaultActive = storedPlayers.first?.id ?? PlayerProfile(name: "Player 1").id
        _activePlayerID = Published(initialValue: defaultActive)
        roundDuration = storedRoundDuration
        baseMinimumLength = storedBaseMinimumLength
        loadDictionary()    // Load valid word list from file
        highScore = UserDefaults.standard.integer(forKey: "HighScore") // Load best score
        if players.isEmpty {
            let player = PlayerProfile(name: "Player 1")
            players = [player]
            activePlayerID = player.id
        }
        syncActivePlayerState()
        rebuildRules()      // Set up rule engine based on saved options
    }

    // MARK: - Derived helpers
    /// Returns the active player profile if available.
    var activePlayer: PlayerProfile? { players.first { $0.id == activePlayerID } }

    /// Returns the minimum length currently applied to the active player.
    private var activeMinimumLength: Int {
        guard currentOptions.contains(.minLength), let player = activePlayer else { return baseMinimumLength }
        return player.minimumLength(using: baseMinimumLength)
    }

    // MARK: - Persistence
    private static func loadPersistedPlayers() -> [PlayerProfile] {
        guard let data = UserDefaults.standard.data(forKey: "Players") else { return [] }
        return (try? JSONDecoder().decode([PlayerProfile].self, from: data)) ?? []
    }

    private func persistPlayers() {
        if let data = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(data, forKey: "Players")
        }
        // Ensure the active player id still exists; if not, fall back.
        if players.indexOfPlayer(id: activePlayerID) == nil, let first = players.first {
            activePlayerID = first.id
        }
        syncActivePlayerState()
    }

    // MARK: - Public API
    func startGame() {
        generateGrid()
        resetGame()
        startTimer()
        isRoundRunning = true
    }

    func resetGame() {
        timer?.cancel()
        isRoundRunning = false
        currentWord = ""
        timeRemaining = roundDuration
        for idx in players.indices {
            players[idx].score = 0
            players[idx].words.removeAll()
        }
        syncActivePlayerState()
    }

    func submitWord(selectedLetters: [Position]) {
        let normalized = currentWord.lowercased()
        guard !normalized.isEmpty else { return }
        guard let playerIndex = players.indexOfPlayer(id: activePlayerID) else { return }
        let ctx = GameContext(grid: grid, previousWords: Set(players[playerIndex].words))
        switch ruleEngine.evaluate(word: normalized, path: selectedLetters, in: ctx) {
        case .success(let bonus):
            guard dictionary.contains(normalized) else {
                userMessage = UserMessage(message: "Not in dictionary")
                return
            }
            players[playerIndex].words.append(normalized)
            players[playerIndex].score += bonus + calculateScore(for: normalized)
            score = players[playerIndex].score
            foundWords = players[playerIndex].words.sorted()
            if players[playerIndex].score > highScore {
                highScore = players[playerIndex].score
                UserDefaults.standard.set(highScore, forKey: "HighScore")
            }
        case .failure(let why):
            userMessage = UserMessage(message: why)
        }
        currentWord = ""
    }

    func clearCurrentSelection() {
        currentWord = ""
    }

    func shuffleBoard() {
        generateGrid()
    }

    func updateRoundDuration(_ value: Int) {
        roundDuration = max(30, value)
        storedRoundDuration = roundDuration
        if !isRoundRunning {
            timeRemaining = roundDuration
        }
    }

    func updateBaseMinimumLength(_ value: Int) {
        baseMinimumLength = max(2, value)
        storedBaseMinimumLength = baseMinimumLength
        rebuildRules()
    }

    func setMinimumLengthOverride(_ value: Int?, for player: PlayerProfile.ID) {
        guard let idx = players.indexOfPlayer(id: player) else { return }
        players[idx].minimumLengthOverride = value
        if player == activePlayerID { rebuildRules() }
    }

    func rename(player: PlayerProfile.ID, to newName: String) {
        guard let idx = players.indexOfPlayer(id: player) else { return }
        players[idx].name = newName.isEmpty ? "Player" : newName
    }

    func addPlayer() {
        let nextNumber = players.count + 1
        let player = PlayerProfile(name: "Player \(nextNumber)")
        players.append(player)
        if players.count == 1 { activePlayerID = player.id }
    }

    func removePlayers(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        if players.isEmpty {
            let fallback = PlayerProfile(name: "Player 1")
            players = [fallback]
            activePlayerID = fallback.id
        }
    }

    func setActivePlayer(_ id: PlayerProfile.ID) {
        guard activePlayerID != id else { return }
        activePlayerID = id
    }

    func string(for path: [Position]) -> String {
        path.map { grid[$0.row][$0.col] }.joined()
    }

    // MARK: - Rule toggling (settings/rules UI interaction)
    // Toggles a specific rule on/off using bitwise XOR.
    func toggle(_ flag: RuleOptions) {
        optionsRaw ^= flag.rawValue
        rebuildRules()
    }

    // MARK: - Utility
    private func syncActivePlayerState() {
        guard let idx = players.indexOfPlayer(id: activePlayerID) else { return }
        score = players[idx].score
        foundWords = players[idx].words.sorted()
    }

    private func rebuildRules() {
        let opts = RuleOptions(rawValue: optionsRaw)
        var r: [GameRule] = [PathMatchesWordRule()]
        if opts.contains(.minLength) {
            r.append(MinLengthRule(minLen: activeMinimumLength, owner: activePlayer?.name))
        }
        if opts.contains(.uniqueWords) { r.append(UniqueWordRule()) }
        ruleEngine = RuleEngine(r)
    }

    private func loadDictionary() {
        guard let path = Bundle.main.path(forResource: "dictionary", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else { return }
        dictionary = Set(content.split(whereSeparator: { $0.isNewline }).map { $0.lowercased() })
    }

    private func generateGrid() {
        let dice = BoggleDice.standard
        var faces = dice.shuffled().map { $0.randomFace() }
        // Ensure we have exactly 16 faces for the 4x4 board.
        if faces.count < 16 {
            faces.append(contentsOf: Array(repeating: "E", count: 16 - faces.count))
        }
        grid = stride(from: 0, to: 16, by: 4).map { row in
            Array(faces[row..<row+4])
        }
    }

    private func calculateScore(for w: String) -> Int {
        switch w.count {
        case ..<3: return 0
        case 3...4: return 1
        case 5: return 2
        case 6: return 3
        case 7: return 5
        default: return 11
        }
    }

    private func startTimer() {
        timer?.cancel()
        timeRemaining = roundDuration
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            timer?.cancel()
            isRoundRunning = false
            userMessage = UserMessage(message: "Time's up! Tap New Round to play again.")
            return
        }
        timeRemaining -= 1
    }
}

// MARK: - Boggle dice definition
private struct BoggleDie: Codable {
    let faces: [String]

    func randomFace() -> String { faces.randomElement() ?? "E" }
}

private enum BoggleDice {
    /// Official Hasbro 4x4 Boggle dice letter distribution.
    static let standard: [BoggleDie] = [
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
        BoggleDie(faces: ["E", "H", "R", "T", "D", "V"]),
        BoggleDie(faces: ["A", "E", "N", "E", "G", "N"]),
        BoggleDie(faces: ["A", "F", "F", "K", "P", "S"]),
        BoggleDie(faces: ["H", "L", "N", "N", "R", "Z"])
    ]
}
