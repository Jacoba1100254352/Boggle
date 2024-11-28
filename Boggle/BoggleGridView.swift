import SwiftUI

struct BoggleGridView: View {
    let grid: [[Character]]
    @Binding var selectedLetters: [Position]
    
    var onSelect: (Position) -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        let position = Position(row: row, col: col)
                        Text(String(grid[row][col]))
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(selectedLetters.contains(position) ? Color.green.opacity(0.7) : Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .onTapGesture {
                                onSelect(position)
                            }
                    }
                }
            }
        }
        .padding()
    }
}
