import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router
    @State private var showSpeedMatch = false
    @State private var showFeed = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var feedWords: [Word] {
        let learned = store.learnedWords
        if learned.count >= 5 { return learned.shuffled() }
        return (store.currentUnit?.words ?? Array(ContentStore.shared.allWords.prefix(12)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "Luyện tập", subtitle: "Ôn đúng lúc – nhớ thật lâu")
                        .padding(.top, 8)
                    reviewCard
                    masteryCard
                    LazyVGrid(columns: columns, spacing: 12) {
                        PracticeTile(icon: "exclamationmark.bubble.fill", color: Theme.danger, title: "Từ hay sai",
                                     detail: store.difficultWords.isEmpty ? "Chưa có từ nào" : "\(store.difficultWords.count) từ cần củng cố") {
                            router.start(.difficult)
                        }
                        .disabled(store.difficultWords.isEmpty)
                        .opacity(store.difficultWords.isEmpty ? 0.55 : 1)

                        PracticeTile(icon: "keyboard.fill", color: Theme.sky, title: "Nghe chép chính tả", detail: "Nghe câu và gõ lại") {
                            router.start(.dictation)
                        }
                        PracticeTile(icon: "waveform", color: Theme.pink, title: "Luyện phát âm", detail: "App chấm điểm giọng nói") {
                            router.start(.pronunciation)
                        }
                        PracticeTile(icon: "bolt.fill", color: Theme.warning, title: "Ghép cặp tốc độ",
                                     detail: store.data.speedMatchBest > 0 ? "Kỷ lục: \(store.data.speedMatchBest) cặp" : "Thử thách 60 giây") {
                            Haptics.tap()
                            showSpeedMatch = true
                        }
                        PracticeTile(icon: "rectangle.stack.fill", color: Theme.accent, title: "Lướt từ vựng", detail: "Vuốt như TikTok") {
                            Haptics.tap()
                            showFeed = true
                        }
                        NavigationLink {
                            NotebookView()
                        } label: {
                            PracticeTileLabel(icon: "bookmark.fill", color: Color(hex: "14B8A6"), title: "Sổ tay", detail: "\(store.data.savedWords.count) từ đã lưu")
                        }
                        .buttonStyle(PressableStyle())
                    }
                    tipCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSpeedMatch) {
                SpeedMatchView()
            }
            .fullScreenCover(isPresented: $showFeed) {
                WordFeedView(words: feedWords)
            }
        }
    }

    private var reviewCard: some View {
        let due = store.dueWords.count
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ÔN TẬP THÔNG MINH")
                        .font(.rounded(12, .heavy))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.85))
                    Text(due > 0 ? "\(due) từ đến hạn ôn" : (store.learnedCount > 0 ? "Bạn đã ôn hết! 🎉" : "Chưa có từ để ôn"))
                        .font(.rounded(24, .heavy))
                        .foregroundColor(.white)
                    Text(due > 0 ? "Ôn ngay trước khi quên – chỉ mất vài phút." : "Hệ thống sẽ nhắc khi có từ sắp quên. Bạn vẫn có thể luyện tự do.")
                        .font(.rounded(13, .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.9))
            }
            Button {
                router.start(.review)
            } label: {
                Text(due > 0 ? "Bắt đầu ôn tập" : "Luyện tự do")
            }
            .buttonStyle(BigButtonStyle(color: .white, textColor: Theme.warning, enabled: store.learnedCount > 0))
            .disabled(store.learnedCount == 0)
        }
        .padding(20)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "F97316")], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color.white.opacity(0.1)).frame(width: 200, height: 200).offset(x: 130, y: -60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.warning.opacity(0.35), radius: 14, y: 8)
    }

    private var masteryCard: some View {
        let counts = store.masteryCounts()
        let total = max(ContentStore.shared.allWords.count, 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Kho từ vựng của bạn")
                    .font(.rounded(17, .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(store.learnedCount)/\(total) từ")
                    .font(.rounded(13, .bold))
                    .foregroundColor(Theme.accent)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach([MasteryLevel.mastered, .familiar, .learning], id: \.self) { level in
                        let count = counts[level] ?? 0
                        if count > 0 {
                            Rectangle()
                                .fill(color(for: level))
                                .frame(width: max(4, geo.size.width * CGFloat(count) / CGFloat(total)))
                        }
                    }
                    Rectangle().fill(Theme.cardRaised)
                }
                .clipShape(Capsule())
            }
            .frame(height: 12)
            HStack(spacing: 14) {
                ForEach([MasteryLevel.learning, .familiar, .mastered], id: \.self) { level in
                    HStack(spacing: 5) {
                        Circle().fill(color(for: level)).frame(width: 9, height: 9)
                        Text("\(level.label) \(counts[level] ?? 0)")
                            .font(.rounded(12, .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .card()
    }

    private func color(for level: MasteryLevel) -> Color {
        switch level {
        case .new: return Theme.cardRaised
        case .learning: return Theme.warning
        case .familiar: return Theme.sky
        case .mastered: return Theme.success
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundColor(Theme.warning)
            Text("Mẹo: Ôn tập mỗi ngày quan trọng hơn học nhiều bài mới. Một từ được ôn đúng 5 lần ở các thời điểm giãn cách sẽ nằm trong trí nhớ dài hạn.")
                .font(.rounded(13, .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.cardRaised))
    }
}

struct PracticeTile: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PracticeTileLabel(icon: icon, color: color, title: title, detail: detail)
        }
        .buttonStyle(PressableStyle())
    }
}

struct PracticeTileLabel: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(icon: icon, color: color, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.rounded(16, .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(detail)
                    .font(.rounded(12, .medium))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .card(padding: 14)
    }
}

struct NotebookView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router
    @State private var selected: Word?

    var body: some View {
        let words = store.savedWords
        List {
            if words.isEmpty {
                EmptyStateView(emoji: "🔖", title: "Sổ tay trống", message: "Chạm biểu tượng dấu trang ở thẻ từ để lưu những từ bạn muốn ôn thêm.")
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    Button {
                        router.start(.words(words.map(\.id), title: "Ôn sổ tay"))
                    } label: {
                        Label("Luyện tập \(words.count) từ trong sổ tay", systemImage: "play.fill")
                            .font(.rounded(16, .bold))
                    }
                }
                Section("Từ đã lưu") {
                    ForEach(words) { word in
                        Button { selected = word } label: {
                            WordRow(word: word, mastery: store.mastery(of: word))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .swipeActions {
                            Button(role: .destructive) { store.toggleSaved(word) } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sổ tay")
        .sheet(item: $selected) { word in
            WordDetailSheet(word: word).presentationDetents([.medium, .large])
        }
    }
}
