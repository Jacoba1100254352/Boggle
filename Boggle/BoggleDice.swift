// =============================================================
// BoggleDice.swift
// =============================================================

import Foundation

/// Utility responsible for producing realistic Boggle boards by rolling the
/// original Hasbro dice for the 4x4 game and the "Big Boggle" 5x5 variant.
enum BoggleDice {
    private static let classic4x4: [[String]] = [
        ["A", "A", "E", "E", "G", "N"],
        ["E", "L", "R", "T", "T", "Y"],
        ["A", "O", "O", "T", "T", "W"],
        ["A", "B", "B", "J", "O", "O"],
        ["E", "H", "R", "T", "V", "W"],
        ["C", "I", "M", "O", "T", "U"],
        ["D", "I", "S", "T", "T", "Y"],
        ["E", "I", "O", "S", "S", "T"],
        ["D", "E", "L", "R", "V", "Y"],
        ["A", "C", "H", "O", "P", "S"],
        ["H", "I", "M", "N", "Qu", "U"],
        ["E", "E", "I", "N", "S", "U"],
        ["E", "E", "G", "H", "N", "W"],
        ["A", "F", "F", "K", "P", "S"],
        ["H", "L", "N", "N", "R", "Z"],
        ["D", "E", "I", "L", "R", "X"],
    ]

    private static let bigBoggle5x5: [[String]] = [
        ["A", "A", "A", "F", "R", "S"],
        ["A", "A", "E", "E", "E", "E"],
        ["A", "A", "F", "I", "R", "S"],
        ["A", "D", "E", "N", "N", "N"],
        ["A", "E", "E", "E", "E", "M"],
        ["A", "E", "E", "G", "M", "U"],
        ["A", "E", "G", "M", "N", "N"],
        ["A", "F", "I", "R", "S", "Y"],
        ["B", "J", "K", "Qu", "X", "Z"],
        ["C", "C", "E", "N", "S", "T"],
        ["C", "E", "I", "I", "L", "T"],
        ["C", "E", "I", "P", "S", "T"],
        ["C", "E", "I", "P", "S", "T"],
        ["C", "E", "I", "P", "S", "T"],
        ["D", "D", "H", "N", "O", "T"],
        ["D", "H", "H", "L", "O", "R"],
        ["D", "H", "L", "N", "O", "R"],
        ["D", "H", "L", "N", "O", "R"],
        ["E", "I", "I", "I", "T", "T"],
        ["E", "M", "O", "T", "T", "T"],
        ["E", "N", "S", "S", "S", "U"],
        ["F", "I", "P", "R", "S", "Y"],
        ["G", "O", "R", "R", "V", "W"],
        ["I", "P", "R", "R", "R", "Y"],
        ["N", "O", "O", "T", "U", "W"],
    ]

    /// Generates a board of the requested size by rolling the appropriate dice set.
    /// - Parameter size: Board size (4 for classic Boggle, 5 for Big Boggle).
    /// - Returns: A 2D array of uppercase letter strings, with "Qu" treated as a single tile.
    static func rollBoard(size: Int) -> [[String]] {
        let dice: [[String]]
        switch size {
        case 5:
            dice = bigBoggle5x5
        default:
            dice = classic4x4
        }

        let required = size * size
        var pool = dice
        // If a larger board than the dice set supports is requested, cycle through the dice.
        while pool.count < required {
            pool.append(contentsOf: dice)
        }
        pool = Array(pool.shuffled().prefix(required))

        var iterator = pool.makeIterator()
        var result: [[String]] = []
        for _ in 0..<size {
            var row: [String] = []
            for _ in 0..<size {
                if let die = iterator.next() ?? pool.randomElement() {
                    row.append(die.randomElement() ?? "A")
                }
            }
            result.append(row)
        }
        return result
    }
}
