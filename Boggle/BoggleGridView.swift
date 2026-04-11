// =============================================================
// BoggleGridView.swift
// =============================================================

import SwiftUI

struct BoggleGridView: View {
    let grid: [[Character]]
    @Binding var selectedLetters: [Position]
    var onSelect: (Position) -> Void

    var body: some View {
        GeometryReader { proxy in
            let dimension = max(grid.count, 1)
            let positions = grid.indices.flatMap { row in
                grid[row].indices.map { Position(row: row, col: $0) }
            }
            let spacing: CGFloat = dimension == 5 ? 8 : 10
            let padding: CGFloat = dimension == 5 ? 18 : 20
            let tileSize = max(
                46,
                min(
                    84,
                    (
                        proxy.size.width
                        - (padding * 2)
                        - (CGFloat(dimension - 1) * spacing)
                    ) / CGFloat(dimension)
                )
            )
            let columns = Array(repeating: GridItem(.fixed(tileSize), spacing: spacing), count: dimension)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.34, blue: 0.42).opacity(0.12),
                                Color.white.opacity(0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                    )

                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(positions, id: \.self) { position in
                        let selectionIndex = selectedLetters.firstIndex(of: position)

                        Button {
                            onSelect(position)
                        } label: {
                            BoggleTile(
                                letter: String(grid[position.row][position.col]),
                                tileSize: tileSize,
                                selectionIndex: selectionIndex
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(padding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: boardHeight)
    }

    private var boardHeight: CGFloat {
        switch grid.count {
        case 5:
            return 396
        default:
            return 314
        }
    }

}

private struct BoggleTile: View {
    let letter: String
    let tileSize: CGFloat
    let selectionIndex: Int?

    private var isSelected: Bool {
        selectionIndex != nil
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isSelected
                            ? [
                                Color(red: 0.19, green: 0.57, blue: 0.50),
                                Color(red: 0.11, green: 0.33, blue: 0.38)
                            ]
                            : [
                                Color.white.opacity(0.98),
                                Color(red: 0.83, green: 0.90, blue: 0.95)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            isSelected
                                ? Color.white.opacity(0.76)
                                : Color(red: 0.28, green: 0.42, blue: 0.52).opacity(0.14),
                            lineWidth: isSelected ? 2 : 1
                        )
                )

            Text(letter)
                .font(.system(size: tileSize * 0.42, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color(red: 0.12, green: 0.22, blue: 0.30))
        }
        .overlay(alignment: .topTrailing) {
            if let selectionIndex {
                Text("\(selectionIndex + 1)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(red: 0.09, green: 0.28, blue: 0.33))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.92))
                    )
                    .padding(8)
            }
        }
        .frame(width: tileSize, height: tileSize)
        .shadow(
            color: Color.black.opacity(isSelected ? 0.20 : 0.08),
            radius: isSelected ? 16 : 10,
            x: 0,
            y: isSelected ? 12 : 8
        )
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: isSelected)
    }
}
