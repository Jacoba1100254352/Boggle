// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

struct WordInputView: View {
    @Binding var word: String
    var canClear: Bool
    var onClear: () -> Void
    var onWordEdited: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(canClear ? Color(red: 0.40, green: 0.23, blue: 0.19) : Color(red: 0.56, green: 0.62, blue: 0.66))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(canClear ? Color(red: 0.95, green: 0.91, blue: 0.88) : Color(red: 0.94, green: 0.97, blue: 0.98))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canClear)
            .accessibilityLabel("Clear word")
            .accessibilityHint("Removes the current word and tile selection.")
            .accessibilityIdentifier("clearWordButton")

            HStack(spacing: 12) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.40, blue: 0.47))

                TextField("Type a board word", text: editableWord)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.22, blue: 0.30))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(onSubmit)
                    .accessibilityLabel("Word")
                    .accessibilityHint("Enter a word that can be formed from connected board tiles.")
                    .accessibilityIdentifier("wordInput")
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
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
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .disabled(word.isEmpty)
            .opacity(word.isEmpty ? 0.5 : 1)
            .accessibilityLabel("Submit word")
            .accessibilityIdentifier("submitWordButton")
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(red: 0.67, green: 0.78, blue: 0.84).opacity(0.60), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var editableWord: Binding<String> {
        Binding(
            get: { word },
            set: { newValue in
                word = String(newValue.filter(\.isLetter))
                onWordEdited()
            }
        )
    }
}
