// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

// =============================================================
// WordInputView: Lets the user type in a word and submit it.
// Used as a reusable component in the main game view.
// =============================================================
struct WordInputView: View {
    /// Live binding to the current word entry.
    @Binding var word: String
    /// Placeholder shown inside the text field.
    var placeholder: String = "Type or tap a word"
    /// Invoked when the user submits the word.
    var onSubmit: () -> Void
    /// Optional closure to clear the current word/selection.
    var onClear: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $word)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.characters)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            if let onClear {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear current word")
            }

            Button(action: onSubmit) {
                Label("Submit", systemImage: "paperplane.fill")
                    .labelStyle(.titleAndIcon)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(word.isEmpty ? Color.gray.opacity(0.4) : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 6)
    }
}
