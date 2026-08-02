import Foundation

struct BoardWordMatch: Identifiable, Hashable, Sendable {
    let word: String
    let path: [Position]

    var id: String { word }
}

enum BoardWordFinder {
    static func findWords(in grid: [[String]], dictionary: Set<String>, minimumLength: Int) -> [BoardWordMatch] {
        guard !grid.isEmpty, grid.allSatisfy({ !$0.isEmpty }) else { return [] }

        let normalizedGrid = grid.map { row in
            row.map { $0.lowercased() }
        }
        let maximumLength = normalizedGrid.flatMap { $0 }.reduce(0) { $0 + $1.count }
        let boardCounts = boardLetterCounts(for: normalizedGrid)
        let filteredDictionary = dictionary.filter {
            isCandidate($0, boardCounts: boardCounts, minimumLength: minimumLength, maximumLength: maximumLength)
        }
        let trie = WordTrie(words: filteredDictionary)

        guard trie.hasWords else { return [] }

        var matches: [String: BoardWordMatch] = [:]
        var visited = normalizedGrid.map { Array(repeating: false, count: $0.count) }
        var path: [Position] = []

        for row in normalizedGrid.indices {
            for col in normalizedGrid[row].indices {
                guard let childIndex = trie.nodeIndex(after: normalizedGrid[row][col], from: 0) else { continue }
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

    /// Finds one playable tile path for a typed word.
    static func path(for word: String, in grid: [[String]]) -> [Position]? {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedWord.isEmpty else { return nil }

        return findWords(
            in: grid,
            dictionary: [normalizedWord],
            minimumLength: 1
        ).first?.path
    }

    /// Returns the word represented by a path only when every tile is in
    /// bounds, adjacent to the prior tile, and used no more than once.
    static func word(along path: [Position], in grid: [[String]]) -> String? {
        guard !path.isEmpty else { return nil }

        var used: Set<Position> = []
        var previous: Position?
        var word = ""

        for position in path {
            guard grid.indices.contains(position.row),
                  grid[position.row].indices.contains(position.col),
                  used.insert(position).inserted else { return nil }

            if let previous {
                let rowDistance = abs(previous.row - position.row)
                let columnDistance = abs(previous.col - position.col)
                guard rowDistance <= 1,
                      columnDistance <= 1,
                      rowDistance + columnDistance > 0 else { return nil }
            }

            word += grid[position.row][position.col].lowercased()
            previous = position
        }

        return word
    }

    static func path(_ path: [Position], spells word: String, in grid: [[String]]) -> Bool {
        self.word(along: path, in: grid)
            == word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

    private static func boardLetterCounts(for board: [[String]]) -> [Character: Int] {
        var counts: [Character: Int] = [:]
        for row in board {
            for tile in row {
                for character in tile {
                    counts[character, default: 0] += 1
                }
            }
        }
        return counts
    }

    private static func explore(
        row: Int,
        col: Int,
        nodeIndex: Int,
        grid: [[String]],
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
                let nextTile = grid[nextRow][nextCol]
                guard let childIndex = trie.nodeIndex(after: nextTile, from: nodeIndex) else { continue }

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

    func nodeIndex(after tile: String, from nodeIndex: Int) -> Int? {
        var currentIndex = nodeIndex

        for character in tile {
            guard let childIndex = nodes[currentIndex].children[character] else { return nil }
            currentIndex = childIndex
        }

        return currentIndex
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
