import SwiftUI

/// Tap an English word and its Vietnamese meaning to match them.
struct MatchPairsView: View {
    let pairs: [MatchPair]
    let onComplete: (Set<String>) -> Void

    @State private var leftOrder: [MatchPair] = []
    @State private var rightOrder: [MatchPair] = []
    @State private var selectedLeft: String?
    @State private var selectedRight: String?
    @State private var matched: Set<String> = []
    @State private var wrongFlash: Set<String> = []
    @State private var mistakes: Set<String> = []
    @State private var done = false

    var body: some View {
        VStack(spacing: 18) {
            Text("Ghép cặp từ và nghĩa")
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            Text("Chạm một từ tiếng Anh rồi chạm nghĩa tương ứng")
                .font(.rounded(14, .medium))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(leftOrder) { pair in
                        MatchTile(text: pair.left, state: tileState(id: pair.id, isLeft: true), english: true) {
                            tapLeft(pair)
                        }
                    }
                }
                VStack(spacing: 10) {
                    ForEach(rightOrder) { pair in
                        MatchTile(text: pair.right, state: tileState(id: pair.id, isLeft: false), english: false) {
                            tapRight(pair)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .onAppear {
            if leftOrder.isEmpty {
                leftOrder = pairs.shuffled()
                rightOrder = pairs.shuffled()
            }
        }
    }

    private func tileState(id: String, isLeft: Bool) -> MatchTile.TileState {
        if matched.contains(id) { return .matched }
        let key = (isLeft ? "L-" : "R-") + id
        if wrongFlash.contains(key) { return .wrong }
        if isLeft ? selectedLeft == id : selectedRight == id { return .selected }
        return .idle
    }

    private func tapLeft(_ pair: MatchPair) {
        guard !matched.contains(pair.id), !done else { return }
        Haptics.tap()
        SpeechManager.shared.speak(pair.left)
        selectedLeft = pair.id
        evaluate()
    }

    private func tapRight(_ pair: MatchPair) {
        guard !matched.contains(pair.id), !done else { return }
        Haptics.tap()
        selectedRight = pair.id
        evaluate()
    }

    private func evaluate() {
        guard let left = selectedLeft, let right = selectedRight else { return }
        if left == right {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                _ = matched.insert(left)
            }
            SoundFX.tap.play()
            Haptics.soft()
            selectedLeft = nil
            selectedRight = nil
            if matched.count == pairs.count {
                done = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onComplete(mistakes) }
            }
        } else {
            mistakes.insert(left)
            let keys: Set<String> = ["L-" + left, "R-" + right]
            withAnimation(.easeInOut(duration: 0.15)) { wrongFlash.formUnion(keys) }
            Haptics.error()
            selectedLeft = nil
            selectedRight = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.2)) { wrongFlash.subtract(keys) }
            }
        }
    }
}

struct MatchTile: View {
    enum TileState { case idle, selected, matched, wrong }

    let text: String
    let state: TileState
    let english: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.rounded(english ? 17 : 15, english ? .bold : .semibold))
                .foregroundColor(foreground)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(background))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(border, lineWidth: 2))
                .scaleEffect(state == .selected ? 1.03 : 1)
                .opacity(state == .matched ? 0.45 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: state)
        }
        .buttonStyle(PressableStyle())
        .disabled(state == .matched)
    }

    private var foreground: Color {
        switch state {
        case .matched: return Theme.success
        case .wrong: return Theme.danger
        case .selected: return Theme.accent
        case .idle: return Theme.textPrimary
        }
    }

    private var background: Color {
        switch state {
        case .matched: return Theme.success.opacity(0.12)
        case .wrong: return Theme.danger.opacity(0.12)
        case .selected: return Theme.accent.opacity(0.12)
        case .idle: return Theme.card
        }
    }

    private var border: Color {
        switch state {
        case .matched: return Theme.success.opacity(0.5)
        case .wrong: return Theme.danger
        case .selected: return Theme.accent
        case .idle: return Theme.stroke
        }
    }
}
