// =============================================================
// RuleSettingsView.swift
// =============================================================

import SwiftUI

struct RuleSettingsView: View {
    @ObservedObject var vm: GameViewModel

    @State private var config: RuleConfiguration
    @State private var players: [Player]

    @Environment(\.dismiss) private var dismiss

    init(vm: GameViewModel) {
        self.vm = vm
        _config = State(initialValue: vm.configuration)
        _players = State(initialValue: vm.players)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Round settings") {
                    Stepper(value: $config.roundDuration, in: 60...600, step: 30) {
                        let minutes = config.roundDuration / 60
                        let seconds = config.roundDuration % 60
                        Text("Round length: \(minutes)m \(String(format: "%02ds", seconds))")
                    }
                    Stepper(value: $config.minimumWordLength, in: 2...8) {
                        Text("Minimum letters: \(config.minimumWordLength)")
                    }
                    Toggle("Reject duplicate words", isOn: $config.enforceUniqueWords)
                } footer: {
                    Text("Adjust the standard Boggle rules. Rounds last between 1 and 10 minutes; minimum length can drop as low as 2 letters if you want a gentler game.")
                }

                Section("Players & handicaps") {
                    ForEach($players) { $player in
                        PlayerSettingsRow(player: $player, defaultMinimum: config.minimumWordLength)
                    }
                    .onDelete { indexSet in
                        players.remove(atOffsets: indexSet)
                    }

                    Button {
                        players.append(Player(name: "Player \(players.count + 1)"))
                    } label: {
                        Label("Add player", systemImage: "plus.circle.fill")
                    }
                } footer: {
                    Text("Override the minimum word length for individual players to introduce handicaps or advantages.")
                }
            }
            .navigationTitle("Rules & Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
            }
            .onChange(of: config) { newConfig in
                vm.updateConfiguration(newConfig)
            }
            .onChange(of: players) { newPlayers in
                vm.updatePlayers(newPlayers)
                if vm.players != newPlayers {
                    players = vm.players
                }
            }
            .onAppear {
                config = vm.configuration
                players = vm.players
            }
        }
    }
}

private struct PlayerSettingsRow: View {
    @Binding var player: Player
    let defaultMinimum: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Player name", text: $player.name)

            Toggle("Use default minimum", isOn: Binding(
                get: { player.minimumWordLengthOverride == nil },
                set: { newValue in
                    if newValue {
                        player.minimumWordLengthOverride = nil
                    } else {
                        player.minimumWordLengthOverride = max(2, defaultMinimum)
                    }
                }
            ))

            if player.minimumWordLengthOverride != nil {
                Stepper(value: Binding(
                    get: { player.minimumWordLengthOverride ?? defaultMinimum },
                    set: { player.minimumWordLengthOverride = max(2, min(8, $0)) }
                ), in: 2...8) {
                    Text("Minimum letters: \(player.minimumWordLengthOverride ?? defaultMinimum)")
                }
            } else {
                Text("Minimum letters: \(defaultMinimum)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
