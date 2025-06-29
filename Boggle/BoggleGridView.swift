// =============================================================
// BoggleGridView.swift
// =============================================================

import SwiftUI

// =============================================================
// BoggleGridView: Displays the Boggle game board as a grid of letters.
// Shows which tiles are selected, and lets the user tap to select tiles.
// =============================================================
struct BoggleGridView: View {
    // The 2D grid of characters (letters) to display.
    let grid: [[Character]]
    // @Binding lets this view read and update the parent's list of selected positions.
    @Binding var selectedLetters: [Position]
    // 'onSelect' is a closure (function) called when a tile is tapped, passing the tapped tile's position.
    var onSelect: (Position) -> Void

    var body: some View {
        // Outer VStack: lays out the rows vertically
        VStack(spacing: 5) {
            // For each row in the grid...
            ForEach(grid.indices, id: \.self) { row in
                // HStack: lays out the tiles in this row horizontally
                HStack(spacing: 5) {
                    // For each column (tile) in this row...
                    ForEach(grid[row].indices, id: \.self) { col in
                        // Create a Position for this tile
                        let pos = Position(row: row, col: col)
                        // Show the letter in a styled square tile
                        Text(String(grid[row][col]))
                            .font(.largeTitle) // Big readable letter
                            .frame(width: 60, height: 60) // Fixed tile size
                            // Tile color: greenish if selected, blue otherwise
                            .background(selectedLetters.contains(pos) ? .green.opacity(0.7) : .blue.opacity(0.7))
                            .foregroundColor(.white) // White letter
                            .cornerRadius(8) // Rounded tile corners
                            // When tapped, call onSelect to notify parent view
                            .onTapGesture { onSelect(pos) }
                    }
                }
            }
        }
        .padding() // Adds space around the grid
    }
}
