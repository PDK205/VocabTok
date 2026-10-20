import SwiftUI

struct TopicsView: View {
    @EnvironmentObject private var store: ProgressStore
    let startLesson: (LessonMode) -> Void
    private let bank = WordBank.shared
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(bank.topics) { topic in
                        NavigationLink {
                            TopicDetailView(topic: topic, startLesson: startLesson)
                        } label: {
                            TopicCard(topic: topic,
                                      learned: store.learnedCount(in: topic.id),
                                      total: bank.words(in: topic.id).count,
                                      mastery: store.masteredRatio(in: topic.id))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(18)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Chủ đề")
        }
    }
}

private struct TopicCard: View {
    let topic: Topic
    let learned: Int
    let total: Int
    let mastery: Double

    var body: some View {
        let color = Color(hex: topic.color)
        VStack(alignment: .leading, spacing: 10) {
            Text(topic.emoji)
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color.opacity(0.15)))
            Text(topic.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
            CapsuleProgressBar(progress: mastery, color: color, height: 8)
            Text("\(learned)/\(total) từ đã học")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .card(padding: 14)
    }
}

struct TopicDetailView: View {
    @EnvironmentObject private var store: ProgressStore
    let topic: Topic
    let startLesson: (LessonMode) -> Void
    @State private var selected: Word? = nil

    private var words: [Word] { WordBank.shared.words(in: topic.id) }

    var body: some View {
        let color = Color(hex: topic.color)
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Text(topic.emoji).font(.system(size: 54))
                    Text(topic.name)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(store.learnedCount(in: topic.id))/\(words.count) từ đã học · \(Int(store.masteredRatio(in: topic.id) * 100))% thành thạo")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                    Button {
                        startLesson(.topic(topic.id))
                    } label: {
                        Label(store.newWords(in: topic.id).isEmpty ? "Ôn luyện chủ đề" : "Học chủ đề này", systemImage: "play.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: color))
                    .padding(.top, 6)
                }
                .card()

                VStack(spacing: 0) {
                    ForEach(words) { word in
                        Button {
                            Haptics.tap()
                            selected = word
                        } label: {
                            WordRow(word: word, mastery: store.mastery(of: word))
                        }
                        .buttonStyle(.plain)
                        if word.id != words.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { word in
            WordDetailSheet(word: word)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct WordRow: View {
    let word: Word
    let mastery: MasteryLevel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(word.word)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(mastery == .new ? "• • •" : word.vi)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            MasteryDots(level: mastery)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct MasteryDots: View {
    let level: MasteryLevel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1..<4) { i in
                Capsule()
                    .fill(i <= level.rawValue ? color : Theme.cardRaised)
                    .frame(width: 14, height: 6)
            }
        }
        .accessibilityLabel(level.label)
    }

    private var color: Color {
        switch level {
        case .new: return Theme.cardRaised
        case .learning: return Theme.warning
        case .familiar: return Theme.sky
        case .mastered: return Theme.success
        }
    }
}

struct WordDetailSheet: View {
    @EnvironmentObject private var store: ProgressStore
    let word: Word

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.word)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        HStack(spacing: 8) {
                            Text(word.ipa).foregroundColor(Theme.accent)
                            Text(word.posLabel)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.cardRaised))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(spacing: 10) {
                        SpeakButton(text: word.word, size: 46)
                        SpeakButton(text: word.word, slow: true, size: 46)
                    }
                }
                InfoBlock(title: "NGHĨA", icon: "character.book.closed.fill") {
                    Text(word.vi).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundColor(Theme.textPrimary)
                }
                InfoBlock(title: "VÍ DỤ", icon: "text.quote") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(word.ex).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Button { SpeechManager.shared.speak(word.ex) } label: {
                                Image(systemName: "speaker.wave.2.fill").foregroundColor(Theme.accent)
                            }
                        }
                        Text(word.exVi).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Theme.textSecondary)
                    }
                }
                if let tip = word.tip {
                    InfoBlock(title: "MẸO NHỚ", icon: "lightbulb.fill") {
                        Text(tip).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(Theme.textPrimary)
                    }
                }
                HStack {
                    Text("Trạng thái:").foregroundColor(Theme.textSecondary)
                    Text(store.mastery(of: word).label).bold().foregroundColor(Theme.textPrimary)
                    Spacer()
                    MasteryDots(level: store.mastery(of: word))
                }
                .font(.system(size: 14, design: .rounded))
            }
            .padding(22)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct InfoBlock<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
    }
}
