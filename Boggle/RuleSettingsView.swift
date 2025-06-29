// =============================================================
// RuleSettingsView.swift
// =============================================================

import SwiftUI

/// A SwiftUI view that allows the user to configure game rule options.
/// This view presents toggles for different rule settings and keeps them
/// in sync with the game's view model.
struct RuleSettingsView: View {
    
    /// The observed view model that holds the current game state and options.
    /// Changes to this object will update the view automatically.
    @ObservedObject var vm: GameViewModel
    
    /// Local state representing the currently selected rule options in this view.
    /// This is initialized from the view model's current options and updated
    /// when toggles change, keeping the UI responsive.
    @State private var opts: RuleOptions
    
    /// Environment variable to allow dismissing the view.
    /// This is commonly used in modal presentations to programmatically close the view.
    @Environment(\.dismiss) private var dismiss
    
    /// Custom initializer that takes the view model and initializes
    /// the local state `opts` from the view model's current options.
    /// This ensures the toggles reflect the current game settings when shown.
    /// - Parameter vm: The game view model containing rule options.
    init(vm: GameViewModel) {
        self.vm = vm
        _opts = State(initialValue: vm.currentOptions)
    }
    
    /// The main body of the view, defining its UI hierarchy.
    /// Uses a navigation view containing a form with toggles for each rule option.
    /// Also includes a toolbar with a Close button to dismiss the sheet.
    var body: some View {
        NavigationView {
            Form {
                // Toggle for enabling/disabling the minimum length rule.
                // The binding connects the toggle's state to the local opts set,
                // which in turn updates the view model.
                Toggle("Minimum length ≥ 3", isOn: binding(for: .minLength))
                
                // Toggle for enforcing unique words only.
                // Uses the same pattern to keep local state and view model in sync.
                Toggle("Unique words only",   isOn: binding(for: .uniqueWords))
            }
            .navigationTitle("Rules") // Title of the navigation bar
            
            // Toolbar with a cancellation action placement.
            // Provides a Close button that calls dismiss to close this view.
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Helper method that creates a two-way binding between a rule option flag
    /// in the local `opts` state and the corresponding toggle.
    ///
    /// When the toggle changes, this updates the local state and notifies the view model.
    /// When the local state changes, the toggle updates accordingly.
    ///
    /// - Parameter flag: The specific RuleOptions flag to bind.
    /// - Returns: A Binding<Bool> that can be used with SwiftUI controls.
    private func binding(for flag: RuleOptions) -> Binding<Bool> {
        Binding {
            // Return true if the current options contain the given flag.
            opts.contains(flag)
        } set: { newVal in
            // On toggle change, insert or remove the flag in local state.
            if newVal {
                opts.insert(flag)
            } else {
                opts.remove(flag)
            }
            // Notify the view model to toggle the option accordingly,
            // maintaining global state consistency.
            vm.toggle(flag)
        }
    }
}
