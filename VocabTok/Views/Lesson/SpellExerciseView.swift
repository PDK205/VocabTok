import SwiftUI

/// Build the word by tapping shuffled letter tiles.
struct SpellExerciseView: View {
    let exercise: Exercise
    let state: AnswerState
    let onSubmit: (String) -> Void

    /// Indices into `exercise.tiles`, in the order the user tapped them.
    @State private var placed: [Int] = []
    @State private var shake: CGFloat = 0

    private var typed: String { String(placed.map { exercise.tiles[$0] }) }
    private let columns = [GridItem(.adaptive(minimum: 48, maximum: 56), spacing: 10)]

    var body: some View {
        VStack(spacing: 18) {
            Text(exercise.kind.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Text("“\(exercise.word.vi)”")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    SpeakButton(text: exercise.word.word, size: 42)
                    Text("Gợi ý: nghe phát âm")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .card(padding: 20)

            answerSlots
                .modifier(ShakeEffect(animatableData: shake))

            Spacer(minLength: 0)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(exercise.tiles.indices, id: \.self) { i in
                    let used = placed.contains(i)
                    Button {
                        guard state == .answering, !used else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.append(i) }
                        if placed.count == exercise.tiles.count { submit() }
                    } label: {
                        LetterTile(letter: exercise.tiles[i], faded: used)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(used || state != .answering)
                }
            }

            HStack(spacing: 12) {
                Button {
                    guard state == .answering, !placed.isEmpty else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { _ = placed.removeLast() }
                } label: {
                    Label("Xoá", systemImage: "delete.left.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.cardRaised, textColor: Theme.textPrimary))

                Button {
                    guard state == .answering else { return }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.removeAll() }
                } label: {
                    Label("Làm lại", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(BigButtonStyle(color: Theme.cardRaised, textColor: Theme.textPrimary))
            }
            .opacity(state == .answering ? 1 : 0)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
    }

    private var answerSlots: some View {
        let slotColor: Color = state == .correct ? Theme.success : state == .wrong ? Theme.danger : Theme.accent
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 30, maximum: 38), spacing: 6)], spacing: 8) {
            ForEach(exercise.tiles.indices, id: \.self) { slot in
                let filled = slot < placed.count
                Text(filled ? String(exercise.tiles[placed[slot]]) : " ")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(slotColor)
                    .frame(width: 32, height: 42)
                    .overlay(
                        Rectangle()
                            .fill(filled ? slotColor : Theme.stroke)
                            .frame(height: 3),
                        alignment: .bottom
                    )
                    .onTapGesture {
                        // Tap a filled slot to send that letter (and the ones after it) back.
                        guard state == .answering, filled else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.removeSubrange(slot...) }
                    }
            }
        }
        .padding(.horizontal, 4)
    }

    private func submit() {
        let answer = typed
        let correct = answer == exercise.answer
        if !correct {
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onSubmit(answer) }
    }
}

private struct LetterTile: View {
    let letter: Character
    let faded: Bool

    var body: some View {
        Text(String(letter))
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundColor(faded ? .clear : Theme.textPrimary)
            .frame(width: 50, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(faded ? Theme.cardRaised : Theme.card)
                    .shadow(color: .black.opacity(faded ? 0 : 0.08), radius: 0, x: 0, y: faded ? 0 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(faded ? Color.clear : Theme.stroke, lineWidth: 2)
            )
    }
}
