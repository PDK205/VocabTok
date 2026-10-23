import SwiftUI

/// Dictation: listen and type the word or sentence.
struct TypeExerciseView: View {
    let data: TypeData
    let state: AnswerState
    let onSubmit: (String) -> Void

    @State private var text = ""
    @State private var showHint = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text(data.instruction)
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            VStack(spacing: 14) {
                if let audio = data.audio {
                    HStack(spacing: 20) {
                        SpeakButton(text: audio, size: 76)
                        SpeakButton(text: audio, slow: true, size: 54)
                    }
                }
                if let prompt = data.prompt {
                    Text(prompt)
                        .font(.rounded(20, .bold))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                }
                if let hint = data.hint {
                    if showHint {
                        Text(hint)
                            .font(.rounded(14, .medium))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    } else {
                        Button {
                            withAnimation { showHint = true }
                        } label: {
                            Label("Xem gợi ý nghĩa", systemImage: "lightbulb")
                                .font(.rounded(13, .bold))
                                .foregroundColor(Theme.warning)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .card(padding: 20)

            TextField("Gõ những gì bạn nghe được...", text: $text, axis: .vertical)
                .font(.rounded(19, .semibold))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(1...4)
                .focused($focused)
                .submitLabel(.done)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(borderColor, lineWidth: 2))
                .disabled(state != .answering)
                .onSubmit(submit)

            Spacer(minLength: 0)

            Button("Kiểm tra", action: submit)
                .buttonStyle(BigButtonStyle(enabled: !text.trimmingCharacters(in: .whitespaces).isEmpty))
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || state != .answering)
                .opacity(state == .answering ? 1 : 0)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { focused = true }
        }
    }

    private var borderColor: Color {
        switch state {
        case .answering: return focused ? Theme.accent : Theme.stroke
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, state == .answering else { return }
        focused = false
        onSubmit(trimmed)
    }
}
