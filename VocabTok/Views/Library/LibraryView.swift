import SwiftUI

struct LibraryView: View {
    private let content = ContentStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    SectionHeader(title: "Tài liệu", subtitle: "Kiến thức nền tảng – tra cứu bất cứ lúc nào")
                        .padding(.top, 8)

                    NavigationLink { RoadmapView() } label: {
                        LibraryHero()
                    }
                    .buttonStyle(PressableStyle())

                    LibraryRow(icon: "puzzlepiece.extension.fill", color: Theme.accent, title: "Ngữ pháp theo cấp độ",
                               detail: "\(content.units.count) chủ điểm từ A1 đến C1") { GrammarListView() }
                    LibraryRow(icon: "clock.arrow.circlepath", color: Theme.sky, title: "12 thì tiếng Anh",
                               detail: "Công thức, cách dùng, dấu hiệu nhận biết") { TensesView() }
                    LibraryRow(icon: "waveform.and.mic", color: Theme.pink, title: "Bảng phiên âm IPA",
                               detail: "44 âm & quy tắc phát âm cho người Việt") { PhoneticsView() }
                    LibraryRow(icon: "list.number", color: Theme.warning, title: "Động từ bất quy tắc",
                               detail: "\(content.irregularVerbs.count) động từ thông dụng nhất") { IrregularVerbsView() }
                    LibraryRow(icon: "bubble.left.and.text.bubble.right.fill", color: Theme.success, title: "Mẫu câu giao tiếp",
                               detail: "\(content.allPhrases.count) câu theo tình huống") { PhrasebookView() }
                    LibraryRow(icon: "character.book.closed.fill", color: Color(hex: "14B8A6"), title: "Từ điển giáo trình",
                               detail: "\(content.allWords.count) từ vựng có phiên âm, ví dụ") { DictionaryView() }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

private struct LibraryHero: View {
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LỘ TRÌNH & PHƯƠNG PHÁP")
                    .font(.rounded(12, .heavy))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.85))
                Text("Từ A1 đến C1 trong 5 cấp độ")
                    .font(.rounded(21, .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Text("Hiểu cách app giúp bạn nhớ lâu và học hiệu quả mỗi ngày")
                    .font(.rounded(13, .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "map.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .background(
            ZStack {
                Theme.accentGradient
                Circle().fill(Color.white.opacity(0.08)).frame(width: 200, height: 200).offset(x: 140, y: -60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 8)
    }
}

private struct LibraryRow<Destination: View>: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                IconBadge(icon: icon, color: color, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.rounded(16, .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(detail)
                        .font(.rounded(13, .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .card(padding: 14)
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Roadmap & method

struct RoadmapView: View {
    @EnvironmentObject private var store: ProgressStore
    private let content = ContentStore.shared
    @State private var level: Level?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Lộ trình A1 → C1", subtitle: "Theo Khung tham chiếu châu Âu (CEFR)")
                VStack(spacing: 0) {
                    ForEach(Array(content.levels.enumerated()), id: \.element.id) { i, lvl in
                        Button { level = lvl } label: {
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 0) {
                                    Text(lvl.emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 48, height: 48)
                                        .background(Circle().fill(Color(hex: lvl.color).opacity(0.18)))
                                    if i < content.levels.count - 1 {
                                        Rectangle().fill(Theme.stroke).frame(width: 3, height: 44)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(lvl.id) · \(lvl.name)")
                                            .font(.rounded(17, .heavy))
                                            .foregroundColor(Theme.textPrimary)
                                        if store.isLevelCompleted(lvl.id) {
                                            Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                                        }
                                    }
                                    Text("\(lvl.units.count) unit · \(lvl.hours)")
                                        .font(.rounded(13, .semibold))
                                        .foregroundColor(Color(hex: lvl.color))
                                    Text(lvl.description)
                                        .font(.rounded(13, .medium))
                                        .foregroundColor(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .card()

                if let guide = content.guide {
                    SectionHeader(title: "App hoạt động thế nào?")
                    ForEach(guide.howItWorks) { item in
                        GuideRow(item: item, color: Theme.sky)
                    }

                    SectionHeader(title: "Phương pháp học khoa học", subtitle: "Những nguyên lý đã được nghiên cứu chứng minh")
                    ForEach(guide.methods) { item in
                        GuideRow(item: item, color: Theme.accent)
                    }

                    SectionHeader(title: "Kế hoạch 10–15 phút mỗi ngày")
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(guide.dailyPlan) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Text(step.time)
                                    .font(.rounded(12, .heavy))
                                    .foregroundColor(Theme.accent)
                                    .frame(width: 66, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title).font(.rounded(15, .bold)).foregroundColor(Theme.textPrimary)
                                    Text(step.body).font(.rounded(13, .medium)).foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    SectionHeader(title: "10 mẹo học tiếng Anh hiệu quả")
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(guide.tips.enumerated()), id: \.offset) { i, tip in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.rounded(12, .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Theme.success))
                                Text(tip)
                                    .font(.rounded(14, .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Lộ trình & Phương pháp")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $level) { lvl in LevelDetailView(level: lvl) }
    }
}

private struct GuideRow: View {
    let item: GuideItem
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(icon: item.icon, color: color, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.rounded(16, .bold))
                    .foregroundColor(Theme.textPrimary)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.rounded(12, .heavy))
                        .foregroundColor(color)
                }
                Text(item.body)
                    .font(.rounded(14, .medium))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 16)
    }
}
