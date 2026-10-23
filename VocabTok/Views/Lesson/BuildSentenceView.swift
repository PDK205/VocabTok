import SwiftUI

/// Arrange word tiles into the correct sentence.
struct BuildSentenceView: View {
    let data: BuildData
    let state: AnswerState
    let onSubmit: (String) -> Void

    @State private var placed: [Int] = []
    @State private var shake: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            Text(data.instruction)
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            HStack(alignment: .top, spacing: 12) {
                if let audio = data.audio {
                    SpeakButton(text: audio, size: 44)
                } else {
                    IconBadge(icon: "text.bubble.fill", color: Theme.accent, size: 44)
                }
                Text(data.prompt)
                    .font(.rounded(18, .bold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .card(padding: 16)

            // Answer area
            ZStack(alignment: .topLeading) {
                VStack(spacing: 48) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(Theme.stroke).frame(height: 1.5)
                    }
                }
                .padding(.top, 46)

                FlowLayout(spacing: 8, lineSpacing: 10) {
                    ForEach(Array(placed.enumerated()), id: \.offset) { position, tileIndex in
                        Button {
                            guard state == .answering else { return }
                            Haptics.tap()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { _ = placed.remove(at: position) }
                        } label: {
                            WordTile(text: data.tiles[tileIndex], tint: tint)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.top, 4)
            }
            .frame(minHeight: 150, alignment: .top)
            .modifier(ShakeEffect(animatableData: shake))

            Spacer(minLength: 0)

            FlowLayout(spacing: 8, lineSpacing: 10, alignment: .center) {
                ForEach(data.tiles.indices, id: \.self) { i in
                    let used = placed.contains(i)
                    Button {
                        guard state == .answering, !used else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { placed.append(i) }
                    } label: {
                        WordTile(text: data.tiles[i], tint: Theme.textPrimary, faded: used)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(used || state != .answering)
                }
            }

            Button("Kiểm tra", action: submit)
                .buttonStyle(BigButtonStyle(enabled: !placed.isEmpty))
                .disabled(placed.isEmpty || state != .answering)
                .opacity(state == .answering ? 1 : 0)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
    }

    private var tint: Color {
        switch state {
        case .answering: return Theme.textPrimary
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        }
    }

    private func submit() {
        guard state == .answering, !placed.isEmpty else { return }
        let sentence = placed.map { data.tiles[$0] }.joined(separator: " ")
        if TextMatch.normalize(sentence) != TextMatch.normalize(data.answerTokens.joined(separator: " ")) {
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
        onSubmit(sentence)
    }
}

struct WordTile: View {
    let text: String
    var tint: Color = Theme.textPrimary
    var faded = false

    var body: some View {
        Text(text)
            .font(.rounded(17, .semibold))
            .foregroundColor(faded ? .clear : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(faded ? Theme.cardRaised : Theme.card)
                    .shadow(color: .black.opacity(faded ? 0 : 0.07), radius: 0, x: 0, y: faded ? 0 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(faded ? Color.clear : Theme.stroke, lineWidth: 1.5)
            )
    }
}
