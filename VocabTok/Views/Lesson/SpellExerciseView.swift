import SwiftUI

/// Build the word by tapping shuffled letter tiles.
struct SpellExerciseView: View {
    let word: Word
    let tiles: [Character]
    let state: AnswerState
    let onSubmit: (String) -> Void

    /// Indices into `tiles`, in the order the learner tapped them.
    @State private var placed: [Int] = []
    @State private var shake: CGFloat = 0
    @State private var submitted = false

    private var typed: String { String(placed.map { tiles[$0] }) }

    var body: some View {
        VStack(spacing: 18) {
            Text("Ghép chữ thành từ")
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Text("“\(word.vi)”")
                    .font(.rounded(24, .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    SpeakButton(text: word.word, size: 42)
                    Text("Gợi ý: nghe phát âm")
                        .font(.rounded(13, .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .card(padding: 20)

            answerSlots
                .modifier(ShakeEffect(animatableData: shake))

            Spacer(minLength: 0)

            FlowLayout(spacing: 10, lineSpacing: 10, alignment: .center) {
                ForEach(tiles.indices, id: \.self) { i in
                    let used = placed.contains(i)
                    Button {
                        tapTile(i)
                    } label: {
                        LetterTile(letter: tiles[i], faded: used)
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
                .buttonStyle(SecondaryButtonStyle(color: Theme.textSecondary))

                Button {
                    guard state == .answering else { return }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.removeAll() }
                } label: {
                    Label("Làm lại", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.textSecondary))
            }
            .opacity(state == .answering ? 1 : 0)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
    }

    private func tapTile(_ i: Int) {
        guard state == .answering, !placed.contains(i), !submitted else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.append(i) }
        if placed.count == tiles.count {
            submitted = true
            let answer = typed
            if TextMatch.normalize(answer) != TextMatch.normalize(word.word) {
                withAnimation(.linear(duration: 0.4)) { shake += 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onSubmit(answer) }
        }
    }

    private var answerSlots: some View {
        let slotColor: Color = state == .correct ? Theme.success : (state == .wrong ? Theme.danger : Theme.accent)
        return FlowLayout(spacing: 6, lineSpacing: 8, alignment: .center) {
            ForEach(tiles.indices, id: \.self) { slot in
                let filled = slot < placed.count
                Text(filled ? String(tiles[placed[slot]]) : " ")
                    .font(.rounded(24, .heavy))
                    .foregroundColor(slotColor)
                    .frame(width: 30, height: 42)
                    .overlay(
                        Rectangle()
                            .fill(filled ? slotColor : Theme.stroke)
                            .frame(height: 3),
                        alignment: .bottom
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard state == .answering, filled, !submitted else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { placed.removeSubrange(slot...) }
                    }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct LetterTile: View {
    let letter: Character
    let faded: Bool

    var body: some View {
        Text(String(letter))
            .font(.rounded(24, .heavy))
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
