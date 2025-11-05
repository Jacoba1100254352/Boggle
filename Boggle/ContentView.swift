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
    @State private var selected: [Position] = [] // Tracks the path for the in-progress word

    // Controls if the settings/rules sheet is shown.
    // When set to true, a modal sheet appears.
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.indigo.opacity(0.85), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    header

                    BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 10)
                        )

                    currentWordSection

                    foundWordsSection

                    Spacer(minLength: 10)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Boggle Deluxe")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            vm.startGame()
                            selected.removeAll()
                        } label: {
                            Label("New Round", systemImage: "arrow.clockwise")
                        }

                        Button(role: .destructive) {
                            vm.resetGame()
                            selected.removeAll()
                        } label: {
                            Label("Reset Score", systemImage: "gobackward")
                        }

                        Divider()

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Customize Rules", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .alert(item: $vm.userMessage) { msg in
                Alert(title: Text(msg.message))
            }
            .sheet(isPresented: $showingSettings) {
                RuleSettingsView(vm: vm)
            }
            .onAppear { vm.startGame() }
            .onChange(of: vm.grid) { _ in
                selected.removeAll()
                vm.currentWord = ""
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(title: "Time", value: formatTime(vm.timeRemaining), systemImage: "timer")
                StatCard(title: "Score", value: "\(vm.score)", systemImage: "star.fill")
                StatCard(title: "Best", value: "\(vm.highScore)", systemImage: "trophy.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 10)

            ruleInfoCard
        }
    }

    private var ruleInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Rule Set", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            Menu {
                Button {
                    vm.activeHandicapID = nil
                } label: {
                    label(for: "Standard Rules", isActive: vm.activeHandicapID == nil)
                }

                if !vm.ruleConfiguration.handicaps.isEmpty {
                    Section("Handicaps") {
                        ForEach(vm.ruleConfiguration.handicaps) { handicap in
                            Button {
                                vm.activeHandicapID = handicap.id
                            } label: {
                                label(for: handicap.name, isActive: vm.activeHandicapID == handicap.id)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Label(vm.activeHandicapName ?? "Standard Rules", systemImage: "person.2.fill")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Minimum word length: \(vm.activeMinWordLength) letters")
                Text("Round length: \(formatTime(vm.activeRoundDuration))")
                Text(vm.ruleConfiguration.requireUniqueWords ? "Duplicate words disabled" : "Duplicate words allowed")
            }
            .font(.footnote)
            .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 8)
    }

    private var currentWordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Word")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Letters: \(vm.currentWord.count)")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            WordInputView(word: $vm.currentWord) {
                vm.submitWord(selectedLetters: selected)
                selected.removeAll()
            }

            HStack {
                Button(role: .cancel) {
                    selected.removeAll()
                    vm.currentWord = ""
                } label: {
                    Label("Clear Selection", systemImage: "delete.left")
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)

                Spacer()

                Text("Need at least \(vm.activeMinWordLength) letters")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 8)
    }

    private var foundWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Found Words")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(vm.foundWords.count)")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            if vm.foundWords.isEmpty {
                Text("No words yet — tap letters to build one!")
                    .font(.callout)
                    .foregroundStyle(Color.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.foundWords, id: \.self) { word in
                            HStack {
                                Text(word.uppercased())
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("+\(vm.points(for: word))")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.green.opacity(0.3), in: Capsule())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 8)
    }

    private func label(for name: String, isActive: Bool) -> some View {
        HStack {
            Text(name)
            if isActive {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }


    // Handles selection of a tile/position in the grid.
    // Only allows selection if it's touching the last selected, and not already selected.
    private func select(_ pos: Position) {
        if selected.last == pos {
            selected.removeLast()
            vm.currentWord = selected.map { vm.grid[$0.row][$0.col] }.joined()
            return
        }
        if let last = selected.last {
            guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
        }
        if !selected.contains(pos) {
            selected.append(pos)
            vm.currentWord = selected.map { vm.grid[$0.row][$0.col] }.joined()
        }
    }

    // Formats the time remaining as MM:SS.
    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Supporting views

private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
