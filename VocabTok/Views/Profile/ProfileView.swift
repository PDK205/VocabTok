import SwiftUI
import Charts

struct ProfileView: View {
    @EnvironmentObject private var store: ProgressStore
    private let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    StreakCard()
                    QuestsCard()
                    LazyVGrid(columns: statColumns, spacing: 12) {
                        StatTile(icon: "checkmark.seal.fill", color: Theme.success, value: "\(store.data.lessonsCompleted)", label: "Bài học")
                        StatTile(icon: "book.fill", color: Theme.accent, value: "\(store.learnedCount)", label: "Từ đã học")
                        StatTile(icon: "star.fill", color: Theme.warning, value: "\(store.masteredCount)", label: "Thành thạo")
                        StatTile(icon: "target", color: Theme.sky, value: "\(Int(store.accuracy * 100))%", label: "Chính xác")
                        StatTile(icon: "mic.fill", color: Theme.pink, value: "\(store.data.speakingCount)", label: "Lần nói")
                        StatTile(icon: "clock.fill", color: Color(hex: "14B8A6"), value: "\(store.data.secondsStudied / 60)p", label: "Thời gian")
                    }
                    WeekChartCard()
                    achievementsPreview
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Hồ sơ")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }

    private var header: some View {
        let name = store.data.name.isEmpty ? "Bạn" : store.data.name
        return HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: store.xpLevelProgress, lineWidth: 6)
                    .frame(width: 78, height: 78)
                Text(String(name.prefix(1)).uppercased())
                    .font(.rounded(30, .heavy))
                    .foregroundColor(.white)
                    .frame(width: 62, height: 62)
                    .background(Circle().fill(Theme.accentGradient))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.rounded(24, .heavy))
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: 6) {
                    if let level = store.currentLevel {
                        Chip(text: "\(level.emoji) \(level.id) · \(level.name)", color: Theme.levelColor(level))
                    }
                    Chip(text: "Cấp \(store.xpLevel)", color: Theme.accent, icon: "bolt.fill")
                }
                Text("\(store.data.totalXP) XP · còn \(store.xpToNextLevel) XP lên cấp \(store.xpLevel + 1)")
                    .font(.rounded(12, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var achievementsPreview: some View {
        let all = AchievementBook.all
        let earned = all.filter { store.data.achievements[$0.id] != nil }
        return NavigationLink {
            AchievementsView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Thành tích")
                        .font(.rounded(17, .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(earned.count)/\(all.count)")
                        .font(.rounded(13, .bold))
                        .foregroundColor(Theme.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
                HStack(spacing: 10) {
                    ForEach(Array((earned.isEmpty ? Array(all.prefix(5)) : Array(earned.suffix(5))).enumerated()), id: \.offset) { _, achievement in
                        AchievementBadge(achievement: achievement, earned: store.data.achievements[achievement.id] != nil, size: 52)
                    }
                    Spacer(minLength: 0)
                }
            }
            .card()
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Streak

struct StreakCard: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(store.isStreakActiveToday ? AnyShapeStyle(Theme.flameGradient) : AnyShapeStyle(Theme.textSecondary.opacity(0.5)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.data.streak) ngày liên tiếp")
                        .font(.rounded(22, .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(store.isStreakActiveToday ? "Đã giữ lửa hôm nay 🔥" : "Học một bài để giữ chuỗi hôm nay!")
                        .font(.rounded(13, .semibold))
                        .foregroundColor(store.isStreakActiveToday ? Theme.flame : Theme.textSecondary)
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    Text("\(store.data.bestStreak)")
                        .font(.rounded(18, .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Kỷ lục")
                        .font(.rounded(11, .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(store.weekActivity.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(day.active ? AnyShapeStyle(Theme.flameGradient) : AnyShapeStyle(Theme.cardRaised))
                                .frame(width: 32, height: 32)
                            if day.active {
                                Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundColor(.white)
                            }
                        }
                        .overlay(Circle().strokeBorder(day.isToday ? Theme.flame : Color.clear, lineWidth: 2).frame(width: 38, height: 38))
                        Text(day.label)
                            .font(.rounded(11, .bold))
                            .foregroundColor(day.isToday ? Theme.flame : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "snowflake").foregroundColor(Theme.ice)
                Text("Bảo vệ chuỗi: \(store.data.freezes)/2 · nhận thêm mỗi 7 ngày liên tiếp, tự dùng khi bạn lỡ 1 ngày.")
                    .font(.rounded(12, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }
}

// MARK: - Daily quests

struct QuestsCard: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var opened = false

    var body: some View {
        let today = store.today
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Nhiệm vụ hôm nay")
                    .font(.rounded(17, .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("Làm mới lúc 0h")
                    .font(.rounded(12, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            ForEach(store.todayQuests) { quest in
                let value = quest.progress(in: today)
                HStack(spacing: 12) {
                    IconBadge(icon: quest.icon, color: quest.isDone(in: today) ? Theme.success : Theme.accent, size: 38)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(quest.title)
                                .font(.rounded(14, .bold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(value)/\(quest.target)")
                                .font(.rounded(12, .bold))
                                .foregroundColor(Theme.textSecondary)
                        }
                        CapsuleProgressBar(progress: Double(value) / Double(max(quest.target, 1)), color: quest.isDone(in: today) ? Theme.success : Theme.accent, height: 9)
                    }
                }
            }
            Button {
                guard store.allQuestsDone, !store.chestClaimedToday else { return }
                Haptics.celebrate()
                SoundFX.unlock.play()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { opened = true }
                store.claimChest()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: store.chestClaimedToday ? "gift.fill" : "shippingbox.fill")
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(opened ? 0 : (store.allQuestsDone && !store.chestClaimedToday ? -8 : 0)))
                    Text(store.chestClaimedToday ? "Đã nhận +\(QuestBook.chestXP) XP hôm nay" : (store.allQuestsDone ? "Mở rương thưởng +\(QuestBook.chestXP) XP" : "Hoàn thành 3 nhiệm vụ để mở rương"))
                        .font(.rounded(15, .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundColor(store.allQuestsDone && !store.chestClaimedToday ? .white : Theme.textSecondary)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(store.allQuestsDone && !store.chestClaimedToday ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.cardRaised))
                )
            }
            .buttonStyle(PressableStyle())
            .disabled(!store.allQuestsDone || store.chestClaimedToday)
        }
        .card()
    }
}

// MARK: - Week chart

struct WeekChartCard: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        let week = store.weekXP
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("XP 7 ngày qua")
                    .font(.rounded(17, .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(week.reduce(0) { $0 + $1.xp }) XP")
                    .font(.rounded(14, .bold))
                    .foregroundColor(Theme.accent)
            }
            Chart {
                ForEach(Array(week.enumerated()), id: \.offset) { item in
                    BarMark(
                        x: .value("Ngày", item.element.label),
                        y: .value("XP", item.element.xp)
                    )
                    .foregroundStyle(item.element.isToday ? Theme.accent : Theme.accentLight.opacity(0.6))
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Mục tiêu", store.dailyGoal))
                    .foregroundStyle(Theme.success.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
        }
        .card()
    }
}

// MARK: - Achievements

struct AchievementBadge: View {
    let achievement: Achievement
    let earned: Bool
    var size: CGFloat = 64

    var body: some View {
        Image(systemName: achievement.icon)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(earned ? .white : Theme.textSecondary.opacity(0.5))
            .frame(width: size, height: size)
            .background(
                Circle().fill(earned ? AnyShapeStyle(Color(hex: achievement.color).gradient) : AnyShapeStyle(Theme.cardRaised))
            )
            .overlay(Circle().strokeBorder(earned ? Color.white.opacity(0.4) : Color.clear, lineWidth: 2))
    }
}

struct AchievementsView: View {
    @EnvironmentObject private var store: ProgressStore
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(AchievementBook.all) { achievement in
                    let date = store.data.achievements[achievement.id]
                    VStack(spacing: 8) {
                        AchievementBadge(achievement: achievement, earned: date != nil, size: 70)
                        Text(achievement.title)
                            .font(.rounded(14, .bold))
                            .foregroundColor(date != nil ? Theme.textPrimary : Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Text(achievement.detail)
                            .font(.rounded(11, .medium))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                        if let date {
                            Text(date, style: .date)
                                .font(.rounded(10, .semibold))
                                .foregroundColor(Theme.success)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Thành tích")
    }
}
