// =============================================================
// RuleSettingsView.swift
// =============================================================

import SwiftUI

/// A polished setup screen that lets the player customize a new round.
struct RuleSettingsView: View {
    @ObservedObject var vm: GameViewModel
    @State private var settings: GameSettings

    @Environment(\.dismiss) private var dismiss

    private let optionColumns = [
        GridItem(.adaptive(minimum: 132), spacing: 12)
    ]

    private let thresholdColumns = [
        GridItem(.adaptive(minimum: 92), spacing: 10)
    ]

    private let presets: [SetupPreset] = [
        SetupPreset(
            id: "classic",
            title: "Classic",
            subtitle: "4x4 board, 3 minutes, standard rules",
            settings: .classic
        ),
        SetupPreset(
            id: "casual",
            title: "Casual",
            subtitle: "Longer round with repeated words allowed",
            settings: GameSettings(
                options: [.minLength],
                minimumWordLength: 3,
                boardSize: .four,
                roundDuration: .fiveMinutes
            )
        ),
        SetupPreset(
            id: "challenge",
            title: "Challenge",
            subtitle: "5x5 board, longer words, no repeats",
            settings: GameSettings(
                options: .standard,
                minimumWordLength: 4,
                boardSize: .five,
                roundDuration: .sevenMinutes
            )
        )
    ]

    init(vm: GameViewModel) {
        self.vm = vm
        _settings = State(initialValue: vm.currentSettings)
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.98, blue: 0.98),
                        Color(red: 0.82, green: 0.90, blue: 0.94),
                        Color(red: 0.88, green: 0.94, blue: 0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        presetsCard
                        boardCard
                        timerCard
                        rulesCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 150)
                }
            }
            .navigationTitle("Game Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        settings = .classic
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                footer
            }
        }
        .navigationViewStyle(.stack)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tune the next round.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.primary)

                    Text("Pick a preset, adjust the pressure, and restart with a board that matches the pace you want.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.45))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                    )
            }

            LazyVGrid(columns: optionColumns, spacing: 12) {
                SummaryChip(title: "Board", value: settings.boardSize.title)
                SummaryChip(title: "Round", value: settings.roundDuration.title)
                SummaryChip(title: "Rules", value: "\(settings.activeRuleCount)")
            }

            Text(settings.summaryText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.31, blue: 0.37))
        }
        .padding(22)
        .background(cardBackground)
    }

    private var presetsCard: some View {
        SettingsCard(title: "Presets", subtitle: "Start from a quick format and fine-tune it.") {
            VStack(spacing: 12) {
                ForEach(presets) { preset in
                    Button {
                        settings = preset.settings
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)

                                Text(preset.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: settings == preset.settings ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(
                                    settings == preset.settings
                                    ? Color(red: 0.14, green: 0.49, blue: 0.40)
                                    : Color.secondary.opacity(0.5)
                                )
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    settings == preset.settings
                                    ? Color.white.opacity(0.95)
                                    : Color.white.opacity(0.55)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var boardCard: some View {
        SettingsCard(title: "Board Size", subtitle: "A bigger board creates more paths and longer words.") {
            LazyVGrid(columns: optionColumns, spacing: 12) {
                ForEach(BoardSize.allCases) { size in
                    ChoiceChip(
                        title: size.title,
                        subtitle: size.subtitle,
                        isSelected: settings.boardSize == size
                    ) {
                        settings.boardSize = size
                    }
                }
            }
        }
    }

    private var timerCard: some View {
        SettingsCard(title: "Round Length", subtitle: "Set the pace for each board.") {
            LazyVGrid(columns: optionColumns, spacing: 12) {
                ForEach(RoundDuration.allCases) { duration in
                    ChoiceChip(
                        title: duration.title,
                        subtitle: duration.subtitle,
                        isSelected: settings.roundDuration == duration
                    ) {
                        settings.roundDuration = duration
                    }
                }
            }
        }
    }

    private var rulesCard: some View {
        SettingsCard(title: "Rules", subtitle: "Turn scoring constraints on or off.") {
            VStack(spacing: 18) {
                ToggleRow(
                    title: "Minimum word length",
                    subtitle: "Require every submitted word to meet a minimum size.",
                    isOn: minimumLengthEnabled
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Length threshold")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(minimumLengthEnabled.wrappedValue ? Color.primary : Color.secondary)

                    LazyVGrid(columns: thresholdColumns, alignment: .leading, spacing: 10) {
                        ForEach(3...6, id: \.self) { length in
                            Button {
                                settings.minimumWordLength = length
                                settings.set(.minLength, enabled: true)
                            } label: {
                                Text("\(length) letters")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(
                                        settings.minimumWordLength == length && minimumLengthEnabled.wrappedValue
                                        ? Color.white
                                        : Color.primary
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(
                                                settings.minimumWordLength == length && minimumLengthEnabled.wrappedValue
                                                ? Color(red: 0.17, green: 0.47, blue: 0.44)
                                                : Color.white.opacity(0.7)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(!minimumLengthEnabled.wrappedValue)
                        }
                    }
                    .opacity(minimumLengthEnabled.wrappedValue ? 1 : 0.45)
                }

                Divider()

                ToggleRow(
                    title: "Unique words only",
                    subtitle: "Reject duplicate submissions during the same round.",
                    isOn: uniqueWordsOnly
                )
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("Next round")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(settings.summaryText)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            Button {
                vm.applySettings(settings)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text("Apply & Restart")
                        .font(.headline.weight(.semibold))
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.45, blue: 0.41),
                                    Color(red: 0.10, green: 0.31, blue: 0.39)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }

    private var minimumLengthEnabled: Binding<Bool> {
        Binding {
            settings.options.contains(.minLength)
        } set: { isEnabled in
            settings.set(.minLength, enabled: isEnabled)
        }
    }

    private var uniqueWordsOnly: Binding<Bool> {
        Binding {
            settings.options.contains(.uniqueWords)
        } set: { isEnabled in
            settings.set(.uniqueWords, enabled: isEnabled)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 18)
    }
}

private struct SetupPreset: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let settings: GameSettings
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 16)
        )
    }
}

private struct ChoiceChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.82) : Color.secondary)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(16)
            .frame(minHeight: 92)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.47, blue: 0.47),
                                Color(red: 0.11, green: 0.26, blue: 0.36)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.white.opacity(0.58)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected ? Color.white.opacity(0.28) : Color.white.opacity(0.72),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.15, green: 0.44, blue: 0.39))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }
}

private struct SummaryChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.74))
        )
    }
}
