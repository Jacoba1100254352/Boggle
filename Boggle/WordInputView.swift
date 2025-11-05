// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

// =============================================================
// WordInputView: Styled entry row for submitting candidate words.
// =============================================================
struct WordInputView: View {
    @Binding var word: String
    var minimumLength: Int
    var isEnabled: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter a word")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                TextField("Type here", text: $word)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .disabled(!isEnabled)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)

                Button(action: onSubmit) {
                    Label("Submit", systemImage: "paperplane.fill")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSubmitDisabled ? Color.gray.opacity(0.4) : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(isSubmitDisabled)
            }

            Text("Minimum length: \(minimumLength) letters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .opacity(isEnabled ? 1 : 0.6)
    }

    private var isSubmitDisabled: Bool {
        !isEnabled || word.trimmingCharacters(in: .whitespacesAndNewlines).count < minimumLength
    }
}
