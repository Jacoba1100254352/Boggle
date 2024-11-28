import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedLetters: [Position] = []
    
    var body: some View {
        VStack {
            BoggleGridView(grid: gameViewModel.grid, selectedLetters: $selectedLetters, onSelect: selectLetter)
            // Add additional UI elements like timer, score, word list
            Text("Time: \(formattedTime(gameViewModel.timeRemaining))")
                .font(.title2)
                .padding()
            
            Text("Score: \(gameViewModel.score)")
                .font(.title2)
                .padding()
            
            Text("High Score: \(gameViewModel.highScore)")
                .font(.title2)
                .padding()
            
            // Word input and list
            WordInputView(word: $gameViewModel.currentWord, onSubmit: {
                gameViewModel.submitWord()
            })
            List(gameViewModel.foundWords, id: \.self) { word in
                Text(word)
            }
            Spacer()
        }
        .onAppear {
            gameViewModel.startGame()
        }
    }
    
    private func selectLetter(_ position: Position) {
        // Check if the letter can be selected
        if let last = selectedLetters.last {
            let distance = abs(last.row - position.row) + abs(last.col - position.col)
            if distance > 1 {
                return // Non-adjacent letter
            }
        }
        selectedLetters.append(position)
        gameViewModel.currentWord = selectedLetters.map { gameViewModel.grid[$0.row][$0.col] }.map { String($0) }.joined()
    }
    
    func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
