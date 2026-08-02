// =============================================================
// ContentView.swift
// =============================================================

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = GameViewModel()
    @State private var selected: [Position] = []
    @State private var showingSettings = false
    @State private var showingRestartConfirmation = false
    @State private var selectedSolution: BoardWordMatch?

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
                    if vm.isRoundOver {
                        roundReviewPanel
                    } else {
                        wordBankPanel
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 136)
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            if vm.isRoundOver {
                roundOverBar
            } else {
                composerBar
            }
        }
        .sheet(isPresented: $showingSettings) {
            RuleSettingsView(vm: vm)
        }
        .sheet(item: $selectedSolution) { match in
            WordPathPreviewSheet(
                grid: vm.grid,
                match: match,
                isFound: foundWordSet.contains(match.word)
            )
        }
        .confirmationDialog(
            "Start a new round?",
            isPresented: $showingRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start New Round", role: .destructive) {
                vm.startGame()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your current board, words, and score will be replaced.")
        }
        .onAppear {
            if vm.grid.isEmpty {
                vm.startGame()
            }
        }
        .onChange(of: vm.grid) {
            selected.removeAll()
            selectedSolution = nil
            vm.currentWord = ""
        }
        .onChange(of: vm.timeRemaining) { _, newValue in
            if newValue == 0 {
                clearSelection()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                vm.refreshTimer()
            }
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
                TopBarButton(systemName: "arrow.clockwise", accessibilityLabel: "Start new round") {
                    requestNewRound()
                }
                .accessibilityIdentifier("newRoundButton")

                Spacer()

                TopBarButton(systemName: "slider.horizontal.3", accessibilityLabel: "Game settings") {
                    showingSettings = true
                }
                .accessibilityIdentifier("gameSettingsButton")
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
                    .accessibilityHidden(true)

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

                Text(vm.isRoundOver ? "Round over. Review every playable word below." : "Drag or tap letters, then submit.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
            }

            BoggleGridView(grid: vm.grid, selectedLetters: $selected, isInteractive: !vm.isRoundOver, onSelect: select)

            HStack(spacing: 10) {
                FootnoteBadge(title: "Required", value: minimumWordRequirement)
                FootnoteBadge(
                    title: vm.isRoundOver ? "Available" : "Linked",
                    value: vm.isRoundOver
                        ? (vm.isSearchingAvailableWords ? "..." : "\(vm.availableWords.count)")
                        : "\(selected.count)"
                )

                Spacer()
            }
        }
        .padding(20)
        .background(primaryCardBackground)
    }

    private var composerBar: some View {
        VStack(spacing: 10) {
            if let message = vm.userMessage {
                SubmissionMessageView(message: message.message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                Text(vm.currentWord.isEmpty ? "Start tracing" : vm.currentWord.uppercased())
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(
                        vm.currentWord.isEmpty
                            ? Color(red: 0.40, green: 0.48, blue: 0.53)
                            : Color(red: 0.10, green: 0.20, blue: 0.28)
                    )
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
                onClear: clearSelection,
                onWordEdited: {
                    selected.removeAll()
                    vm.clearUserMessage()
                }
            ) {
                if vm.submitWord(selectedLetters: selected) {
                    selected.removeAll()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.userMessage)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
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

    private var roundOverBar: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round over")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.09, green: 0.19, blue: 0.28))

                    Text(vm.isSearchingAvailableWords ? "Analyzing the board..." : "Tap any available word to preview its path.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
                        .lineLimit(2)
                }

                Spacer()

                Button("New Round") {
                    vm.startGame()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.19, green: 0.52, blue: 0.39),
                                    Color(red: 0.12, green: 0.35, blue: 0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .accessibilityIdentifier("roundOverNewRoundButton")
            }

            HStack(spacing: 10) {
                FootnoteBadge(title: "Found", value: "\(vm.foundWords.count)")
                FootnoteBadge(title: "Available", value: vm.isSearchingAvailableWords ? "..." : "\(vm.availableWords.count)")
                FootnoteBadge(title: "Coverage", value: solutionCoverage)
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 16)
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
                    Text("Trace connected tiles or type a word that can be made on this board.")
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

    private var roundReviewPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round Review")
                        .font(.headline)

                    Text(vm.isSearchingAvailableWords ? "Building the full solution list for this board." : "Tap a word to see the path that spells it on the board.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
                }

                Spacer()

                Text(vm.isSearchingAvailableWords ? "..." : "\(vm.availableWords.count)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.12, green: 0.34, blue: 0.42))
            }

            HStack(spacing: 10) {
                FootnoteBadge(title: "Found", value: "\(vm.foundWords.count)")
                FootnoteBadge(title: "Missed", value: "\(missedWords.count)")
                FootnoteBadge(title: "Coverage", value: solutionCoverage)
            }

            if vm.isSearchingAvailableWords {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(Color(red: 0.15, green: 0.39, blue: 0.45))

                    Text("Searching the board for every playable word.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )
            } else if vm.availableWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No playable words found")
                        .font(.headline)
                    Text("This board did not produce any dictionary matches under the active rules.")
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
                LazyVStack(spacing: 12) {
                    ForEach(vm.availableWords) { match in
                        Button {
                            selectedSolution = match
                        } label: {
                            SolutionWordRow(
                                match: match,
                                isFound: foundWordSet.contains(match.word)
                            )
                        }
                        .buttonStyle(.plain)
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

    private var minimumRequirementBadgeText: String {
        if vm.currentSettings.options.contains(.minLength) {
            return "Min \(vm.currentSettings.minimumWordLength)+"
        }

        return "No minimum"
    }

    private var foundWordSet: Set<String> {
        Set(vm.foundWords)
    }

    private var missedWords: [BoardWordMatch] {
        vm.availableWords.filter { !foundWordSet.contains($0.word) }
    }

    private var solutionCoverage: String {
        guard !vm.availableWords.isEmpty else { return "0%" }
        let ratio = Double(foundWordSet.count) / Double(vm.availableWords.count)
        return "\(Int((ratio * 100).rounded()))%"
    }

    private var currentWordPreviewScore: Int {
        GameViewModel.score(for: vm.currentWord)
    }

    private func clearSelection() {
        selected.removeAll()
        vm.currentWord = ""
        vm.clearUserMessage()
    }

    private func select(_ pos: Position) {
        guard !vm.isRoundOver else { return }
        vm.clearUserMessage()

        if selected.last == pos {
            selected.removeLast()
            syncCurrentWord()
            return
        }

        if selected.count >= 2, selected[selected.count - 2] == pos {
            selected.removeLast()
            syncCurrentWord()
            return
        }

        if let last = selected.last {
            guard abs(last.row - pos.row) <= 1 && abs(last.col - pos.col) <= 1 else { return }
        }

        if !selected.contains(pos) {
            selected.append(pos)
            syncCurrentWord()
        }
    }

    private func syncCurrentWord() {
        vm.currentWord = selected.map { vm.grid[$0.row][$0.col] }.joined()
    }

    private func requestNewRound() {
        if vm.isRoundOver || (vm.foundWords.isEmpty && vm.currentWord.isEmpty) {
            vm.startGame()
        } else {
            showingRestartConfirmation = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct TopBarButton: View {
    let systemName: String
    let accessibilityLabel: String
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
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct SubmissionMessageView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(red: 0.46, green: 0.20, blue: 0.16))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.98, green: 0.91, blue: 0.88))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Word not accepted. \(message)")
        .accessibilityIdentifier("submissionMessage")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
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

                Text("\(GameViewModel.score(for: word)) pts")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Word \(rank), \(word), \(word.count) letters, \(GameViewModel.score(for: word)) points")
    }
}

private struct SolutionWordRow: View {
    let match: BoardWordMatch
    let isFound: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(match.word.uppercased())
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color(red: 0.09, green: 0.18, blue: 0.26))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if isFound {
                        Text("FOUND")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color(red: 0.12, green: 0.35, blue: 0.32))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(red: 0.88, green: 0.96, blue: 0.92))
                            )
                    }
                }

                Text("\(match.word.count) letters • \(GameViewModel.score(for: match.word)) pts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.39, green: 0.46, blue: 0.52))
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 0.28, green: 0.44, blue: 0.50))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            isFound
                                ? Color(red: 0.25, green: 0.63, blue: 0.48).opacity(0.24)
                                : Color.white.opacity(0.92),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(match.word), \(match.word.count) letters, \(GameViewModel.score(for: match.word)) points, \(isFound ? "found" : "missed")"
        )
    }
}

private struct WordPathPreviewSheet: View {
    let grid: [[String]]
    let match: BoardWordMatch
    let isFound: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Text(match.word.uppercased())
                                .font(.largeTitle.weight(.black))
                                .foregroundStyle(Color(red: 0.08, green: 0.17, blue: 0.25))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            if isFound {
                                Text("FOUND")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(Color(red: 0.12, green: 0.35, blue: 0.32))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color(red: 0.88, green: 0.96, blue: 0.92))
                                    )
                            }
                        }

                        Text("Highlighted in play order on the round board.")
                            .font(.subheadline)
                            .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.48))

                        HStack(spacing: 10) {
                            FootnoteBadge(title: "Letters", value: "\(match.word.count)")
                            FootnoteBadge(title: "Score", value: "\(GameViewModel.score(for: match.word))")
                            FootnoteBadge(title: "Path", value: "\(match.path.count)")
                        }
                    }

                    WordPathBoardPreview(grid: grid, path: match.path)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.98, blue: 0.98),
                        Color(red: 0.83, green: 0.90, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.bold))
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct WordPathBoardPreview: View {
    let grid: [[String]]
    let path: [Position]

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: grid.count == 5 ? 8 : 10), count: max(grid.count, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Board path")
                .font(.headline)
                .foregroundStyle(Color(red: 0.09, green: 0.18, blue: 0.26))

            LazyVGrid(columns: columns, spacing: grid.count == 5 ? 8 : 10) {
                ForEach(grid.indices.flatMap { row in
                    grid[row].indices.map { Position(row: row, col: $0) }
                }, id: \.self) { position in
                    let selectionIndex = path.firstIndex(of: position)

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: selectionIndex == nil
                                        ? [
                                            Color.white,
                                            Color(red: 0.86, green: 0.92, blue: 0.96)
                                        ]
                                        : [
                                            Color(red: 0.19, green: 0.57, blue: 0.50),
                                            Color(red: 0.11, green: 0.33, blue: 0.38)
                                        ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        selectionIndex == nil
                                            ? Color(red: 0.28, green: 0.42, blue: 0.52).opacity(0.14)
                                            : Color.white.opacity(0.78),
                                        lineWidth: selectionIndex == nil ? 1 : 2
                                    )
                            )

                        Text(grid[position.row][position.col])
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(selectionIndex == nil ? Color(red: 0.12, green: 0.22, blue: 0.30) : Color.white)
                    }
                    .overlay(alignment: .topTrailing) {
                        if let selectionIndex {
                            Text("\(selectionIndex + 1)")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color(red: 0.09, green: 0.28, blue: 0.33))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.94))
                                )
                                .padding(7)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(
                        color: Color.black.opacity(selectionIndex == nil ? 0.06 : 0.14),
                        radius: selectionIndex == nil ? 8 : 14,
                        x: 0,
                        y: selectionIndex == nil ? 6 : 10
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.94), lineWidth: 1)
                    )
            )
        }
    }
}
