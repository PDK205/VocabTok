import SwiftUI

struct ChoiceExerciseView: View {
    let exercise: Exercise
    let state: AnswerState
    let selected: String?
    let onSelect: (String) -> Void

    @State private var shake: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            Text(exercise.kind.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            prompt
                .frame(maxWidth: .infinity)
                .frame(minHeight: 170)
                .card(padding: 20)
                .modifier(ShakeEffect(animatableData: shake))

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                ForEach(Array(exercise.options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        number: index + 1,
                        text: option,
                        style: style(for: option)
                    ) {
                        guard state == .answering else { return }
                        Haptics.tap()
                        onSelect(option)
                        if option.lowercased() != exercise.answer.lowercased() {
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
        let word = exercise.word
        switch exercise.kind {
        case .meaning:
            VStack(spacing: 10) {
                Text(word.word)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(word.ipa)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.accent)
                SpeakButton(text: word.word, size: 46)
            }
        case .reverse:
            VStack(spacing: 10) {
                Text("Từ nào có nghĩa là")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                Text("“\(word.vi)”")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(word.posLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.cardRaised))
                    .foregroundColor(Theme.textSecondary)
            }
        case .listen:
            VStack(spacing: 14) {
                HStack(spacing: 20) {
                    SpeakButton(text: word.word, size: 84)
                    SpeakButton(text: word.word, slow: true, size: 58)
                }
                Text("Chạm loa để nghe lại")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
        case .fillBlank:
            VStack(spacing: 12) {
                Text(word.blankedExample ?? word.ex)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(word.exVi)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        default:
            EmptyView()
        }
    }

    private func style(for option: String) -> OptionButton.Style {
        guard state != .answering else { return .idle }
        if option.lowercased() == exercise.answer.lowercased() { return .correct }
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
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(badgeText)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(badgeFill))
                Text(text)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if style == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                } else if style == .wrong {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.danger)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            )
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

    private var badgeText: Color {
        style == .correct || style == .wrong ? .white : Theme.textSecondary
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}
