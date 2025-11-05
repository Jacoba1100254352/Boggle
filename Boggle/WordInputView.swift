// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

// =============================================================
// WordInputView: Presents the composed word, controls for clearing,
// submitting, and shuffling the board.
// =============================================================
struct WordInputView: View {
    @Binding var word: String
    var isRoundActive: Bool
    var onClear: () -> Void
    var onSubmit: () -> Void
    var onShuffle: () -> Void
    var remainingTime: Int
    var totalTime: Int

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - remainingTime) / Double(totalTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Word")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                Text(word.isEmpty ? "Select letters" : word.uppercased())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.mint)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            HStack(spacing: 12) {
                Button {
                    onClear()
                } label: {
                    Label("Clear", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .gray.opacity(0.4)))
                .disabled(word.isEmpty)

                Button {
                    onShuffle()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .blue.opacity(0.5)))
                .disabled(!isRoundActive)

                Button {
                    onSubmit()
                } label: {
                    Label("Submit", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .green.opacity(0.7)))
                .disabled(word.isEmpty || !isRoundActive)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

private struct ActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.6 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
