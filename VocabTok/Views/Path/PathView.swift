import SwiftUI

/// The learning path: levels → units → lessons, Duolingo style.
struct PathView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router
    @State private var selectedLesson: Lesson?
    @State private var grammarUnit: Unit?
    @State private var wordsUnit: Unit?
    @State private var levelInfo: Level?
    private let content = ContentStore.shared

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        TodayCard()
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        ForEach(content.levels) { level in
                            LevelBanner(level: level, progress: store.levelProgress(level)) {
                                levelInfo = level
                            }
                            .padding(.horizontal, 18)
                            .padding(.bottom, 18)
                            .id("level-\(level.id)")

                            ForEach(level.units) { unit in
                                unitSection(unit, level: level)
                            }
                        }

                        Text("🎓 Bạn đã đi hết lộ trình! Hãy tiếp tục ôn tập để giữ vững phong độ.")
                            .font(.rounded(14, .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(30)
                    }
                    .padding(.bottom, 40)
                }
                .background(Theme.background.ignoresSafeArea())
                .safeAreaInset(edge: .top) { topBar(proxy: proxy) }
                .overlay(alignment: .bottomTrailing) {
                    if let current = store.currentLesson {
                        Button {
                            Haptics.tap()
                            withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo(current.id, anchor: .center) }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Theme.accent))
                                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(20)
                        .accessibilityLabel("Về bài học hiện tại")
                    }
                }
                .onAppear {
                    guard let current = store.currentLesson else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        proxy.scrollTo(current.id, anchor: .center)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedLesson) { lesson in
                LessonSheet(lesson: lesson) {
                    selectedLesson = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { router.start(.lesson(lesson)) }
                }
                .presentationDetents([.height(lesson.kind == .test ? 400 : 360)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $grammarUnit) { unit in
                NavigationStack {
                    ScrollView {
                        GrammarContentView(grammar: unit.grammar).padding(18)
                    }
                    .background(Theme.background.ignoresSafeArea())
                    .navigationTitle("Unit \(unit.number) · Ngữ pháp")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(item: $wordsUnit) { unit in
                UnitWordsView(unit: unit)
            }
            .sheet(item: $levelInfo) { level in
                LevelDetailView(level: level)
            }
        }
    }

    private func topBar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(content.levels) { level in
                    Button("\(level.emoji) \(level.id) · \(level.name)") {
                        withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo("level-\(level.id)", anchor: .top) }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(store.currentLevel?.emoji ?? "🌱")
                    Text(store.currentLevel?.id ?? "A1")
                        .font(.rounded(16, .heavy))
                        .foregroundColor(Theme.levelColor(store.currentLevel))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.card))
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(store.isStreakActiveToday ? AnyShapeStyle(Theme.flameGradient) : AnyShapeStyle(Theme.textSecondary))
                Text("\(store.data.streak)")
                    .font(.rounded(16, .heavy))
                    .foregroundColor(store.isStreakActiveToday ? Theme.flame : Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))

            HStack(spacing: 5) {
                Image(systemName: "bolt.fill").foregroundColor(Theme.warning)
                Text("\(store.data.totalXP)")
                    .font(.rounded(16, .heavy))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))

            if store.data.freezes > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "snowflake").foregroundColor(Theme.ice)
                    Text("\(store.data.freezes)")
                        .font(.rounded(15, .heavy))
                        .foregroundColor(Theme.ice)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.card))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.background.opacity(0.96).ignoresSafeArea(edges: .top))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    @ViewBuilder
    private func unitSection(_ unit: Unit, level: Level) -> some View {
        let color = Theme.levelColor(level)
        let lessons = content.lessons(in: unit.id)
        let reachable = store.isUnitReachable(unit.index)

        UnitHeaderView(unit: unit, color: color, completed: store.completedCount(in: unit.id), total: lessons.count, locked: !reachable, passed: store.isUnitPassed(unit.id)) {
            grammarUnit = unit
        } onWords: {
            wordsUnit = unit
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .id("unit-\(unit.id)")

        VStack(spacing: 18) {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { position, lesson in
                let pattern: [CGFloat] = [0, 55, 85, 55, 0, -55, -85]
                let direction: CGFloat = unit.index % 2 == 0 ? 1 : -1
                LessonNode(lesson: lesson, state: nodeState(for: lesson), color: color) {
                    Haptics.tap()
                    selectedLesson = lesson
                }
                .offset(x: pattern[position % pattern.count] * direction)
                .id(lesson.id)
            }
        }
        .padding(.bottom, 36)
    }

    private func nodeState(for lesson: Lesson) -> LessonNode.NodeState {
        if store.isCompleted(lesson) { return .completed(store.stars(for: lesson)) }
        if store.currentLesson?.id == lesson.id { return .current }
        if store.isUnlocked(lesson) { return .available }
        return .locked
    }
}

// MARK: - Today card

struct TodayCard: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = store.data.name.isEmpty ? "" : ", \(store.data.name)"
        switch hour {
        case 5..<12: return "Chào buổi sáng\(name) ☀️"
        case 12..<18: return "Chào buổi chiều\(name) 🌤"
        default: return "Chào buổi tối\(name) 🌙"
        }
    }

    var body: some View {
        let goal = store.dailyGoal
        let progress = Double(store.todayXP) / Double(max(goal, 1))
        let due = store.dueWords.count
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: progress, lineWidth: 9, colors: progress >= 1 ? [Theme.success, Color(hex: "86EFAC")] : [Theme.accent, Theme.accentLight])
                        .frame(width: 64, height: 64)
                    if progress >= 1 {
                        Image(systemName: "checkmark").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.success)
                    } else {
                        Text("\(Int(min(progress, 1) * 100))%")
                            .font(.rounded(15, .heavy))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.rounded(15, .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Mục tiêu: \(store.todayXP)/\(goal) XP hôm nay")
                        .font(.rounded(14, .semibold))
                        .foregroundColor(Theme.accent)
                    Text(progress >= 1 ? "Tuyệt! Bạn đã đạt mục tiêu ngày 🎉" : "Còn \(max(goal - store.todayXP, 0)) XP nữa, cố lên!")
                        .font(.rounded(12, .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                if let lesson = store.currentLesson, let unit = ContentStore.shared.unit(id: lesson.unitId) {
                    Button {
                        router.start(.lesson(lesson))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: lesson.kind.icon)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Học tiếp").font(.rounded(15, .heavy))
                                Text("Unit \(unit.number) · \(lesson.kind.title)")
                                    .font(.rounded(11, .semibold))
                                    .opacity(0.85)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "play.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accentGradient))
                    }
                    .buttonStyle(PressableStyle())
                }
                if due > 0 {
                    Button {
                        router.start(.review)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "brain.head.profile").font(.system(size: 17, weight: .bold))
                            Text("Ôn \(due)").font(.rounded(12, .heavy))
                        }
                        .foregroundColor(.white)
                        .frame(width: 70)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.warning))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .card()
    }
}

// MARK: - Level banner

struct LevelBanner: View {
    let level: Level
    let progress: Double
    let onInfo: () -> Void

    var body: some View {
        Button(action: onInfo) {
            HStack(spacing: 14) {
                Text(level.emoji)
                    .font(.system(size: 34))
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.22)))
                VStack(alignment: .leading, spacing: 4) {
                    Text("CẤP ĐỘ \(level.id) · \(level.nameEn.uppercased())")
                        .font(.rounded(11, .heavy))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.85))
                    Text(level.name)
                        .font(.rounded(22, .heavy))
                        .foregroundColor(.white)
                    CapsuleProgressBar(progress: progress, color: .white, height: 7)
                        .frame(maxWidth: 180)
                }
                Spacer(minLength: 0)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(18)
            .background(
                ZStack {
                    Theme.gradient(level.color)
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 180, height: 180).offset(x: 140, y: -50)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(hex: level.color).opacity(0.35), radius: 12, y: 8)
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Unit header

struct UnitHeaderView: View {
    let unit: Unit
    let color: Color
    let completed: Int
    let total: Int
    let locked: Bool
    let passed: Bool
    let onGrammar: () -> Void
    let onWords: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UNIT \(unit.number) · \(unit.levelId)")
                        .font(.rounded(12, .heavy))
                        .tracking(1)
                        .foregroundColor(color)
                    Text("\(unit.emoji) \(unit.title)")
                        .font(.rounded(19, .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(unit.goal)
                        .font(.rounded(13, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if passed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.goldGradient)
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textSecondary)
                } else {
                    Text("\(completed)/\(total)")
                        .font(.rounded(14, .heavy))
                        .foregroundColor(color)
                }
            }
            HStack(spacing: 8) {
                Button(action: onGrammar) {
                    Label(unit.grammar.title, systemImage: "book.closed.fill")
                        .lineLimit(1)
                }
                .buttonStyle(UnitPillStyle(color: color))
                Button(action: onWords) {
                    Label("12 từ", systemImage: "list.bullet.rectangle.fill")
                }
                .buttonStyle(UnitPillStyle(color: color))
                .fixedSize()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(color.opacity(locked ? 0.15 : 0.45), lineWidth: 2)
                )
        )
        .opacity(locked ? 0.75 : 1)
    }
}

struct UnitPillStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(12, .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(color.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

// MARK: - Lesson node

struct LessonNode: View {
    enum NodeState: Equatable {
        case locked, available, current, completed(Int)
    }

    let lesson: Lesson
    let state: NodeState
    let color: Color
    let action: () -> Void
    @State private var bounce = false

    private var size: CGFloat { lesson.kind == .test ? 84 : 72 }

    var body: some View {
        VStack(spacing: 6) {
            if state == .current {
                Text("BẮT ĐẦU")
                    .font(.rounded(13, .heavy))
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.card)
                            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    )
                    .offset(y: bounce ? -4 : 2)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bounce)
                    .onAppear { bounce = true }
            }
            Button(action: action) {
                ZStack {
                    if state == .current {
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 6)
                            .frame(width: size + 18, height: size + 18)
                    }
                    Circle()
                        .fill(baseColor)
                        .frame(width: size, height: size)
                        .offset(y: 6)
                    Circle()
                        .fill(topFill)
                        .frame(width: size, height: size)
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.36, weight: .bold))
                        .foregroundColor(iconColor)
                }
            }
            .buttonStyle(PressableStyle())

            if let stars = completedStars {
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(i <= stars ? Theme.gold : Theme.cardRaised)
                    }
                }
            } else {
                Text(lesson.kind.title)
                    .font(.rounded(11, .bold))
                    .foregroundColor(state == .locked ? Theme.textSecondary.opacity(0.6) : Theme.textSecondary)
            }
        }
    }

    private var completedStars: Int? {
        if case .completed(let stars) = state { return stars }
        return nil
    }

    private var iconName: String {
        if state == .locked { return lesson.kind == .test ? "crown.fill" : "lock.fill" }
        if case .completed = state { return lesson.kind == .test ? "crown.fill" : "checkmark" }
        return lesson.kind.icon
    }

    private var topFill: AnyShapeStyle {
        switch state {
        case .locked: return AnyShapeStyle(Theme.cardRaised)
        case .completed: return AnyShapeStyle(Theme.goldGradient)
        default: return AnyShapeStyle(color.gradient)
        }
    }

    private var baseColor: Color {
        switch state {
        case .locked: return Theme.stroke
        case .completed: return Color(hex: "D97706")
        default: return color.opacity(0.55)
        }
    }

    private var iconColor: Color {
        state == .locked ? Theme.textSecondary.opacity(0.6) : .white
    }
}
