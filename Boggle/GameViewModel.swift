// =============================================================
// GameViewModel.swift – Core game logic & state container
// =============================================================

import Combine
import SwiftUI

struct UserMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

@MainActor final class GameViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published private(set) var grid: [[String]] = []
    @Published var currentWord: String = ""
    @Published private(set) var highlightedPath: [Position] = []
    @Published private(set) var foundWords: [String] = []
    @Published private(set) var playerStates: [PlayerState]
    @Published private(set) var activePlayerIndex: Int = 0
    @Published private(set) var settings: GameSettings
    @Published private(set) var timeRemaining: Int
    @Published private(set) var highScore: Int
    @Published var userMessage: UserMessage? = nil

    // MARK: - Private state
    private var timer: AnyCancellable?
    private var dictionary: Set<String> = []
    private var usedWords: Set<String> = []
    private var hasStartedRound = false

    private static let settingsKey = "GameSettings.v1"
    private static let playersKey = "PlayerProfiles.v1"
    private static let highScoreKey = "HighScore"

    // MARK: - Init
    init() {
        settings = Self.loadSettings()
        let profiles = Self.loadPlayerProfiles()
        playerStates = profiles.map { PlayerState(profile: $0) }
        if playerStates.isEmpty {
            playerStates = defaultPlayers.map { PlayerState(profile: $0) }
        }
        activePlayerIndex = 0
        timeRemaining = settings.roundLength
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        loadDictionary()
        grid = BoggleDice.classicBoard()
        rebuildUsedWordsSet()
        updateFoundWordsDisplay()
    }

    deinit { timer?.cancel() }

    // MARK: - Accessors for the view
    var board: [[String]] { grid }

    var activePlayer: PlayerState? {
        guard playerStates.indices.contains(activePlayerIndex) else { return nil }
        return playerStates[activePlayerIndex]
    }

    var activePlayerName: String {
        activePlayer?.profile.name ?? ""
    }

    var activePlayerMinimumLength: Int {
        guard let player = activePlayer else { return settings.minimumWordLength }
        return minimumWordLength(for: player)
    }

    var isRoundActive: Bool { timeRemaining > 0 }

    func scoreForWord(_ word: String) -> Int {
        calculateScore(for: word.lowercased())
    }

    // MARK: - Public API consumed by the views
    func ensureGameStarted() {
        guard !hasStartedRound else { return }
        startGame()
    }

    func startGame() {
        hasStartedRound = true
        timer?.cancel()
        timeRemaining = settings.roundLength
        usedWords.removeAll()
        highlightedPath = []
        currentWord = ""
        for index in playerStates.indices {
            playerStates[index].resetForNewRound()
        }
        updateFoundWordsDisplay()
        savePlayerProfiles()
        grid = BoggleDice.classicBoard()
        startTimer()
    }

    func shuffleBoard() {
        grid = BoggleDice.classicBoard()
        if !settings.highlightLastWord {
            highlightedPath = []
        }
    }

    func submitCurrentWord() {
        let trimmed = currentWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        guard isRoundActive else {
            userMessage = UserMessage(message: "Time is up! Start a new round to keep playing.")
            return
        }
        guard var player = activePlayer else { return }

        let requiredLength = minimumWordLength(for: player)
        guard trimmed.count >= requiredLength else {
            userMessage = UserMessage(message: "Word must be at least \(requiredLength) letters for \(player.profile.name).")
            return
        }

        guard dictionary.contains(trimmed) else {
            userMessage = UserMessage(message: "\(trimmed.uppercased()) is not in the dictionary.")
            return
        }

        if settings.enforceUniqueWords {
            guard !usedWords.contains(trimmed) else {
                userMessage = UserMessage(message: "That word has already been claimed this round.")
                return
            }
        } else {
            guard !player.words.contains(trimmed) else {
                userMessage = UserMessage(message: "You already played that word.")
                return
            }
        }

        guard let path = findPath(for: trimmed) else {
            userMessage = UserMessage(message: "\(trimmed.uppercased()) cannot be formed on this board.")
            return
        }

        player.words.append(trimmed)
        player.score += calculateScore(for: trimmed)

        playerStates[activePlayerIndex] = player
        if settings.enforceUniqueWords {
            usedWords.insert(trimmed)
        }

        if settings.highlightLastWord {
            highlightedPath = path
        } else {
            highlightedPath = []
        }

        currentWord = ""
        updateFoundWordsDisplay()
        updateHighScoreIfNeeded(with: player.score)
    }

    func selectPlayer(_ playerID: PlayerProfile.ID) {
        guard let index = playerStates.firstIndex(where: { $0.id == playerID }) else { return }
        activePlayerIndex = index
        updateFoundWordsDisplay()
    }

    func apply(settings newSettings: GameSettings, players newProfiles: [PlayerProfile]) {
        settings = newSettings
        saveSettings()

        var sanitizedProfiles = newProfiles
        if sanitizedProfiles.isEmpty {
            sanitizedProfiles = defaultPlayers
        }

        let existingStates = Dictionary(uniqueKeysWithValues: playerStates.map { ($0.id, $0) })
        playerStates = sanitizedProfiles.map { profile in
            if var preserved = existingStates[profile.id] {
                preserved.profile = profile
                return preserved
            } else {
                return PlayerState(profile: profile)
            }
        }

        if !playerStates.indices.contains(activePlayerIndex) {
            activePlayerIndex = 0
        }

        savePlayerProfiles()
        rebuildUsedWordsSet()

        if timeRemaining > settings.roundLength {
            timeRemaining = settings.roundLength
        }

        if !settings.highlightLastWord {
            highlightedPath = []
        }

        updateFoundWordsDisplay()
    }

    // MARK: - Private helpers
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
            return
        }
        timeRemaining -= 1
        if timeRemaining == 0 {
            timer?.cancel()
            userMessage = UserMessage(message: "Round complete! Tap “New Round” when you are ready to play again.")
        }
    }

    private func updateHighScoreIfNeeded(with score: Int) {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
        }
    }

    private func updateFoundWordsDisplay() {
        guard let player = activePlayer else {
            foundWords = []
            return
        }
        foundWords = sortedWords(player.words)
    }

    private func rebuildUsedWordsSet() {
        if settings.enforceUniqueWords {
            usedWords = Set(playerStates.flatMap { $0.words })
        } else {
            usedWords.removeAll()
        }
    }

    private func minimumWordLength(for player: PlayerState) -> Int {
        player.minimumWordLengthOverride ?? settings.minimumWordLength
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

    private func sortedWords(_ words: [String]) -> [String] {
        words.sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs < rhs
            }
            return lhs.count > rhs.count
        }
    }

    private func findPath(for word: String) -> [Position]? {
        guard !grid.isEmpty else { return nil }
        let dimension = grid.count
        let target = word.lowercased()
        for row in 0..<dimension {
            for col in 0..<dimension {
                var visited: Set<Position> = []
                var path: [Position] = []
                if search(from: Position(row: row, col: col), remaining: target[...], visited: &visited, path: &path) {
                    return path
                }
            }
        }
        return nil
    }

    private func search(from position: Position, remaining: Substring, visited: inout Set<Position>, path: inout [Position]) -> Bool {
        guard !visited.contains(position) else { return false }
        let tile = grid[position.row][position.col].lowercased()
        guard remaining.hasPrefix(tile) else { return false }

        visited.insert(position)
        path.append(position)

        let leftover = remaining.dropFirst(tile.count)
        if leftover.isEmpty {
            return true
        }

        for neighbor in position.neighbors(in: grid.count) {
            if search(from: neighbor, remaining: leftover, visited: &visited, path: &path) {
                return true
            }
        }

        visited.remove(position)
        path.removeLast()
        return false
    }

    private func loadDictionary() {
        if let url = Bundle.main.url(forResource: "dictionary", withExtension: "txt"),
           let content = try? String(contentsOf: url) {
            dictionary = Set(content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        }
        if dictionary.isEmpty {
            dictionary = Self.fallbackDictionary
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }

    private func savePlayerProfiles() {
        let profiles = playerStates.map { $0.profile }
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: Self.playersKey)
        }
    }

    private static func loadSettings() -> GameSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return defaultSettings
        }
        return settings
    }

    private static func loadPlayerProfiles() -> [PlayerProfile] {
        guard let data = UserDefaults.standard.data(forKey: playersKey),
              let profiles = try? JSONDecoder().decode([PlayerProfile].self, from: data) else {
            return defaultPlayers
        }
        return profiles
    }

    private static let fallbackDictionary: Set<String> = [
        "able", "about", "after", "again", "apple", "baker", "bloom", "board", "brain", "brave",
        "bring", "castle", "chance", "clear", "cloud", "crane", "dream", "eagle", "earth", "flame",
        "frame", "ghost", "globe", "grape", "honey", "house", "jelly", "knife", "light", "magic",
        "night", "ocean", "pearl", "queen", "quick", "river", "stone", "table", "train", "water"
    ]
}
