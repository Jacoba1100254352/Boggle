// =============================================================
// BoggleGridView.swift
// =============================================================

import SwiftUI

// =============================================================
// BoggleGridView: Displays the Boggle game board as a grid of tiles.
// Highlights the player's selection and forwards tap events.
// =============================================================
struct BoggleGridView: View {
    let grid: [[String]]
    @Binding var selectedLetters: [Position]
    var onSelect: (Position) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(grid.indices, id: \.self) { row in
                ForEach(grid[row].indices, id: \.self) { col in
                    let pos = Position(row: row, col: col)
                    TileView(text: grid[row][col], isSelected: selectedLetters.contains(pos))
                        .onTapGesture { onSelect(pos) }
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedLetters)
                }
            }
        }
        .padding(18)
    }

    private struct TileView: View {
        let text: String
        let isSelected: Bool

        var body: some View {
            Text(text.uppercased())
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 70)
                .padding(4)
                .background(tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(isSelected ? 0.9 : 0.4), lineWidth: isSelected ? 4 : 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 6 : 4)
        }

        private var tileBackground: some View {
            let base = LinearGradient(colors: isSelected ? [.orange, .pink] : [.blue.opacity(0.8), .purple.opacity(0.8)],
                                      startPoint: .topLeading,
                                      endPoint: .bottomTrailing)
            return base
        }
    }
}
