import Foundation

struct BoardWordMatch: Identifiable, Hashable, Sendable {
    let word: String
    let path: [Position]

    var id: String { word }
}

enum BoardWordFinder {
    static func findWords(in grid: [[Character]], dictionary: Set<String>, minimumLength: Int) -> [BoardWordMatch] {
        guard !grid.isEmpty else { return [] }

        let normalizedGrid = grid.map { row in
            row.map { Character(String($0).lowercased()) }
        }
        let maximumLength = normalizedGrid.count * normalizedGrid.count
        let boardCounts = boardLetterCounts(for: normalizedGrid)
        let filteredDictionary = dictionary.filter {
            isCandidate($0, boardCounts: boardCounts, minimumLength: minimumLength, maximumLength: maximumLength)
        }
        let trie = WordTrie(words: filteredDictionary)

        guard trie.hasWords else { return [] }

        var matches: [String: BoardWordMatch] = [:]
        var visited = Array(
            repeating: Array(repeating: false, count: normalizedGrid.first?.count ?? 0),
            count: normalizedGrid.count
        )
        var path: [Position] = []

        for row in normalizedGrid.indices {
            for col in normalizedGrid[row].indices {
                guard let childIndex = trie.childIndex(for: normalizedGrid[row][col], from: 0) else { continue }
                explore(
                    row: row,
                    col: col,
                    nodeIndex: childIndex,
                    grid: normalizedGrid,
                    trie: trie,
                    visited: &visited,
                    path: &path,
                    matches: &matches
                )
            }
        }

        return matches.values.sorted {
            if $0.word.count != $1.word.count {
                return $0.word.count > $1.word.count
            }
            return $0.word < $1.word
        }
    }

    private static func isCandidate(
        _ word: String,
        boardCounts: [Character: Int],
        minimumLength: Int,
        maximumLength: Int
    ) -> Bool {
        guard word.count >= minimumLength, word.count <= maximumLength else { return false }
        var requiredCounts: [Character: Int] = [:]

        for character in word {
            guard boardCounts[character, default: 0] > 0 else { return false }
            requiredCounts[character, default: 0] += 1
            if requiredCounts[character, default: 0] > boardCounts[character, default: 0] {
                return false
            }
        }

        return true
    }

    private static func boardLetterCounts(for board: [[Character]]) -> [Character: Int] {
        var counts: [Character: Int] = [:]
        for row in board {
            for character in row {
                counts[character, default: 0] += 1
            }
        }
        return counts
    }

    private static func explore(
        row: Int,
        col: Int,
        nodeIndex: Int,
        grid: [[Character]],
        trie: WordTrie,
        visited: inout [[Bool]],
        path: inout [Position],
        matches: inout [String: BoardWordMatch]
    ) {
        visited[row][col] = true
        path.append(Position(row: row, col: col))

        if let word = trie.word(at: nodeIndex), matches[word] == nil {
            matches[word] = BoardWordMatch(word: word, path: path)
        }

        for nextRow in max(0, row - 1)...min(grid.count - 1, row + 1) {
            for nextCol in max(0, col - 1)...min(grid[nextRow].count - 1, col + 1) {
                guard !(nextRow == row && nextCol == col), !visited[nextRow][nextCol] else { continue }
                let nextCharacter = grid[nextRow][nextCol]
                guard let childIndex = trie.childIndex(for: nextCharacter, from: nodeIndex) else { continue }

                explore(
                    row: nextRow,
                    col: nextCol,
                    nodeIndex: childIndex,
                    grid: grid,
                    trie: trie,
                    visited: &visited,
                    path: &path,
                    matches: &matches
                )
            }
        }

        path.removeLast()
        visited[row][col] = false
    }
}

private struct WordTrie {
    private struct Node {
        var children: [Character: Int] = [:]
        var word: String?
    }

    private var nodes: [Node] = [Node()]

    var hasWords: Bool {
        nodes.count > 1
    }

    init(words: Set<String>) {
        for word in words {
            insert(word)
        }
    }

    func childIndex(for character: Character, from nodeIndex: Int) -> Int? {
        nodes[nodeIndex].children[character]
    }

    func word(at nodeIndex: Int) -> String? {
        nodes[nodeIndex].word
    }

    private mutating func insert(_ word: String) {
        var currentIndex = 0

        for character in word {
            if let childIndex = nodes[currentIndex].children[character] {
                currentIndex = childIndex
            } else {
                let nextIndex = nodes.count
                nodes.append(Node())
                nodes[currentIndex].children[character] = nextIndex
                currentIndex = nextIndex
            }
        }

        nodes[currentIndex].word = word
    }
}
