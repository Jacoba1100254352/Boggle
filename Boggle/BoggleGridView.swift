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
    let grid: [[String]]
    // @Binding lets this view read and update the parent's list of selected positions.
    @Binding var selectedLetters: [Position]
    // 'onSelect' is a closure (function) called when a tile is tapped, passing the tapped tile's position.
    var onSelect: (Position) -> Void

    var body: some View {
        // Outer VStack: lays out the rows vertically
        let dimension = max(44, 260 / CGFloat(max(grid.count, 1)))

        VStack(spacing: 8) {
            // For each row in the grid...
            ForEach(grid.indices, id: \.self) { row in
                // HStack: lays out the tiles in this row horizontally
                HStack(spacing: 8) {
                    // For each column (tile) in this row...
                    ForEach(grid[row].indices, id: \.self) { col in
                        // Create a Position for this tile
                        let pos = Position(row: row, col: col)
                        // Show the letter in a styled square tile
                        Text(grid[row][col])
                            .font(.system(size: dimension * 0.45, weight: .bold, design: .rounded))
                            .frame(width: dimension, height: dimension)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(tileGradient(for: pos))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 3)
                            // When tapped, call onSelect to notify parent view
                            .onTapGesture { onSelect(pos) }
                    }
                }
            }
        }
        .padding(12) // Adds space around the grid
    }

    private func tileGradient(for position: Position) -> LinearGradient {
        let colors: [Color]
        if selectedLetters.contains(position) {
            colors = [Color.green.opacity(0.9), Color.green.opacity(0.6)]
        } else {
            colors = [Color.blue.opacity(0.85), Color.blue.opacity(0.6)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
