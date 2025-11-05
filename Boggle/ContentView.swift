// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var selected: [Position] = []
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.purple.opacity(0.25), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    header
                    scoreboard
                    BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    selectedWordCard

                    if vm.players.count > 1 {
                        playerPicker
                    }

                    WordInputView(word: $vm.currentWord, onSubmit: playCurrentWord, onClear: clearSelection)
                        .padding(.horizontal, 8)

                    wordHistory
                }
                .padding()
            }
            .navigationTitle("Boggle Deluxe")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: vm.startGame) {
                        Label("New Round", systemImage: "arrow.clockwise.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Label("Rules", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                RuleSettingsView(vm: vm)
                    .presentationDetents([.medium, .large])
            }
            .alert(item: $vm.userMessage) { Alert(title: Text($0.message)) }
            .onAppear { vm.startGame() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Time: \(formatTime(vm.timeRemaining))", systemImage: "timer")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                Spacer()
                Text("High Score: \(vm.highScore)")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }

            ProgressView(value: progressValue)
                .tint(.mint)
                .padding(.trailing, 12)
        }
    }

    private var scoreboard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.players) { player in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(player.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                            if player.id == vm.activePlayerID {
                                Image(systemName: "star.fill").foregroundColor(.yellow)
                            }
                        }
                        Text("Score: \(player.score)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        Text("Min length: \(player.minimumWordLength(default: vm.configuration.minimumWordLength))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(player.id == vm.activePlayerID ? Color.blue.opacity(0.75) : Color.black.opacity(0.35))
                    )
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var playerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active player")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Picker("Active Player", selection: $vm.activePlayerID) {
                ForEach(vm.players) { player in
                    Text(player.displayName).tag(player.id)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    private var selectedWordCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current word")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            HStack {
                Text(vm.currentWord.isEmpty ? "Tap letters or type" : vm.currentWord.uppercased())
                    .font(.title2.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                if !selected.isEmpty {
                    Button(action: clearSelection) {
                        Label("Undo", systemImage: "arrow.uturn.left.circle")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.35)))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private var wordHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Words found")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)

            if vm.wordLog.isEmpty {
                Text("Play a word to start scoring!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.wordLog) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.word)
                                        .font(.headline)
                                    Text(entry.playerName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("+\(entry.points)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.9)))
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func playCurrentWord() {
        vm.submitWord(selectedLetters: selected)
        clearSelection()
    }

    private func clearSelection() {
        selected.removeAll()
        vm.currentWord = ""
    }

    private func select(_ pos: Position) {
        guard vm.grid.indices.contains(pos.row), vm.grid[pos.row].indices.contains(pos.col) else { return }
        if selected.last == pos {
            selected.removeLast()
        } else {
            if let last = selected.last {
                guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
            }
            guard !selected.contains(pos) else { return }
            selected.append(pos)
        }
        vm.currentWord = selected.map { vm.grid[$0.row][$0.col].text }.joined()
    }

    private func formatTime(_ s: Int) -> String {
        let minutes = s / 60
        let seconds = s % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progressValue: Double {
        let total = max(1, vm.configuration.roundDuration)
        let ratio = Double(vm.timeRemaining) / Double(total)
        return min(1, max(0, ratio))
    }
}
