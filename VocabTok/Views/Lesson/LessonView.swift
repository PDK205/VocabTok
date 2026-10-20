import SwiftUI

struct LessonView: View {
    @StateObject private var vm: LessonViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmExit = false

    init(mode: LessonMode, store: ProgressStore) {
        _vm = StateObject(wrappedValue: LessonViewModel(mode: mode, store: store))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if vm.finished {
                LessonCompleteView(vm: vm) { dismiss() }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                        FeedbackPanel(exercise: ex, correct: vm.state == .correct, xpGain: vm.lastXPGain) {
                            vm.advance()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            } else {
                emptyState
            }
        }
        .alert("Thoát bài học?", isPresented: $confirmExit) {
            Button("Học tiếp", role: .cancel) {}
            Button("Thoát", role: .destructive) {
                SpeechManager.shared.stop()
                dismiss()
            }
        } message: {
            Text("Tiến độ của bài này sẽ không được lưu.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                confirmExit = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
            }
            CapsuleProgressBar(progress: vm.progress, color: Theme.success, height: 14)
            ComboBadge(combo: vm.combo)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func exerciseView(_ ex: Exercise) -> some View {
        switch ex.kind {
        case .intro:
            IntroCardView(word: ex.word) { vm.acknowledgeIntro() }
        case .spell:
            SpellExerciseView(exercise: ex, state: vm.state) { vm.submit($0) }
        default:
            ChoiceExerciseView(exercise: ex, state: vm.state, selected: vm.selected) { vm.submit($0) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎉").font(.system(size: 64))
            Text("Bạn đã học hết từ vựng!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Button("Quay lại") { dismiss() }
                .buttonStyle(BigButtonStyle())
                .padding(.horizontal, 40)
        }
    }
}

private struct ComboBadge: View {
    let combo: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text("\(combo)")
                .contentTransition(.numericText())
        }
        .font(.system(size: 15, weight: .heavy, design: .rounded))
        .foregroundColor(combo >= 2 ? Theme.flame : Theme.textSecondary.opacity(0.5))
        .scaleEffect(combo >= 2 ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
        .frame(minWidth: 44)
    }
}

private struct FeedbackPanel: View {
    let exercise: Exercise
    let correct: Bool
    let xpGain: Int
    let onContinue: () -> Void

    private let praises = ["Chính xác!", "Tuyệt vời!", "Giỏi quá!", "Xuất sắc!", "Quá đỉnh!"]
    @State private var praise = ""

    var body: some View {
        let color = correct ? Theme.success : Theme.danger
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                Text(correct ? praise : "Chưa đúng rồi")
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                Spacer()
                if correct {
                    Text("+\(xpGain) XP")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(color.opacity(0.15)))
                }
            }
            .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                if !correct {
                    Text("Đáp án đúng:")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
                HStack(spacing: 8) {
                    Text(exercise.word.word)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text(exercise.word.ipa)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.accent)
                    Spacer()
                    Button { SpeechManager.shared.speak(exercise.word.word) } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundColor(color)
                    }
                }
                Text(exercise.word.vi)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                if !correct {
                    Text("Đừng lo, từ này sẽ quay lại để bạn thử lần nữa 💪")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 2)
                }
            }

            Button("Tiếp tục", action: onContinue)
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
        .onAppear { praise = praises.randomElement() ?? "Chính xác!" }
    }
}
