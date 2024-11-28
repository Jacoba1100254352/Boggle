import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var grid: [[Character]] = []
    @Published var currentWord: String = ""
    @Published var foundWords: [String] = []
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 180 // 3 minutes
    @Published var highScore: Int = 0
    
    private var timer: AnyCancellable?
    private var dictionary: Set<String> = []
    
    init() {
        loadDictionary()
        highScore = UserDefaults.standard.integer(forKey: "HighScore")
    }
    
    func startGame() {
        generateGrid()
        resetGame()
        startTimer()
    }
    
    func resetGame() {
        foundWords.removeAll()
        score = 0
        currentWord = ""
        timeRemaining = 180
    }
    
    private func loadDictionary() {
        if let path = Bundle.main.path(forResource: "dictionary", ofType: "txt") {
            if let content = try? String(contentsOfFile: path) {
                let words = content.components(separatedBy: .newlines)
                dictionary = Set(words.map { $0.lowercased() })
            }
        }
    }
    
    private func generateGrid() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        grid = (0..<4).map { _ in
            (0..<4).map { _ in
                letters.randomElement()!
            }
        }
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.cancel()
            // Handle end of game
        }
    }
    
    func submitWord(selectedLetters: [Position]) {
        let lowercasedWord = currentWord.lowercased()
        guard lowercasedWord.count >= 3 else {
            // Word too short
            currentWord = ""
            return
        }
        guard dictionary.contains(lowercasedWord) else {
            // Not a valid word
            currentWord = ""
            return
        }
        guard !foundWords.contains(lowercasedWord) else {
            // Word already found
            currentWord = ""
            return
        }
        if isWordOnBoard(word: lowercasedWord) {
            foundWords.append(lowercasedWord)
            score += calculateScore(for: lowercasedWord)
        }
        currentWord = ""
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "HighScore")
        }
    }
    
    func isWordOnBoard(word: String) -> Bool {
        guard !word.isEmpty else { return false }
        var visited = Array(repeating: Array(repeating: false, count: grid[0].count), count: grid.count)
        
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if grid[row][col].lowercased() == word.first {
                    if dfs(word: word, index: 0, row: row, col: col, visited: &visited) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func calculateScore(for word: String) -> Int {
        switch word.count {
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
    
    private func dfs(word: String, index: Int, row: Int, col: Int, visited: inout [[Bool]]) -> Bool {
        if index == word.count {
            return true
        }
        // Check boundaries and character match
        if row < 0 || row >= grid.count || col < 0 || col >= grid[row].count {
            return false
        }
        if visited[row][col] || grid[row][col].lowercased() != String(word[word.index(word.startIndex, offsetBy: index)]).lowercased() {
            return false
        }
        
        // Mark as visited
        visited[row][col] = true
        
        // Explore all adjacent cells
        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          (0, -1),          (0, 1),
                          (1, -1),  (1, 0), (1, 1)]
        
        for direction in directions {
            let newRow = row + direction.0
            let newCol = col + direction.1
            if dfs(word: word, index: index + 1, row: newRow, col: newCol, visited: &visited) {
                return true
            }
        }
        
        // Backtrack
        visited[row][col] = false
        return false
    }
}
