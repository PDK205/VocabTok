import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("dailyGoal") private var dailyGoal = 50
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    private enum Step: Int, CaseIterable { case welcome, name, reason, goal, reminder, level, placement, done }

    @State private var step: Step = .welcome
    @State private var name = ""
    @State private var reason = ""
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var startLevel = 0
    @FocusState private var nameFocused: Bool

    private let reasons: [(String, String)] = [
        ("💬", "Giao tiếp hằng ngày"), ("✈️", "Du lịch"), ("💼", "Công việc"),
        ("🎓", "Học tập, thi cử"), ("📝", "IELTS / TOEIC"), ("🎬", "Phim ảnh, âm nhạc")
    ]

    private let goals: [(Int, String, String)] = [
        (30, "Thư giãn", "~5 phút / ngày"), (50, "Bình thường", "~10 phút / ngày"),
        (100, "Nghiêm túc", "~20 phút / ngày"), (150, "Cấp tốc", "~30 phút / ngày")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if step == .placement {
                PlacementTestView { levelIndex in
                    startLevel = levelIndex
                    go(.done)
                }
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    if step != .welcome && step != .done {
                        HStack(spacing: 14) {
                            Button { back() } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(width: 36, height: 36)
                            }
                            CapsuleProgressBar(progress: Double(step.rawValue) / Double(Step.level.rawValue), color: Theme.accent, height: 10)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                    }
                    Group {
                        switch step {
                        case .welcome: welcome
                        case .name: nameStep
                        case .reason: reasonStep
                        case .goal: goalStep
                        case .reminder: reminderStep
                        case .level: levelStep
                        case .placement: EmptyView()
                        case .done: doneStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
        }
    }

    private func go(_ next: Step) {
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { step = next }
    }

    private func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        go(previous)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.12)).frame(width: 220, height: 220)
                Circle().fill(Theme.accent.opacity(0.18)).frame(width: 160, height: 160)
                Text("Aa")
                    .font(.rounded(72, .heavy))
                    .foregroundStyle(Theme.accentGradient)
            }
            VStack(spacing: 10) {
                Text("Chào mừng đến VocabTok")
                    .font(.rounded(30, .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Lộ trình tiếng Anh từ A1 đến C1: từ vựng, ngữ pháp, nghe, nói, đọc – chỉ 10 phút mỗi ngày.")
                    .font(.rounded(16, .medium))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 18) {
                feature("map.fill", "48 unit")
                feature("character.book.closed.fill", "576 từ")
                feature("mic.fill", "Chấm phát âm")
            }
            Spacer()
            Button("Bắt đầu ngay") { go(.name) }
                .buttonStyle(BigButtonStyle())
        }
        .padding(24)
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        VStack(spacing: 6) {
            IconBadge(icon: icon, color: Theme.accent, size: 46)
            Text(text).font(.rounded(12, .bold)).foregroundColor(Theme.textSecondary)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Bạn tên là gì? 👋")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 24)
            Text("Để VocabTok gọi tên và cổ vũ bạn mỗi ngày.")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
            TextField("Nhập tên của bạn", text: $name)
                .font(.rounded(22, .bold))
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(nameFocused ? Theme.accent : Theme.stroke, lineWidth: 2))
                .submitLabel(.next)
                .onSubmit { go(.reason) }
            Spacer()
            Button("Tiếp tục") {
                nameFocused = false
                go(.reason)
            }
            .buttonStyle(BigButtonStyle())
        }
        .padding(24)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { nameFocused = true } }
    }

    private var reasonStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Bạn học tiếng Anh để làm gì?")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 24)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(reasons.indices, id: \.self) { i in
                    let item = reasons[i]
                    Button {
                        Haptics.tap()
                        reason = item.1
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.0).font(.system(size: 34))
                            Text(item.1)
                                .font(.rounded(14, .bold))
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(reason == item.1 ? Theme.accent.opacity(0.12) : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(reason == item.1 ? Theme.accent : Theme.stroke, lineWidth: 2))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            Spacer()
            Button("Tiếp tục") { go(.goal) }
                .buttonStyle(BigButtonStyle(enabled: !reason.isEmpty))
                .disabled(reason.isEmpty)
        }
        .padding(24)
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Mục tiêu mỗi ngày")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 24)
            Text("Học đều đặn quan trọng hơn học nhiều. Bạn có thể đổi lại bất cứ lúc nào.")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
            VStack(spacing: 10) {
                ForEach(goals.indices, id: \.self) { i in
                    let goal = goals[i]
                    Button {
                        Haptics.tap()
                        dailyGoal = goal.0
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.1).font(.rounded(17, .bold)).foregroundColor(Theme.textPrimary)
                                Text(goal.2).font(.rounded(13, .medium)).foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(goal.0) XP").font(.rounded(15, .heavy)).foregroundColor(Theme.accent)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(dailyGoal == goal.0 ? Theme.accent.opacity(0.12) : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(dailyGoal == goal.0 ? Theme.accent : Theme.stroke, lineWidth: 2))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            Spacer()
            Button("Tiếp tục") { go(.reminder) }
                .buttonStyle(BigButtonStyle())
        }
        .padding(24)
    }

    private var reminderStep: some View {
        VStack(spacing: 18) {
            Text("Đặt lời nhắc học 🔔")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            Text("Người có lời nhắc mỗi ngày có khả năng duy trì thói quen cao hơn nhiều. Chọn khung giờ bạn thường rảnh.")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            Spacer()
            Button("Bật nhắc nhở") {
                let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                reminderHour = c.hour ?? 20
                reminderMinute = c.minute ?? 0
                Reminders.requestPermission { granted in
                    reminderOn = granted
                    if granted { Reminders.schedule(hour: reminderHour, minute: reminderMinute, name: name) }
                    go(.level)
                }
            }
            .buttonStyle(BigButtonStyle())
            Button("Để sau") { go(.level) }
                .font(.rounded(15, .bold))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(24)
    }

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Trình độ của bạn?")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 24)
            Text("Chọn điểm xuất phát phù hợp để không mất thời gian với những gì bạn đã biết.")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
            Button {
                startLevel = 0
                go(.done)
            } label: {
                levelOption(icon: "leaf.fill", color: Theme.success, title: "Tôi mới bắt đầu", detail: "Học từ đầu với cấp độ A1")
            }
            .buttonStyle(PressableStyle())
            Button {
                go(.placement)
            } label: {
                levelOption(icon: "checklist", color: Theme.accent, title: "Làm bài kiểm tra xếp lớp", detail: "Khoảng 5 phút · tối đa 25 câu · tìm cấp độ phù hợp")
            }
            .buttonStyle(PressableStyle())
            Spacer()
        }
        .padding(24)
    }

    private func levelOption(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: color, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.rounded(17, .bold)).foregroundColor(Theme.textPrimary)
                Text(detail).font(.rounded(13, .medium)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Theme.textSecondary)
        }
        .card(padding: 16)
    }

    private var doneStep: some View {
        let level = ContentStore.shared.levels.indices.contains(startLevel) ? ContentStore.shared.levels[startLevel] : nil
        return VStack(spacing: 20) {
            Spacer()
            Text(level?.emoji ?? "🌱").font(.system(size: 80))
            Text("Lộ trình của bạn đã sẵn sàng!")
                .font(.rounded(28, .heavy))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            if let level {
                VStack(spacing: 8) {
                    Text("Bắt đầu từ cấp độ")
                        .font(.rounded(15, .medium))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(level.id) · \(level.name)")
                        .font(.rounded(26, .heavy))
                        .foregroundColor(Color(hex: level.color))
                    Text(level.description)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .card()
            }
            Text("Mục tiêu: \(dailyGoal) XP mỗi ngày")
                .font(.rounded(15, .bold))
                .foregroundColor(Theme.accent)
            Spacer()
            Button("Vào học thôi! 🚀") {
                store.setStartLevel(startLevel)
                store.completeOnboarding(name: name, reason: reason)
            }
            .buttonStyle(BigButtonStyle(color: Theme.success))
        }
        .padding(24)
        .overlay(ConfettiView())
    }
}
