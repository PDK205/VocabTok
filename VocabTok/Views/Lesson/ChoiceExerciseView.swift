import SwiftUI

struct ChoiceExerciseView: View {
    let data: ChoiceData
    let state: AnswerState
    let selected: String?
    let onSelect: (String) -> Void

    @State private var shake: CGFloat = 0
    @State private var showContext = false

    var body: some View {
        VStack(spacing: 16) {
            Text(data.instruction)
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                prompt
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150)
                    .card(padding: 20)
                    .modifier(ShakeEffect(animatableData: shake))
                    .padding(.vertical, 4)
            }
            .frame(maxHeight: 330)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                ForEach(Array(data.options.enumerated()), id: \.offset) { index, option in
                    OptionButton(number: index + 1, text: option, style: style(for: option)) {
                        guard state == .answering else { return }
                        Haptics.tap()
                        onSelect(option)
                        if option != data.answer {
                            withAnimation(.linear(duration: 0.4)) { shake += 1 }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var prompt: some View {
        switch data.prompt {
        case .word(let word):
            VStack(spacing: 10) {
                Text(word.word)
                    .font(.rounded(38, .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(word.ipa)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.accent)
                SpeakButton(text: word.word, size: 46)
            }
        case .meaning(let meaning, let pos):
            VStack(spacing: 10) {
                Text("Từ nào có nghĩa là")
                    .font(.rounded(14, .semibold))
                    .foregroundColor(Theme.textSecondary)
                Text("“\(meaning)”")
                    .font(.rounded(26, .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                if let pos { Chip(text: pos, color: Theme.textSecondary) }
            }
        case .audio(let text):
            VStack(spacing: 14) {
                HStack(spacing: 20) {
                    SpeakButton(text: text, size: 84)
                    SpeakButton(text: text, slow: true, size: 58)
                }
                Text("Chạm loa để nghe lại")
                    .font(.rounded(14, .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
        case .sentence(let sentence, let hint):
            VStack(spacing: 12) {
                Text(sentence)
                    .font(.rounded(22, .bold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if let hint {
                    Text(hint)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                if !sentence.contains("___") {
                    SpeakButton(text: sentence, size: 42)
                }
            }
        case .question(let question, let context):
            VStack(alignment: .leading, spacing: 12) {
                if let context {
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { showContext.toggle() }
                        } label: {
                            Label(showContext ? "Ẩn đoạn văn" : "Xem lại đoạn văn", systemImage: showContext ? "chevron.up" : "doc.text")
                                .font(.rounded(13, .bold))
                                .foregroundColor(Theme.accent)
                        }
                        if showContext {
                            Text(context)
                                .font(.rounded(14, .medium))
                                .foregroundColor(Theme.textSecondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardRaised))
                        }
                    }
                }
                Text(question)
                    .font(.rounded(21, .bold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func style(for option: String) -> OptionButton.Style {
        guard state != .answering else { return .idle }
        if option == data.answer { return .correct }
        if option == selected { return .wrong }
        return .dimmed
    }
}

struct OptionButton: View {
    enum Style { case idle, correct, wrong, dimmed }

    let number: Int
    let text: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.rounded(14, .heavy))
                    .foregroundColor(style == .correct || style == .wrong ? .white : Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(badgeFill))
                Text(text)
                    .font(.rounded(16, .semibold))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if style == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                } else if style == .wrong {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.danger)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(border, lineWidth: 2))
            .opacity(style == .dimmed ? 0.5 : 1)
            .scaleEffect(style == .correct ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: style)
        }
        .buttonStyle(PressableStyle())
    }

    private var fill: Color {
        switch style {
        case .correct: return Theme.success.opacity(0.14)
        case .wrong: return Theme.danger.opacity(0.12)
        default: return Theme.card
        }
    }

    private var border: Color {
        switch style {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        default: return Theme.stroke
        }
    }

    private var textColor: Color {
        switch style {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        default: return Theme.textPrimary
        }
    }

    private var badgeFill: Color {
        switch style {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        default: return Theme.cardRaised
        }
    }
}
