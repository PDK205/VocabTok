import SwiftUI

struct LessonCompleteView: View {
    @ObservedObject var vm: LessonViewModel
    let onDone: () -> Void
    let onRetry: () -> Void
    @State private var appeared = false
    @State private var shownXP = 0

    private var outcome: SessionOutcome { vm.outcome ?? SessionOutcome() }
    private var failedTest: Bool { vm.isTest && !outcome.passed }

    private var title: String {
        if failedTest { return "Chưa đạt rồi 😅" }
        if vm.isTest { return "Hoàn thành unit! 🏆" }
        switch outcome.accuracy {
        case 1: return "Hoàn hảo! 🌟"
        case 0.8...: return "Làm tốt lắm! 🎉"
        case 0.5...: return "Cố gắng tốt! 💪"
        default: return "Đã xong bài! 🌱"
        }
    }

    private var subtitle: String {
        if failedTest {
            return "Bạn đạt \(Int(outcome.accuracy * 100))%, cần từ 80% để qua unit. Ôn lại các bài trong unit rồi thử lại nhé!"
        }
        if vm.isTest { return "Bạn đã mở khóa unit tiếp theo trên lộ trình." }
        return vm.subtitle
    }

    private var durationText: String {
        let seconds = Int(vm.duration)
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)p \(seconds % 60)s"
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    hero.padding(.top, 36)

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.rounded(30, .heavy))
                            .foregroundColor(Theme.textPrimary)
                        Text(subtitle)
                            .font(.rounded(15, .medium))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    HStack(spacing: 10) {
                        ResultTile(title: "XP", value: "+\(shownXP)", icon: "bolt.fill", color: Theme.warning)
                        ResultTile(title: "Chính xác", value: "\(Int(outcome.accuracy * 100))%", icon: "target", color: Theme.success)
                        ResultTile(title: "Combo", value: "\(vm.maxCombo)", icon: "flame.fill", color: Theme.flame)
                        ResultTile(title: "Thời gian", value: durationText, icon: "clock.fill", color: Theme.sky)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                    if outcome.streakExtended {
                        banner(icon: "flame.fill", color: Theme.flame, title: "Chuỗi \(outcome.streak) ngày!", detail: "Tuyệt vời, bạn đã giữ lửa hôm nay.")
                    }
                    if outcome.leveledUp {
                        banner(icon: "arrow.up.circle.fill", color: Theme.accent, title: "Lên cấp \(outcome.newLevel)!", detail: "Kinh nghiệm của bạn đang tăng nhanh.")
                    }
                    ForEach(outcome.newAchievements) { achievement in
                        banner(icon: achievement.icon, color: Color(hex: achievement.color), title: "Thành tích mới: \(achievement.title)", detail: achievement.detail)
                    }

                    if !vm.mistakeWords.isEmpty {
                        wordList(title: "Cần ôn thêm", subtitle: "Sẽ được nhắc lại sớm", words: vm.mistakeWords, color: Theme.warning)
                    }
                    let good = vm.trackedWordList.filter { !vm.mistakes.contains($0.id) }
                    if !good.isEmpty && !failedTest {
                        wordList(title: "Đã nhớ tốt", subtitle: "Lần ôn tiếp theo sẽ giãn ra", words: good, color: Theme.success)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 130)
            }

            VStack(spacing: 10) {
                Spacer()
                if failedTest {
                    Button("Làm lại bài kiểm tra", action: onRetry)
                        .buttonStyle(BigButtonStyle(color: Theme.warning))
                    Button("Về lộ trình", action: onDone)
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Tiếp tục", action: onDone)
                        .buttonStyle(BigButtonStyle(color: Theme.success))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
            .background(
                LinearGradient(colors: [Theme.background.opacity(0), Theme.background], startPoint: .top, endPoint: .center)
                    .frame(height: 170)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )

            if !failedTest { ConfettiView() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) { appeared = true }
            countUpXP()
            if outcome.unitCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { SoundFX.unlock.play() }
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if vm.lesson != nil && !failedTest {
            HStack(spacing: 14) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: i == 2 ? 64 : 48, weight: .bold))
                        .foregroundStyle(i <= outcome.stars ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.cardRaised))
                        .offset(y: i == 2 ? -12 : 0)
                        .scaleEffect(appeared ? 1 : 0.2)
                        .rotationEffect(.degrees(appeared ? 0 : -40))
                        .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15 * Double(i)), value: appeared)
                }
            }
        } else {
            ZStack {
                Circle()
                    .fill((failedTest ? Theme.textSecondary : Theme.warning).opacity(0.15))
                    .frame(width: 150, height: 150)
                    .scaleEffect(appeared ? 1 : 0.4)
                Image(systemName: failedTest ? "arrow.counterclockwise.circle.fill" : "trophy.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(failedTest ? AnyShapeStyle(Theme.textSecondary) : AnyShapeStyle(Theme.goldGradient))
                    .rotationEffect(.degrees(appeared ? 0 : -30))
                    .scaleEffect(appeared ? 1 : 0.2)
            }
        }
    }

    private func countUpXP() {
        let target = outcome.xp
        guard target > 0 else { return }
        let steps = 20
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(step) * 0.035) {
                shownXP = target * step / steps
            }
        }
    }

    private func banner(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, color: color, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(16, .heavy)).foregroundColor(Theme.textPrimary)
                Text(detail).font(.rounded(13, .medium)).foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
    }

    private func wordList(title: String, subtitle: String, words: [Word], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(title)
                    .font(.rounded(16, .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(subtitle)
                    .font(.rounded(12, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            ForEach(words) { word in
                HStack {
                    Text(word.word)
                        .font(.rounded(16, .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(word.vi)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .card()
    }
}

private struct ResultTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.rounded(18, .heavy))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.rounded(11, .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(color.opacity(0.12)))
    }
}
