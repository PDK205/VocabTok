import SwiftUI

struct LessonView: View {
    @StateObject private var vm: LessonViewModel
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @State private var confirmExit = false

    init(kind: SessionKind, store: ProgressStore) {
        _vm = StateObject(wrappedValue: LessonViewModel(kind: kind, store: store))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if vm.finished {
                LessonCompleteView(vm: vm, onDone: close, onRetry: retry)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if vm.isEmpty {
                emptyState
            } else if let ex = vm.current {
                VStack(spacing: 0) {
                    topBar
                    ZStack {
                        exerciseView(ex)
                            .id(ex.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    if vm.state != .answering {
                        FeedbackPanel(exercise: ex, correct: vm.state == .correct, xpGain: vm.lastXPGain, note: vm.feedbackNote) {
                            vm.advance()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear { vm.autoSpeakCurrent() }
        .alert("Thoát bài học?", isPresented: $confirmExit) {
            Button("Học tiếp", role: .cancel) {}
            Button("Thoát", role: .destructive) { close() }
        } message: {
            Text("Tiến độ của bài này sẽ không được lưu.")
        }
    }

    private func close() {
        SpeechManager.shared.stop()
        dismiss()
    }

    private func retry() {
        let kind = vm.kind
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { router.start(kind) }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                if vm.answeredCount == 0 && vm.index == 0 { close() } else { confirmExit = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
            }
            CapsuleProgressBar(progress: vm.progress, color: vm.isTest ? Theme.warning : Theme.success, height: 14)
            if vm.isTest {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Theme.goldGradient)
                    .font(.system(size: 18, weight: .bold))
                    .frame(minWidth: 36)
            } else {
                ComboBadge(combo: vm.combo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func exerciseView(_ ex: Exercise) -> some View {
        switch ex.content {
        case .intro(let word):
            IntroCardView(word: word) { vm.acknowledge() }
        case .choice(let data):
            ChoiceExerciseView(data: data, state: vm.state, selected: vm.selected) { vm.submit($0) }
        case .spell(let word, let tiles):
            SpellExerciseView(word: word, tiles: tiles, state: vm.state) { vm.submit($0) }
        case .type(let data):
            TypeExerciseView(data: data, state: vm.state) { vm.submit($0) }
        case .build(let data):
            BuildSentenceView(data: data, state: vm.state) { vm.submit($0) }
        case .match(let pairs):
            MatchPairsView(pairs: pairs) { vm.completeMatch(mistakenIds: $0) }
        case .speak(let data):
            SpeakExerciseView(data: data, state: vm.state, onResult: { passed, score in
                vm.submitSpeech(passed: passed, score: score)
            }, onSkip: { pauseAll in
                vm.skipSpeaking(pauseAll: pauseAll)
            })
        case .grammarIntro(let grammar):
            GrammarIntroView(grammar: grammar) { vm.acknowledge() }
        case .dialogueIntro(let dialogue):
            DialogueIntroView(dialogue: dialogue) { vm.acknowledge() }
        case .readingIntro(let reading):
            ReadingIntroView(reading: reading) { vm.acknowledge() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            EmptyStateView(emoji: "🌱", title: "Chưa có gì để luyện", message: "Hãy học vài bài trên lộ trình trước, từ vựng sẽ tự động được đưa vào đây để ôn tập.")
            Button("Quay lại", action: close)
                .buttonStyle(BigButtonStyle())
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct ComboBadge: View {
    let combo: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text("\(combo)")
                .contentTransition(.numericText())
        }
        .font(.rounded(15, .heavy))
        .foregroundColor(combo >= 2 ? Theme.flame : Theme.textSecondary.opacity(0.5))
        .scaleEffect(combo >= 2 ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
        .frame(minWidth: 44)
    }
}

struct FeedbackPanel: View {
    let exercise: Exercise
    let correct: Bool
    let xpGain: Int
    let note: String?
    let onContinue: () -> Void

    private static let praises = ["Chính xác!", "Tuyệt vời!", "Giỏi quá!", "Xuất sắc!", "Quá đỉnh!", "Hoàn hảo!", "Chuẩn luôn!"]
    @State private var praise = ""

    var body: some View {
        let color = correct ? Theme.success : Theme.danger
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                Text(correct ? praise : "Chưa đúng rồi")
                    .font(.rounded(21, .heavy))
                Spacer()
                if correct && xpGain > 0 {
                    Text("+\(xpGain) XP")
                        .font(.rounded(15, .heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(color.opacity(0.15)))
                }
            }
            .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                if !correct {
                    Text("Đáp án đúng:")
                        .font(.rounded(13, .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                HStack(alignment: .top, spacing: 8) {
                    Text(exercise.solution)
                        .font(.rounded(17, .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if let audio = exercise.audio {
                        Button { SpeechManager.shared.speak(audio) } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(color)
                                .padding(6)
                        }
                    }
                }
                if let detail = exercise.solutionDetail, !detail.isEmpty {
                    Text(detail)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let note {
                    Text(note)
                        .font(.rounded(13, .semibold))
                        .foregroundColor(correct ? Theme.success : Theme.textSecondary)
                        .padding(.top, 2)
                } else if !correct && !exercise.isSpeaking {
                    Text("Đừng lo, câu này sẽ quay lại để bạn thử lần nữa 💪")
                        .font(.rounded(12, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxHeight: 190)

            Button(correct ? "Tiếp tục" : "Đã hiểu", action: onContinue)
                .buttonStyle(BigButtonStyle(color: color))
        }
        .padding(20)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(color.opacity(0.08)))
                .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
        .onAppear { praise = FeedbackPanel.praises.randomElement() ?? "Chính xác!" }
    }
}
