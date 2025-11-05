// =============================================================
// BoggleGridView.swift
// =============================================================

import SwiftUI

// =============================================================
// BoggleGridView: Displays the Boggle game board as a grid of letters.
// Highlights the most recently discovered path with subtle numbering.
// =============================================================
struct BoggleGridView: View {
    /// The letter grid to present.
    let grid: [[String]]
    /// Ordered path that produced the latest accepted word.
    let highlightedPath: [Position]

    private var highlightLookup: [Position: Int] {
        Dictionary(uniqueKeysWithValues: highlightedPath.enumerated().map { ($1, $0 + 1) })
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(grid.indices, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(grid[row].indices, id: \.self) { col in
                        let position = Position(row: row, col: col)
                        TileView(value: grid[row][col], order: highlightLookup[position])
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
    }
}

private struct TileView: View {
    let value: String
    let order: Int?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tileGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(order == nil ? Color.white.opacity(0.3) : Color.green.opacity(0.8), lineWidth: order == nil ? 1 : 3)
                )
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let order {
                Text("\(order)")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(Color.green.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(6)
            }
        }
    }

    private var tileGradient: LinearGradient {
        if order == nil {
            return LinearGradient(colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.green.opacity(0.95), Color.green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
