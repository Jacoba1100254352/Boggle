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
// Handles game state, rules, timer, score, and dictionary lookups.
// MainActor: Ensures updates happen on the main/UI thread.
// =============================================================
@MainActor final class GameViewModel: ObservableObject {
    // MARK: - UI-bound state (Published so SwiftUI updates automatically)
    // The current letter grid for the game.
    @Published var grid: [[String]] = []
    // The word the user is currently building/selecting.
    @Published var currentWord = ""
    // A running list of words the user has found so far.
    @Published var foundWords: [String] = []
    // The user's current score for this round.
    @Published var score = 0
    // Time left in the round (in seconds).
    @Published var timeRemaining = RuleConfiguration.default.roundDuration
    // Highest score ever achieved (across games).
    @Published var highScore = 0
    // Holds a message to present to the user, e.g., invalid word, end of game, etc.
    @Published var userMessage: UserMessage? = nil

    // MARK: - Private helpers (not exposed to the view)
    // Used to manage the repeating timer for countdown.
    private var timer: AnyCancellable?
    // The set of valid words loaded from a dictionary file.
    private var dictionary = Set<String>()
    // Handles rule enforcement for word validity.
    private var ruleEngine: RuleEngine!

    // MARK: - Persisted configuration
    @AppStorage("ruleConfiguration") private var storedConfigurationData: Data = Data()

    /// The full rule configuration for the game (persisted between launches).
    @Published private(set) var ruleConfiguration: RuleConfiguration
    /// Currently selected handicap (if any) that adjusts the base configuration.
    @Published var activeHandicapID: PlayerHandicap.ID? {
        didSet { rebuildRules() }
    }

    // MARK: - Init (setup)
    init() {
        if let config = try? JSONDecoder().decode(RuleConfiguration.self, from: storedConfigurationData),
           config.boardSize >= 3 {
            ruleConfiguration = config
        } else {
            ruleConfiguration = .default
        }

        timeRemaining = ruleConfiguration.roundDuration
        rebuildRules()      // Set up rule engine based on saved configuration
        loadDictionary()    // Load valid word list from file
        highScore = UserDefaults.standard.integer(forKey: "HighScore") // Load best score
    }

    // MARK: - Game control (main game logic)
    // Starts a new game: creates a new grid, resets word/score/timer, and starts the countdown.
    func startGame() {
        generateGrid()
        resetGame()
        startTimer()
    }

    // Resets the round state: clears found words, resets score, resets time, empties current word.
    func resetGame() {
        foundWords.removeAll()
        score = 0
        currentWord = ""
        timeRemaining = activeRoundDuration
    }

    // Called when the user tries to submit a word.
    // Validates the word, checks rules and dictionary, updates score and state as needed.
    func submitWord(selectedLetters: [Position]) {
        let word = currentWord.lowercased() // Always compare in lowercase
        guard !word.isEmpty else { return } // Ignore empty submissions
        let ctx = GameContext(grid: grid, previousWords: Set(foundWords))
        switch ruleEngine.evaluate(word: word, path: selectedLetters, in: ctx) {
        case .success(let bonus):
            // If custom rules pass, check if it's a real word in our dictionary
            guard dictionary.contains(word) else { userMessage = UserMessage(message: "Not in dictionary"); return }
            foundWords.append(word) // Save the new word
            score += bonus + calculateScore(for: word) // Add points for this word
            // Update high score if needed
            if score > highScore { highScore = score; UserDefaults.standard.set(highScore, forKey: "HighScore") }
        case .failure(let why):
            // If rules failed, show the reason to the user
            userMessage = UserMessage(message: why)
        }
        currentWord = "" // Clear the current word for next turn
    }

    // MARK: - Rule configuration (settings/rules UI interaction)
    func applyConfiguration(_ newConfig: RuleConfiguration) {
        let boardSizeChanged = newConfig.boardSize != ruleConfiguration.boardSize
        ruleConfiguration = newConfig
        persistConfiguration()
        rebuildRules()
        if boardSizeChanged {
            foundWords.removeAll()
            score = 0
            currentWord = ""
            generateGrid()
        }
        if let id = activeHandicapID,
           !ruleConfiguration.handicaps.contains(where: { $0.id == id }) {
            activeHandicapID = nil
        }
        // Ensure the timer reflects the latest settings when a game is active.
        timeRemaining = activeRoundDuration
    }

    private func persistConfiguration() {
        if let data = try? JSONEncoder().encode(ruleConfiguration) {
            storedConfigurationData = data
        }
    }

    /// Rebuild the rule engine using the latest configuration and active handicap.
    private func rebuildRules() {
        var rules: [GameRule] = [PathContinuityRule(), PathWordMatchRule()]

        let minLength = activeMinWordLength
        if minLength > 1 {
            rules.append(MinLengthRule(minLen: minLength))
        }
        if ruleConfiguration.requireUniqueWords {
            rules.append(UniqueWordRule())
        }

        ruleEngine = RuleEngine(rules) // Create new engine with these rules
    }

    // MARK: - Utility
    // Loads a list of valid words from a dictionary file in the app bundle.
    private func loadDictionary() {
        guard let path = Bundle.main.path(forResource: "dictionary", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else { return }
        // Store all words (lowercased) in a set for fast lookup
        dictionary = Set(
            content
                .split(whereSeparator: { $0.isNewline })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    // Creates a new 4x4 grid of random uppercase letters for the game board.
    private func generateGrid() {
        grid = BoggleDice.rollBoard(size: ruleConfiguration.boardSize)
    }

    // Calculates how many points a word earns (longer words score more).
    private func calculateScore(for w: String) -> Int {
        switch w.count {
        case 0...2: return 0
        case 3...4: return 1
        case 5: return 2
        case 6: return 3
        case 7: return 5
        default: return 11
        }
    }

    /// Public helper for the UI to show how many points a previously found word earned.
    func points(for word: String) -> Int {
        calculateScore(for: word)
    }

    // MARK: - Timer logic
    // Starts (or restarts) the countdown timer for the game.
    private func startTimer() {
        timer?.cancel() // Stop any existing timer
        // Create a new timer that fires every second and calls 'tick()'
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // Called every second by the timer.
    // Decreases remaining time, and stops the timer if time runs out.
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.cancel() // Time's up
            if userMessage == nil {
                userMessage = UserMessage(message: "Time's up! Start a new game from the toolbar to play again.")
            }
        }
    }

    private var activeHandicap: PlayerHandicap? {
        guard let id = activeHandicapID else { return nil }
        return ruleConfiguration.handicaps.first(where: { $0.id == id })
    }

    var activeHandicapName: String? { activeHandicap?.name }

    var activeMinWordLength: Int {
        max(2, activeHandicap?.minWordLength ?? ruleConfiguration.baseMinWordLength)
    }

    var activeRoundDuration: Int {
        activeHandicap?.roundDuration ?? ruleConfiguration.roundDuration
    }
}
