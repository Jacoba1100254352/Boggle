// =============================================================
// RuleSettingsView.swift – Configuration UI for rules & players
// =============================================================

import SwiftUI

struct RuleSettingsView: View {
    @ObservedObject var vm: GameViewModel
    @State private var draftSettings: GameSettings
    @State private var draftPlayers: [PlayerProfile]
    @Environment(\.dismiss) private var dismiss

    init(vm: GameViewModel) {
        self.vm = vm
        _draftSettings = State(initialValue: vm.settings)
        _draftPlayers = State(initialValue: vm.playerStates.map { $0.profile })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer") {
                    Stepper(value: $draftSettings.roundLength, in: 30...600, step: 30) {
                        Text("Round length: \(formattedTime(draftSettings.roundLength))")
                    }
                }

                Section("Global rules") {
                    Stepper(value: $draftSettings.minimumWordLength, in: 2...8) {
                        Text("Minimum word length: \(draftSettings.minimumWordLength) letters")
                    }

                    Toggle("Require unique words across all players", isOn: $draftSettings.enforceUniqueWords)
                    Toggle("Highlight last accepted word", isOn: $draftSettings.highlightLastWord)
                }

                Section("Players") {
                    if draftPlayers.isEmpty {
                        Text("Add at least one player to start a game.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach($draftPlayers) { $player in
                        PlayerEditorRow(player: $player, defaultMinimum: draftSettings.minimumWordLength)
                    }
                    .onDelete { indexSet in
                        draftPlayers.remove(atOffsets: indexSet)
                    }

                    Button {
                        let newIndex = draftPlayers.count + 1
                        draftPlayers.append(PlayerProfile(name: "Player \(newIndex)"))
                    } label: {
                        Label("Add player", systemImage: "plus.circle.fill")
                    }
                }

                Section("Utilities") {
                    Button("Restore defaults") {
                        draftSettings = defaultSettings
                        draftPlayers = defaultPlayers
                    }
                }
            }
            .navigationTitle("Rules & Settings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.apply(settings: draftSettings, players: draftPlayers)
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

private struct PlayerEditorRow: View {
    @Binding var player: PlayerProfile
    let defaultMinimum: Int

    private var usesOverride: Binding<Bool> {
        Binding {
            player.minWordLengthOverride != nil
        } set: { newValue in
            player.minWordLengthOverride = newValue ? max(2, defaultMinimum) : nil
        }
    }

    private var overrideValue: Binding<Int> {
        Binding {
            player.minWordLengthOverride ?? max(2, defaultMinimum)
        } set: { newValue in
            player.minWordLengthOverride = max(2, newValue)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Player name", text: $player.name)

            Toggle("Custom minimum word length", isOn: usesOverride)

            if usesOverride.wrappedValue {
                Stepper(value: overrideValue, in: 2...10) {
                    Text("Minimum letters: \(overrideValue.wrappedValue)")
                }
            } else {
                Text("Uses global minimum of \(defaultMinimum) letters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
