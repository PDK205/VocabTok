import SwiftUI
import Charts

struct ProfileView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("dailyGoal") private var dailyGoal = 50
    @AppStorage("newPerLesson") private var newPerLesson = 5
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("hapticsOn") private var hapticsOn = true
    @AppStorage("theme") private var theme = "system"
    @State private var confirmReset = false

    private let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    levelCard
                    LazyVGrid(columns: statColumns, spacing: 12) {
                        StatTile(icon: "flame.fill", color: Theme.flame, value: "\(store.data.streak)", label: "Chuỗi ngày")
                        StatTile(icon: "trophy.fill", color: Theme.warning, value: "\(store.data.bestStreak)", label: "Kỷ lục")
                        StatTile(icon: "target", color: Theme.success, value: "\(Int(store.accuracy * 100))%", label: "Chính xác")
                        StatTile(icon: "book.fill", color: Theme.accent, value: "\(store.learnedCount)", label: "Đã học")
                        StatTile(icon: "star.fill", color: Color(hex: "EC4899"), value: "\(store.masteredCount)", label: "Thành thạo")
                        StatTile(icon: "checkmark.circle.fill", color: Theme.sky, value: "\(store.data.lessonsCompleted)", label: "Bài học")
                    }
                    weekChart
                    settings
                }
                .padding(18)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Tiến độ")
            .confirmationDialog("Xoá toàn bộ tiến độ học?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Xoá tất cả", role: .destructive) { store.resetAll() }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Không thể hoàn tác thao tác này.")
            }
        }
    }

    private var levelCard: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: store.levelProgress, lineWidth: 10)
                    .frame(width: 84, height: 84)
                VStack(spacing: 0) {
                    Text("CẤP").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundColor(Theme.textSecondary)
                    Text("\(store.level)").font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundColor(Theme.textPrimary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("\(store.data.totalXP) XP")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("Còn \(store.xpToNextLevel) XP để lên cấp \(store.level + 1)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var weekChart: some View {
        let week = store.weekXP
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("XP 7 ngày qua")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(week.reduce(0) { $0 + $1.xp }) XP")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
                RuleMark(y: .value("Mục tiêu", dailyGoal))
                    .foregroundStyle(Theme.success.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 160)
        }
        .card()
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Cài đặt")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 10)

            SettingRow(icon: "target", color: Theme.success, title: "Mục tiêu mỗi ngày") {
                Picker("", selection: $dailyGoal) {
                    ForEach([30, 50, 100, 150], id: \.self) { Text("\($0) XP").tag($0) }
                }
                .pickerStyle(.menu)
            }
            Divider()
            SettingRow(icon: "sparkles", color: Theme.accent, title: "Từ mới mỗi bài") {
                Picker("", selection: $newPerLesson) {
                    ForEach([3, 5, 8, 10], id: \.self) { Text("\($0) từ").tag($0) }
                }
                .pickerStyle(.menu)
            }
            Divider()
            SettingRow(icon: "circle.lefthalf.filled", color: Theme.textSecondary, title: "Giao diện") {
                Picker("", selection: $theme) {
                    Text("Tự động").tag("system")
                    Text("Sáng").tag("light")
                    Text("Tối").tag("dark")
                }
                .pickerStyle(.menu)
            }
            Divider()
            SettingRow(icon: "play.circle.fill", color: Theme.sky, title: "Tự phát âm") {
                Toggle("", isOn: $autoPlay).labelsHidden()
            }
            Divider()
            SettingRow(icon: "speaker.wave.2.fill", color: Theme.warning, title: "Âm thanh") {
                Toggle("", isOn: $soundOn).labelsHidden()
            }
            Divider()
            SettingRow(icon: "iphone.radiowaves.left.and.right", color: Color(hex: "EC4899"), title: "Rung phản hồi") {
                Toggle("", isOn: $hapticsOn).labelsHidden()
            }
            Divider()
            Button {
                confirmReset = true
            } label: {
                SettingRow(icon: "trash.fill", color: Theme.danger, title: "Xoá tiến độ") { EmptyView() }
            }
            .buttonStyle(.plain)
        }
        .card()
    }
}

private struct StatTile: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}

private struct SettingRow<Trailing: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color))
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            trailing
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
