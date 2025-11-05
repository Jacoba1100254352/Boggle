// =============================================================
// Position.swift
// =============================================================

import Foundation

/// A single tile coordinate on the 2‑D Boggle board.
struct Position: Hashable {
    let row: Int
    let col: Int
}

extension Position {
    /// Returns all neighbouring coordinates (including diagonals) that fall within
    /// the provided square board dimension.
    ///
    /// - Parameter dimension: The width/height of the square board.
    /// - Returns: Every adjacent tile position that remains inside the board.
    func neighbors(in dimension: Int) -> [Position] {
        guard dimension > 0 else { return [] }
        let lowerBound = 0
        let upperBound = dimension - 1
        var results: [Position] = []
        for r in max(row - 1, lowerBound)...min(row + 1, upperBound) {
            for c in max(col - 1, lowerBound)...min(col + 1, upperBound) {
                if r == row && c == col { continue }
                results.append(Position(row: r, col: c))
            }
        }
        return results
    }
}
