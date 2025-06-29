// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

// =============================================================
// ContentView: The main view for the Boggle game UI.
// Displays the game board, timer, score, word input, and more.
// =============================================================
struct ContentView: View {
    // Holds the core game state and logic for the view.
    // @StateObject tells SwiftUI to create and watch this object for changes, so the view updates when data changes.
    // 'private' means only this struct can use 'vm'.
    @StateObject private var vm = GameViewModel()

    // Stores the currently selected positions (tiles) on the Boggle board.
    // @State is used for simple, changing values. When it changes, the view updates.
    @State private var selected: [Position] = []		// Creates a list of Position structs initialized as an empty list

    // Controls if the settings/rules sheet is shown.
    // When set to true, a modal sheet appears.
    @State private var showingSettings = false

    var body: some View {
        VStack {
            // The main Boggle game grid. Lets the user tap/select tiles.
            // Passes the grid state, selected tiles, and a callback for selecting.
            BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)

            // Shows the remaining time in MM:SS format.
            Text("Time: \(formatTime(vm.timeRemaining))")
                .font(.title2)

            // Shows the user's current score.
            Text("Score: \(vm.score)")
                .font(.title2)

            // Shows the highest score achieved.
            Text("High Score: \(vm.highScore)")
                .font(.title2)

            // Input for the current word being built. Submits the word when user confirms.
            WordInputView(word: $vm.currentWord) {
                // When the word is submitted, send selected tiles to the view model and reset selection.
                vm.submitWord(selectedLetters: selected)
                selected.removeAll()
            }

            // Displays the list of words the user has found so far.
            List(vm.foundWords, id: \.self) { Text($0) }

            // Pushes content to the top, so UI is not cramped.
            Spacer()
        }
        .padding() // Adds padding around the VStack.
        .toolbar {
            // Adds a button in the navigation bar to show the rules/settings.
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Rules") { showingSettings = true }
            }
        }
        .alert(item: $vm.userMessage) { msg in
            // Shows an alert when vm.userMessage is set, displaying the message text.
            Alert(title: Text(msg.message))
        }
        .sheet(isPresented: $showingSettings) {
            // Shows the rules/settings screen as a modal sheet when 'showingSettings' is true.
            RuleSettingsView(vm: vm)
        }
        .onAppear { vm.startGame() } // Starts a new game when the view appears.
    }

    // Handles selection of a tile/position in the grid.
    // Only allows selection if it's touching the last selected, and not already selected.
	private func select(_ pos: Position) {
		// If the tapped tile is the last in the list, allow unselecting it ("undo" the last move)
		if selected.last == pos {
			selected.removeLast()
			vm.currentWord = selected.map { String(vm.grid[$0.row][$0.col]) }.joined()
			return
		}
		// Otherwise, only allow selection if legal
		if let last = selected.last {
			guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
		}
		if !selected.contains(pos) {
			selected.append(pos)
			vm.currentWord = selected.map { String(vm.grid[$0.row][$0.col]) }.joined()
		}
	}

    // Formats the time remaining as MM:SS.
    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
