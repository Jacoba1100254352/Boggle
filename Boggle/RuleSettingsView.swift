// =============================================================
// RuleSettingsView.swift
// =============================================================

import SwiftUI

/// A SwiftUI view that allows the user to configure the full Boggle rule set,
/// including round duration, board size, base rules, and individual handicaps.
struct RuleSettingsView: View {

    @ObservedObject var vm: GameViewModel
    @State private var draft: RuleConfiguration
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedHandicap: PlayerHandicap.ID?

    init(vm: GameViewModel) {
        self.vm = vm
        _draft = State(initialValue: vm.ruleConfiguration)
    }

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                wordRulesSection
                handicapsSection
            }
            .navigationTitle("Rules & Handicaps")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.applyConfiguration(draft)
                        dismiss()
                    }
                    .disabled(!isConfigurationValid)
                }
            }
        }
    }

    private var generalSection: some View {
        Section("Round") {
            Picker("Board Size", selection: $draft.boardSize) {
                ForEach([4, 5], id: \.self) { size in
                    Text("\(size) x \(size)").tag(size)
                }
            }

            Stepper(value: $draft.roundDuration, in: 60...600, step: 30) {
                Text("Duration: \(formatTime(draft.roundDuration))")
            }
        }
    }

    private var wordRulesSection: some View {
        Section("Word Rules") {
            Stepper(value: $draft.baseMinWordLength, in: 2...10) {
                Text("Minimum length: \(draft.baseMinWordLength)")
            }
            Toggle("Require unique words", isOn: $draft.requireUniqueWords)
        }
    }

    private var handicapsSection: some View {
        Section("Handicaps") {
            if draft.handicaps.isEmpty {
                Text("Create personalized rules for different players.")
                    .foregroundColor(.secondary)
            }

            ForEach($draft.handicaps) { $handicap in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Player name", text: $handicap.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedHandicap, equals: handicap.id)

                    Stepper(value: $handicap.minWordLength, in: 2...10) {
                        Text("Minimum length: \(handicap.minWordLength)")
                    }

                    Toggle("Custom round duration", isOn: Binding(
                        get: { handicap.roundDuration != nil },
                        set: { enabled in
                            handicap.roundDuration = enabled ? draft.roundDuration : nil
                        }
                    ))

                    if let _ = handicap.roundDuration {
                        Stepper(value: Binding(
                            get: { handicap.roundDuration ?? draft.roundDuration },
                            set: { handicap.roundDuration = $0 }
                        ), in: 30...900, step: 30) {
                            Text("Custom duration: \(formatTime(handicap.roundDuration ?? draft.roundDuration))")
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                draft.handicaps.remove(atOffsets: indexSet)
            }

            Button {
                let newHandicap = PlayerHandicap(name: "New Player", minWordLength: max(2, draft.baseMinWordLength))
                draft.handicaps.append(newHandicap)
                focusedHandicap = newHandicap.id
            } label: {
                Label("Add Handicap", systemImage: "plus.circle.fill")
            }
        }
    }

    private var isConfigurationValid: Bool {
        draft.boardSize >= 3 && draft.roundDuration > 0 && draft.baseMinWordLength >= 2
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
