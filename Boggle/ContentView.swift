// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

// =============================================================
// ContentView: The main view for the Boggle game UI.
// Displays the game board, timer, score, and rule access.
// =============================================================
struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var selected: [Position] = []
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.indigo.opacity(0.85), .purple.opacity(0.8)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        if vm.players.count > 1 {
                            playerPicker
                        }

                        BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)

                        WordInputView(word: $vm.currentWord,
                                      isRoundActive: vm.isRoundRunning,
                                      onClear: clearSelection,
                                      onSubmit: submitCurrentWord,
                                      onShuffle: shuffleBoard,
                                      remainingTime: vm.timeRemaining,
                                      totalTime: vm.roundDuration)

                        scoreboard
                        foundWordsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Boggle Deluxe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Rules", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                RuleSettingsView(vm: vm)
                    .presentationDetents([.medium, .large])
            }
            .alert(item: $vm.userMessage) { message in
                Alert(title: Text(message.message))
            }
            .onAppear {
                vm.startGame()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Round Timer")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(formatTime(vm.timeRemaining))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    Button(action: startNewRound) {
                        Label("New Round", systemImage: "arrow.clockwise")
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .foregroundColor(.white)

                    Text("High Score: \(vm.highScore)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            ProgressView(value: Double(vm.timeRemaining), total: Double(vm.roundDuration))
                .progressViewStyle(.linear)
                .tint(.mint)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private var playerPicker: some View {
        Picker("Active Player", selection: Binding(
            get: { vm.activePlayerID },
            set: { vm.setActivePlayer($0) }
        )) {
            ForEach(vm.players) { player in
                Text(player.name).tag(player.id)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var scoreboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scoreboard")
                .font(.title2).bold()
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(vm.players) { player in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.name)
                                .font(.headline)
                            if let minOverride = player.minimumLengthOverride {
                                Text("Min length: \(minOverride)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                        Text("\(player.score)")
                            .font(.title3).bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(player.id == vm.activePlayerID ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
    }

    private var foundWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Words Found")
                .font(.title3).bold()
                .foregroundColor(.white)

            if vm.foundWords.isEmpty {
                Text("No words submitted yet. Keep searching!")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(vm.foundWords, id: \.self) { word in
                        Text(word.uppercased())
                            .font(.headline)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
    }

    private func select(_ pos: Position) {
        guard vm.isRoundRunning else { return }
        if selected.last == pos {
            selected.removeLast()
            vm.currentWord = vm.string(for: selected)
            return
        }
        if selected.contains(pos) { return }
        if let last = selected.last {
            guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
        }
        selected.append(pos)
        vm.currentWord = vm.string(for: selected)
    }

    private func clearSelection() {
        selected.removeAll()
        vm.clearCurrentSelection()
    }

    private func submitCurrentWord() {
        vm.submitWord(selectedLetters: selected)
        clearSelection()
    }

    private func shuffleBoard() {
        vm.shuffleBoard()
        clearSelection()
    }

    private func startNewRound() {
        vm.startGame()
        clearSelection()
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
