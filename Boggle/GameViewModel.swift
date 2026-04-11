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
    // A precomputed list of every playable word on the current board.
    @Published private(set) var availableWords: [BoardWordMatch] = []
    @Published private(set) var isSearchingAvailableWords = false

    // MARK: - Private helpers (not exposed to the view)
    // Used to manage the repeating timer for countdown.
    private var timer: AnyCancellable?
    private var solutionTask: Task<Void, Never>?
    private var solutionGeneration = UUID()
    // The set of valid words loaded from a dictionary file.
    private var dictionary = Set<String>()
    // Handles rule enforcement for word validity.
    private var ruleEngine: RuleEngine!

    // MARK: - Persisted rule bit-mask (stores the user's rule preferences)
    // @AppStorage persists the value using UserDefaults, so rule options are saved between app launches.
    // 'private' so only this class changes the value directly.
    @AppStorage("ruleOptions") private var optionsRaw = RuleOptions.standard.rawValue
    @AppStorage("minimumWordLength") private var minimumWordLengthRaw = GameSettings.classic.minimumWordLength
    @AppStorage("boardSize") private var boardSizeRaw = GameSettings.classic.boardSize.rawValue
    @AppStorage("roundDuration") private var roundDurationRaw = GameSettings.classic.roundDuration.rawValue

    /// Exposes the current settings for use in the UI.
    var currentSettings: GameSettings {
        GameSettings(
            options: RuleOptions(rawValue: optionsRaw),
            minimumWordLength: max(3, minimumWordLengthRaw),
            boardSize: BoardSize(rawValue: boardSizeRaw) ?? .four,
            roundDuration: RoundDuration(rawValue: roundDurationRaw) ?? .threeMinutes
        )
    }

    // MARK: - Init (setup)
    init(dictionary: Set<String>? = nil) {
        rebuildRules()      // Set up rule engine based on saved options
        if let dictionary {
            self.dictionary = Self.normalizeDictionaryEntries(dictionary)
        } else {
            loadDictionary()    // Load valid word list from file
        }
        highScore = UserDefaults.standard.integer(forKey: "HighScore") // Load best score
        timeRemaining = currentSettings.roundDuration.seconds
    }

    deinit {
        timer?.cancel()
        solutionTask?.cancel()
    }

    // MARK: - Game control (main game logic)
    // Starts a new game: creates a new grid, resets word/score/timer, and starts the countdown.
    func startGame() {
        generateGrid()
        resetGame()
        prepareBoardReview()
        startTimer()
    }

    // Resets the round state: clears found words, resets score, resets time, empties current word.
    func resetGame() {
        foundWords.removeAll()
        score = 0
        currentWord = ""
        timeRemaining = currentSettings.roundDuration.seconds
        availableWords.removeAll()
        isSearchingAvailableWords = false
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
            score += bonus + Self.score(for: word) // Add points for this word
            // Update high score if needed
            if score > highScore { highScore = score; UserDefaults.standard.set(highScore, forKey: "HighScore") }
        case .failure(let why):
            // If rules failed, show the reason to the user
            userMessage = UserMessage(message: why)
        }
        currentWord = "" // Clear the current word for next turn
    }

    // MARK: - Settings updates (settings/rules UI interaction)
    func applySettings(_ settings: GameSettings) {
        optionsRaw = settings.options.rawValue
        minimumWordLengthRaw = max(3, settings.minimumWordLength)
        boardSizeRaw = settings.boardSize.rawValue
        roundDurationRaw = settings.roundDuration.rawValue
        rebuildRules()
        startGame()
    }

    // Rebuild the rule engine using the latest toggles/options.
    private func rebuildRules() {
        let settings = currentSettings
        let opts = settings.options
        var r: [GameRule] = []
        // Optionally require minimum length
        if opts.contains(.minLength) {
            r.append(MinLengthRule(minLen: settings.minimumWordLength))
        }
        // Optionally require unique words
        if opts.contains(.uniqueWords) { r.append(UniqueWordRule()) }
        ruleEngine = RuleEngine(r) // Create new engine with these rules
    }

    // MARK: - Utility
    // Loads a list of valid words from a dictionary file in the app bundle.
    private func loadDictionary() {
        guard let path = Bundle.main.path(forResource: "dictionary", ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        dictionary = Self.parseDictionary(from: content)
    }

    nonisolated static func parseDictionary(from content: String) -> Set<String> {
        normalizeDictionaryEntries(
            content.split(whereSeparator: \.isNewline).map(String.init)
        )
    }

    private nonisolated static func normalizeDictionaryEntries<S: Sequence>(_ entries: S) -> Set<String> where S.Element == String {
        Set(
            entries
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    // Creates a square grid of random uppercase letters for the current board size.
    private func generateGrid() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let size = currentSettings.boardSize.dimension
        grid = (0..<size).map { _ in (0..<size).map { _ in letters.randomElement()! } }
    }

    // Calculates how many points a word earns (longer words score more).
    nonisolated static func score(for word: String) -> Int {
        switch word.count {
        case 0...2:
            return 0
        case 3...4:
            return 1
        case 5:
            return 2
        case 6:
            return 3
        case 7:
            return 5
        default:
            return 11
        }
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
        guard timeRemaining > 0 else {
            timer?.cancel()
            return
        }

        timeRemaining -= 1

        if timeRemaining == 0 {
            currentWord = ""
            timer?.cancel()
        }
    }

    var isRoundOver: Bool {
        timeRemaining == 0
    }

    private func prepareBoardReview() {
        solutionTask?.cancel()
        availableWords = []
        isSearchingAvailableWords = true

        let grid = self.grid
        let dictionary = self.dictionary
        let minimumLength = currentSettings.options.contains(.minLength) ? currentSettings.minimumWordLength : 1
        let generation = UUID()
        solutionGeneration = generation

        solutionTask = Task.detached(priority: .utility) { [weak self, grid, dictionary] in
            let matches = BoardWordFinder.findWords(in: grid, dictionary: dictionary, minimumLength: minimumLength)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.solutionGeneration == generation else { return }
                self.availableWords = matches
                self.isSearchingAvailableWords = false
            }
        }
    }
}
