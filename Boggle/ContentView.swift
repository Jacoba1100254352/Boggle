// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var selected: [Position] = []
    @State private var showingSettings = false

    private let heroMetricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let wordColumns = [
        GridItem(.adaptive(minimum: 130), spacing: 12)
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    boardPanel
                    heroPanel
                    wordBankPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 104)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Boggle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    vm.startGame()
                } label: {
                    Label("New Round", systemImage: "arrow.clockwise")
                        .labelStyle(.titleAndIcon)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            composerBar
        }
        .alert(item: $vm.userMessage) { msg in
            Alert(title: Text(msg.message))
        }
        .sheet(isPresented: $showingSettings) {
            RuleSettingsView(vm: vm)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if vm.grid.isEmpty {
                vm.startGame()
            }
        }
        .onChange(of: vm.grid) {
            selected.removeAll()
            vm.currentWord = ""
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 0.97),
                    Color(red: 0.78, green: 0.89, blue: 0.90),
                    Color(red: 0.67, green: 0.78, blue: 0.90)
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

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image("BoggleMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.58))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("Round Status")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.45))

                    Text(selected.isEmpty ? "Ready to trace your first word." : "Keep tracing \(vm.currentWord.uppercased()).")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    Text(vm.currentSettings.summaryText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            LazyVGrid(columns: heroMetricColumns, spacing: 12) {
                HeroMetric(title: "Time", value: formatTime(vm.timeRemaining), tint: Color(red: 0.16, green: 0.38, blue: 0.53))
                HeroMetric(title: "Score", value: "\(vm.score)", tint: Color(red: 0.17, green: 0.52, blue: 0.39))
                HeroMetric(title: "Found", value: "\(vm.foundWords.count)", tint: Color(red: 0.54, green: 0.36, blue: 0.18))
                HeroMetric(title: "Best", value: "\(vm.highScore)", tint: Color(red: 0.61, green: 0.39, blue: 0.17))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    SettingPill(label: "Board", value: vm.currentSettings.boardSize.title)
                    SettingPill(label: "Round", value: vm.currentSettings.roundDuration.title)
                    SettingPill(label: "Rules", value: activeRulesText)
                }
            }
        }
        .padding(20)
        .background(heroBackground)
    }

    private var boardPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Board")
                        .font(.headline)

                    Text("Tap neighboring tiles or finish the word in the composer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
            }

            BoggleGridView(grid: vm.grid, selectedLetters: $selected, onSelect: select)

            currentWordPanel

            HStack(spacing: 10) {
                FootnoteBadge(title: "Tiles", value: "\(selected.count)")
                FootnoteBadge(title: "Required", value: minimumWordRequirement)

                Spacer()

                if !selected.isEmpty || !vm.currentWord.isEmpty {
                    Button {
                        clearSelection()
                    } label: {
                        Text("Clear Path")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 0.45, green: 0.19, blue: 0.18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(primaryCardBackground)
    }

    private var currentWordPanel: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Word")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(vm.currentWord.isEmpty ? "Start from the board" : vm.currentWord.uppercased())
                    .font(.title3.weight(.black))
                    .foregroundStyle(vm.currentWord.isEmpty ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(selected.isEmpty ? "Tap a tile to begin." : "\(selected.count) tile\(selected.count == 1 ? "" : "s") linked")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 6) {
                Text(vm.currentWord.isEmpty ? "--" : "\(vm.currentWord.count)")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color(red: 0.15, green: 0.40, blue: 0.44))

                Text("letters")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 66, height: 66)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.84))
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private var composerBar: some View {
        VStack(spacing: 12) {
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
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.65))
                        .frame(height: 1)
                }
        )
    }

    private var wordBankPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Word Bank")
                        .font(.headline)

                    Text("Everything you lock in this round lives here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
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

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.80),
                        Color(red: 0.87, green: 0.94, blue: 0.95).opacity(0.86)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 16)
    }

    private var primaryCardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 16)
    }

    private var minimumWordRequirement: String {
        if vm.currentSettings.options.contains(.minLength) {
            return "\(vm.currentSettings.minimumWordLength)+"
        }
        return "Open"
    }

    private var activeRulesText: String {
        switch vm.currentSettings.activeRuleCount {
        case 0:
            return "Open play"
        case 1:
            return "1 enabled"
        default:
            return "\(vm.currentSettings.activeRuleCount) enabled"
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

private struct HeroMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tint.opacity(0.24), lineWidth: 1.3)
                )
        )
    }
}

private struct SettingPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.62))
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
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.56))
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
                    .foregroundStyle(.secondary)
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
                .fill(Color.white.opacity(0.60))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
        )
    }
}
