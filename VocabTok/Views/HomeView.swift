import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("dailyGoal") private var dailyGoal = 50
    @AppStorage("newPerLesson") private var newPerLesson = 5
    @State private var revealWordOfDay = false
    let startLesson: (LessonMode) -> Void

    private var dueCount: Int { store.dueWords.count }
    private var newCount: Int { min(newPerLesson, store.newWords().count) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    dailyGoalCard
                    lessonCard
                    if dueCount > 0 { reviewCard }
                    if let word = WordBank.shared.wordOfTheDay { wordOfDayCard(word) }
                    focusTip
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Chào buổi sáng ☀️"
        case 12..<18: return "Chào buổi chiều 🌤"
        default: return "Chào buổi tối 🌙"
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                Text("Học gì hôm nay?")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(store.isStreakActiveToday ? Theme.flameGradient : LinearGradient(colors: [Theme.textSecondary], startPoint: .top, endPoint: .bottom))
                Text("\(store.data.streak)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(store.isStreakActiveToday ? Theme.flame : Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.card))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .padding(.top, 12)
    }

    private var dailyGoalCard: some View {
        let progress = Double(store.todayXP) / Double(max(dailyGoal, 1))
        return HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 11, gradient: progress >= 1 ? [Theme.success, Color(hex: "86EFAC")] : [Theme.accent, Theme.accentLight])
                    .frame(width: 76, height: 76)
                if progress >= 1 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(Theme.success)
                } else {
                    Text("\(Int(min(progress, 1) * 100))%")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Mục tiêu hôm nay")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("\(store.todayXP) / \(dailyGoal) XP")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text(progress >= 1 ? "Tuyệt vời! Bạn đã hoàn thành mục tiêu 🎉" : "Còn \(max(dailyGoal - store.todayXP, 0)) XP nữa thôi, cố lên!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var lessonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("BÀI HỌC HÔM NAY")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Cấp \(store.level)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                    .foregroundColor(.white)
            }
            Text(newCount > 0 ? "Học \(newCount) từ mới" : (dueCount > 0 ? "Ôn lại từ đã học" : "Luyện tập tự do"))
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 14) {
                Label("\(newCount) mới", systemImage: "sparkles")
                Label("\(min(dueCount, 10)) ôn tập", systemImage: "arrow.triangle.2.circlepath")
                Label("~\(max(2, (newCount * 3 + min(dueCount, 10)) / 3)) phút", systemImage: "clock")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.9))

            Button {
                startLesson(.daily)
            } label: {
                HStack {
                    Text("Bắt đầu học")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(BigButtonStyle(color: .white, textColor: Theme.accent))
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            ZStack {
                Theme.accentGradient
                Circle().fill(Color.white.opacity(0.08)).frame(width: 220, height: 220).offset(x: 130, y: -70)
                Circle().fill(Color.white.opacity(0.06)).frame(width: 140, height: 140).offset(x: -140, y: 90)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.35), radius: 16, x: 0, y: 10)
    }

    private var reviewCard: some View {
        Button {
            startLesson(.review)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.warning))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ôn tập nhanh")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(dueCount) từ đến hạn ôn — đừng để quên nhé!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .card(padding: 14)
        }
        .buttonStyle(PressableStyle())
    }

    private func wordOfDayCard(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TỪ CỦA NGÀY")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                SpeakButton(text: word.word, size: 38)
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(word.word)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(word.ipa)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.accent)
            }
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.vi)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("“\(word.ex)”")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .italic()
                        .foregroundColor(Theme.textSecondary)
                }
                .blur(radius: revealWordOfDay ? 0 : 8)
                if !revealWordOfDay {
                    Text("Chạm để xem nghĩa")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.3)) { revealWordOfDay.toggle() }
            }
        }
        .card()
    }

    private var focusTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundColor(Theme.warning)
            Text("Mẹo tập trung: mỗi bài chỉ ~5 phút. Học đều mỗi ngày giúp nhớ lâu hơn học dồn — ứng dụng sẽ tự nhắc ôn đúng lúc bạn sắp quên.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.cardRaised))
    }
}
