import SwiftUI

/// Adaptive placement test: five questions per level, stops at the first level the learner does not pass.
struct PlacementTestView: View {
    let onFinish: (Int) -> Void

    @State private var levelIndex = 0
    @State private var questionIndex = 0
    @State private var correctInLevel = 0
    @State private var selected: String?
    @State private var resultLevel: Int?

    private let content = ContentStore.shared
    private let passMark = 4

    private var levels: [String] { content.levels.map(\.id) }

    private var questions: [PlacementItem] {
        guard levels.indices.contains(levelIndex) else { return [] }
        return content.placement.filter { $0.level == levels[levelIndex] }
    }

    private var answeredTotal: Int { levelIndex * 5 + questionIndex }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let result = resultLevel {
                resultView(result)
            } else if questions.indices.contains(questionIndex) {
                questionView(questions[questionIndex])
            }
        }
    }

    private func questionView(_ item: PlacementItem) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Text("Kiểm tra xếp lớp")
                    .font(.rounded(15, .heavy))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Chip(text: "Cấp độ \(levels[levelIndex])", color: Theme.levelColor(content.levels[levelIndex]))
            }
            .padding(.top, 12)
            CapsuleProgressBar(progress: Double(answeredTotal) / Double(max(content.placement.count, 1)), color: Theme.accent, height: 10)

            Spacer()
            Text(item.q)
                .font(.rounded(24, .bold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .card(padding: 24)
            Spacer()

            VStack(spacing: 10) {
                ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                    OptionButton(number: index + 1, text: option, style: selected == option ? .correct : .idle) {
                        Haptics.tap()
                        selected = option
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Tôi không biết") { answer(item, choice: nil) }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.textSecondary))
                Button("Tiếp") { answer(item, choice: selected) }
                    .buttonStyle(BigButtonStyle(enabled: selected != nil))
                    .disabled(selected == nil)
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
    }

    private func answer(_ item: PlacementItem, choice: String?) {
        if choice == item.answer { correctInLevel += 1 }
        selected = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            if questionIndex + 1 < questions.count {
                questionIndex += 1
            } else {
                // Level finished: continue only if the learner passed it.
                if correctInLevel >= passMark && levelIndex + 1 < levels.count {
                    levelIndex += 1
                    questionIndex = 0
                    correctInLevel = 0
                } else {
                    // Start at the first level that was not passed (or the last level if all passed).
                    resultLevel = levelIndex
                    Haptics.celebrate()
                }
            }
        }
    }

    private func resultView(_ result: Int) -> some View {
        let level = content.levels[result]
        return VStack(spacing: 20) {
            Spacer()
            Text(level.emoji).font(.system(size: 80))
            Text("Trình độ của bạn")
                .font(.rounded(17, .semibold))
                .foregroundColor(Theme.textSecondary)
            Text("\(level.id) · \(level.name)")
                .font(.rounded(34, .heavy))
                .foregroundColor(Color(hex: level.color))
            Text(result == 0
                 ? "Bạn sẽ bắt đầu từ nền tảng A1 để xây chắc gốc."
                 : "Các cấp độ trước đã được mở khóa, bạn vẫn có thể quay lại ôn bất cứ lúc nào.")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Tiếp tục") { onFinish(result) }
                .buttonStyle(BigButtonStyle(color: Theme.success))
        }
        .padding(24)
    }
}
