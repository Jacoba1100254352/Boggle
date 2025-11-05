// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

// =============================================================
// WordInputView: Lets the user type in a word and submit it.
// Used as a reusable component in the main game view.
// =============================================================
struct WordInputView: View {
    // @Binding allows this view to read & write the 'word' variable owned by its parent.
    // This means when the user types here, the change is reflected in the parent view too!
    @Binding var word: String
    // 'onSubmit' is a closure (a function you pass in) called when the user taps the Submit button.
    var onSubmit: () -> Void

    var body: some View {
        // Arrange input field and button side-by-side
        HStack {
            // TextField lets the user type their word
            // The text is linked ('bound') to 'word', so it updates live as the user types.
            TextField("Enter word", text: $word)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .font(.headline)
            // Submit button for entering the word
            Button("Submit", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(word.isEmpty)          // Button is disabled if text is empty
        }
        .padding(.vertical)  // Adds space above and below the whole row
    }
}
