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
    @Published var grid: [[Character]] = []
    // The word the user is currently building/selecting.
    @Published var currentWord = ""
    // A running list of words the user has found so far.
    @Published var foundWords: [String] = []
    // The user's current score for this round.
    @Published var score = 0
    // Time left in the round (in seconds).
    @Published var timeRemaining = 180
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

    // MARK: - Persisted rule bit‑mask (stores the user's rule preferences)
    // @AppStorage persists the value using UserDefaults, so rule options are saved between app launches.
    // 'private' so only this class changes the value directly.
    @AppStorage("ruleOptions") private var optionsRaw = RuleOptions.all.rawValue

    /// Exposes the current rule options for use in the settings view (read-only).
    var currentOptions: RuleOptions { RuleOptions(rawValue: optionsRaw) }

    // MARK: - Init (setup)
    init() {
        rebuildRules()      // Set up rule engine based on saved options
        loadDictionary()    // Load valid word list from file
        highScore = UserDefaults.standard.integer(forKey: "HighScore") // Load best score
    }

    // MARK: - Game control (main game logic)
    // Starts a new game: creates a new grid, resets word/score/timer, and starts the countdown.
    func startGame() { generateGrid(); resetGame(); startTimer() }

    // Resets the round state: clears found words, resets score, resets time, empties current word.
    func resetGame() { foundWords.removeAll(); score = 0; currentWord = ""; timeRemaining = 180 }

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

    // MARK: - Rule toggling (settings/rules UI interaction)
    // Toggles a specific rule on/off using bitwise XOR.
    func toggle(_ flag: RuleOptions) { optionsRaw ^= flag.rawValue; rebuildRules() }

    // Rebuild the rule engine using the latest toggles/options.
    private func rebuildRules() {
        let opts = RuleOptions(rawValue: optionsRaw)
        var r: [GameRule] = []
        // Optionally require minimum length
        if opts.contains(.minLength)   { r.append(MinLengthRule(minLen: 3)) }
        // Optionally require unique words
        if opts.contains(.uniqueWords) { r.append(UniqueWordRule()) }
        ruleEngine = RuleEngine(r) // Create new engine with these rules
    }

    // MARK: - Utility
    // Loads a list of valid words from a dictionary file in the app bundle.
    private func loadDictionary() {
        guard let path = Bundle.main.path(forResource: "dictionary", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else { return }
        // Store all words (lowercased) in a set for fast lookup
        dictionary = Set(content.split(separator: "\n").map { $0.lowercased() })
    }

    // Creates a new 4x4 grid of random uppercase letters for the game board.
    private func generateGrid() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        grid = (0..<4).map { _ in (0..<4).map { _ in letters.randomElement()! } }
    }

    // Calculates how many points a word earns (longer words score more).
    private func calculateScore(for w: String) -> Int {
        switch w.count { case 3...4: 1; case 5: 2; case 6: 3; case 7: 5; default: 11 }
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
        }
    }
}
