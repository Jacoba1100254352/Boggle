// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var selected: [Position] = []
    @State private var showingSettings = false

    private let wordColumns = [
        GridItem(.adaptive(minimum: 130), spacing: 12)
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    topBar
                    statusRail
                    boardPanel
                    wordBankPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 104)
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            composerBar
        }
        .alert(item: $vm.userMessage) { msg in
            Alert(title: Text(msg.message))
        }
        .sheet(isPresented: $showingSettings) {
            RuleSettingsView(vm: vm)
        }
        .onAppear {
            if vm.grid.isEmpty {
                vm.startGame()
            }
        }
        .onChange(of: vm.grid) { _ in
            selected.removeAll()
            vm.currentWord = ""
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 0.98),
                    Color(red: 0.78, green: 0.88, blue: 0.92),
                    Color(red: 0.62, green: 0.76, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 260)
                .blur(radius: 8)
                .offset(x: -110, y: -300)

            Circle()
                .fill(Color(red: 0.32, green: 0.63, blue: 0.70).opacity(0.18))
                .frame(width: 320)
                .blur(radius: 24)
                .offset(x: 140, y: 250)
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                TopBarButton(systemName: "arrow.clockwise") {
                    vm.startGame()
                }

                Spacer()

                TopBarButton(systemName: "slider.horizontal.3") {
                    showingSettings = true
                }
            }

            HStack(spacing: 8) {
                Image("BoggleMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Color.white.opacity(0.62))
                    )

                Text("Boggle")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .frame(height: 44)
    }

    private var statusRail: some View {
        HStack(spacing: 10) {
            StatusChip(title: "Time", value: formatTime(vm.timeRemaining), tint: Color(red: 0.16, green: 0.38, blue: 0.53))
            StatusChip(title: "Score", value: "\(vm.score)", tint: Color(red: 0.17, green: 0.52, blue: 0.39))
            StatusChip(title: "Best", value: "\(vm.highScore)", tint: Color(red: 0.61, green: 0.39, blue: 0.17))
        }
    }

    private var boardPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text("Board")
                        .font(.headline)

                    Spacer()

                    Text(vm.currentSettings.boardSize.title)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.12, green: 0.30, blue: 0.39).opacity(0.10))
                        )
                        .foregroundStyle(Color(red: 0.13, green: 0.31, blue: 0.39))

                    FootnoteBadge(title: "Found", value: "\(vm.foundWords.count)")
                }

                Text("Trace letters, then submit.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
            }

            BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)

            HStack(spacing: 10) {
                FootnoteBadge(title: "Required", value: minimumWordRequirement)
                FootnoteBadge(title: "Linked", value: "\(selected.count)")

                Spacer()
            }
        }
        .padding(20)
        .background(primaryCardBackground)
    }

    private var composerBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(vm.currentWord.isEmpty ? "Start tracing" : vm.currentWord.uppercased())
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(vm.currentWord.isEmpty ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(vm.currentWord.isEmpty ? minimumRequirementBadgeText : "+\(currentWordPreviewScore) pts")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.11, green: 0.35, blue: 0.39))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.88))
                    )
            }

            WordInputView(
                word: $vm.currentWord,
                canClear: !selected.isEmpty || !vm.currentWord.isEmpty,
                onClear: clearSelection
            ) {
                vm.submitWord(selectedLetters: selected)
                selected.removeAll()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(Color.white)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.69, green: 0.81, blue: 0.87).opacity(0.55))
                        .frame(height: 1)
                }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -4)
    }

    private var wordBankPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Word Bank")
                        .font(.headline)

                    Text("Everything you lock in this round lives here.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
                }

                Spacer()

                Text("\(vm.foundWords.count)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.12, green: 0.34, blue: 0.42))
            }

            if vm.foundWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No words yet")
                        .font(.headline)
                    Text("Build one from the board or type it into the composer below to start your streak.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )
            } else {
                LazyVGrid(columns: wordColumns, spacing: 12) {
                    ForEach(Array(vm.foundWords.enumerated()), id: \.offset) { index, word in
                        WordBankCard(rank: index + 1, word: word)
                    }
                }
            }
        }
        .padding(20)
        .background(primaryCardBackground)
    }

    private var primaryCardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 24, x: 0, y: 16)
    }

    private var minimumWordRequirement: String {
        if vm.currentSettings.options.contains(.minLength) {
            return "\(vm.currentSettings.minimumWordLength)+"
        }
        return "Open"
    }

    private var minimumRequirementDescription: String {
        if vm.currentSettings.options.contains(.minLength) {
            return "Minimum \(vm.currentSettings.minimumWordLength) letters."
        }

        return "No minimum length."
    }

    private var minimumRequirementBadgeText: String {
        if vm.currentSettings.options.contains(.minLength) {
            return "Min \(vm.currentSettings.minimumWordLength)+"
        }

        return "No minimum"
    }

    private var currentWordPreviewScore: Int {
        switch vm.currentWord.count {
        case 0...2:
            return 0
        case 3...4:
            return 1
        case 5:
            return 2
        case 6:
            return 3
        case 7:
            return 5
        default:
            return 11
        }
    }

    private func clearSelection() {
        selected.removeAll()
        vm.currentWord = ""
    }

    private func select(_ pos: Position) {
        if selected.last == pos {
            selected.removeLast()
            vm.currentWord = selected.map { String(vm.grid[$0.row][$0.col]) }.joined()
            return
        }

        if let last = selected.last {
            guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
        }

        if !selected.contains(pos) {
            selected.append(pos)
            vm.currentWord = selected.map { String(vm.grid[$0.row][$0.col]) }.joined()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct TopBarButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.10, green: 0.31, blue: 0.39))
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.84))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.95), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct StatusChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.46, blue: 0.52))

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.22))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1.2)
                )
        )
    }
}

private struct FootnoteBadge: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.39, green: 0.46, blue: 0.52))

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.22))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
    }
}

private struct WordBankCard: View {
    let rank: Int
    let word: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("#\(rank)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.45))

                Spacer()

                Text("\(word.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.39, green: 0.46, blue: 0.52))
            }

            Text(word.uppercased())
                .font(.body.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(Color.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.92), lineWidth: 1)
                )
        )
    }
}
