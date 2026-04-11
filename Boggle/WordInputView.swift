// =============================================================
// WordInputView.swift
// =============================================================

import SwiftUI

struct WordInputView: View {
    @Binding var word: String
    var canClear: Bool
    var onClear: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(canClear ? Color(red: 0.42, green: 0.21, blue: 0.18) : Color(red: 0.52, green: 0.57, blue: 0.61))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(canClear ? 0.96 : 0.82))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canClear)

            HStack(spacing: 12) {
                Image(systemName: "character.cursor.ibeam")
                    .foregroundStyle(Color(red: 0.15, green: 0.37, blue: 0.44))

                TextField("Type word", text: $word)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(onSubmit)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .layoutPriority(1)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(red: 0.67, green: 0.78, blue: 0.84).opacity(0.55), lineWidth: 1)
                    )
            )

            Button(action: onSubmit) {
                HStack(spacing: 6) {
                    Text("Go")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.subheadline.weight(.bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minWidth: 48)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .disabled(word.isEmpty)
            .opacity(word.isEmpty ? 0.65 : 1)
        }
    }
}
