// =============================================================
// ContentView.swift – Primary game interface
// =============================================================

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.indigo, .blue.opacity(0.7), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        scoreboardSection
                        BoggleGridView(grid: vm.board, highlightedPath: vm.highlightedPath)
                        WordInputView(word: $vm.currentWord,
                                      minimumLength: vm.activePlayerMinimumLength,
                                      isEnabled: vm.isRoundActive) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                vm.submitCurrentWord()
                            }
                        }
                        foundWordsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Boggle Deluxe")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            vm.startGame()
                        }
                    } label: {
                        Label("New Round", systemImage: "arrow.clockwise.circle.fill")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                RuleSettingsView(vm: vm)
            }
            .alert(item: $vm.userMessage) { message in
                Alert(title: Text(message.message))
            }
            .onAppear {
                vm.ensureGameStarted()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Time left: \(formatTime(vm.timeRemaining))", systemImage: "timer")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Label("High score: \(vm.highScore)", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.yellow)
            }

            ProgressView(value: Double(vm.timeRemaining), total: Double(max(vm.settings.roundLength, 1)))
                .tint(.mint)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

            HStack {
                Label("Active player: \(vm.activePlayerName.isEmpty ? "—" : vm.activePlayerName)", systemImage: "person.fill")
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.shuffleBoard()
                    }
                } label: {
                    Label("Shuffle dice", systemImage: "shuffle")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15), in: Capsule())
                }
                .disabled(!vm.isRoundActive)
                .opacity(vm.isRoundActive ? 1 : 0.5)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
    }

    private var scoreboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scoreboard")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.playerStates) { player in
                        PlayerSummaryCard(player: player,
                                           minimumLength: player.minimumWordLengthOverride ?? vm.settings.minimumWordLength,
                                           isActive: player.id == vm.activePlayer?.id,
                                           onSelect: { withAnimation(.easeInOut(duration: 0.25)) { vm.selectPlayer(player.id) } })
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var foundWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(vm.activePlayerName.isEmpty ? "Found words" : "\(vm.activePlayerName)'s words")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("Total: \(vm.foundWords.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if vm.foundWords.isEmpty {
                Text("Play a word to see it appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(vm.foundWords, id: \.self) { word in
                        HStack {
                            Text(word.uppercased())
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("+\(vm.scoreForWord(word))")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}

private struct PlayerSummaryCard: View {
    let player: PlayerState
    let minimumLength: Int
    let isActive: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(player.profile.name)
                        .font(.headline)
                    Spacer()
                    if isActive {
                        Label("Current", systemImage: "sparkles")
                            .font(.caption.bold())
                            .padding(6)
                            .background(Color.white.opacity(0.2), in: Capsule())
                    }
                }

                Text("Score: \(player.score)")
                    .font(.title3.bold())

                Text("Words: \(player.words.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Minimum letters: \(minimumLength)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(width: 200, alignment: .leading)
            .background(cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(isActive ? 0.6 : 0.25), lineWidth: isActive ? 3 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var cardGradient: LinearGradient {
        if isActive {
            return LinearGradient(colors: [Color.mint.opacity(0.9), Color.teal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
