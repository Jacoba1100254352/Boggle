// =============================================================
// RuleSettingsView.swift
// =============================================================

import SwiftUI

/// A SwiftUI view that allows the user to configure game rule options,
/// round duration, and player-specific handicaps.
struct RuleSettingsView: View {

    @ObservedObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    init(vm: GameViewModel) {
        self.vm = vm
    }

    var body: some View {
        NavigationStack {
            Form {
                roundSection
                rulesSection
                playersSection
            }
            .navigationTitle("Rules & Options")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var roundSection: some View {
        Section("Round") {
            Slider(value: Binding(
                get: { Double(vm.roundDuration) },
                set: { vm.updateRoundDuration(Int($0)) }
            ), in: 60...420, step: 30) {
                Text("Round Length")
            } minimumValueLabel: {
                Text("1 min")
            } maximumValueLabel: {
                Text("7 min")
            }

            Text("Current: \(vm.roundDuration / 60) min \(vm.roundDuration % 60) sec")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var rulesSection: some View {
        Section("Rules") {
            Toggle("Unique words only", isOn: Binding(
                get: { vm.isRuleEnabled(.uniqueWords) },
                set: { vm.setRule(.uniqueWords, enabled: $0) }
            ))

            Toggle("Enforce minimum length", isOn: Binding(
                get: { vm.isRuleEnabled(.minLength) },
                set: { vm.setRule(.minLength, enabled: $0) }
            ))

            if vm.isRuleEnabled(.minLength) {
                Stepper(value: Binding(
                    get: { vm.baseMinimumLength },
                    set: { vm.updateBaseMinimumLength($0) }
                ), in: 2...8) {
                    Text("Base minimum length: \(vm.baseMinimumLength)")
                }
            }
        }
    }

    private var playersSection: some View {
        Section {
            ForEach(vm.players) { player in
                playerRow(for: player)
            }
            .onDelete(perform: vm.removePlayers)

            Button {
                vm.addPlayer()
            } label: {
                Label("Add Player", systemImage: "plus.circle")
            }
        } header: {
            Text("Player Handicaps")
        } footer: {
            Text("Set per-player minimum lengths to create handicaps or advantages. Leave off to use the base rule.")
        }
    }

    private func playerRow(for player: PlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Player name", text: Binding(
                get: { player.name },
                set: { vm.rename(player: player.id, to: $0) }
            ))

            Toggle("Custom minimum length", isOn: Binding(
                get: { player.minimumLengthOverride != nil },
                set: { useCustom in
                    let current = player.minimumLengthOverride ?? vm.baseMinimumLength
                    vm.setMinimumLengthOverride(useCustom ? current : nil, for: player.id)
                }
            ))

            if player.minimumLengthOverride != nil {
                Stepper(value: minimumLengthBinding(for: player), in: 2...8) {
                    Text(minimumLengthLabel(for: player))
                }
            }
        }
    }

    private func minimumLengthBinding(for player: PlayerProfile) -> Binding<Int> {
        Binding(
            get: { vm.players.first(where: { $0.id == player.id })?.minimumLengthOverride ?? vm.baseMinimumLength },
            set: { vm.setMinimumLengthOverride($0, for: player.id) }
        )
    }

    private func minimumLengthLabel(for player: PlayerProfile) -> String {
        let override = vm.players.first(where: { $0.id == player.id })?.minimumLengthOverride ?? vm.baseMinimumLength
        return "Custom minimum: \(override)"
    }
}
