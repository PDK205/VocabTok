import SwiftUI

/// Bottom sheet shown when tapping a node on the path.
struct LessonSheet: View {
    @EnvironmentObject private var store: ProgressStore
    let lesson: Lesson
    let onStart: () -> Void

    private var unit: Unit? { ContentStore.shared.unit(id: lesson.unitId) }
    private var level: Level? { unit.flatMap { ContentStore.shared.level(of: $0) } }

    var body: some View {
        let color = Theme.levelColor(level)
        let unlocked = store.isUnlocked(lesson)
        let record = store.record(for: lesson)
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                IconBadge(icon: lesson.kind.icon, color: unlocked ? color : Theme.textSecondary, size: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.kind.title)
                        .font(.rounded(22, .heavy))
                        .foregroundColor(Theme.textPrimary)
                    if let unit {
                        Text("Unit \(unit.number) · \(unit.emoji) \(unit.title)")
                            .font(.rounded(14, .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            Text(lesson.kind.subtitle)
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let record {
                HStack(spacing: 14) {
                    HStack(spacing: 3) {
                        ForEach(1...3, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .foregroundColor(i <= record.stars ? Theme.gold : Theme.cardRaised)
                        }
                    }
                    Text("Tốt nhất \(Int(record.best * 100))% · đã học \(record.count) lần")
                        .font(.rounded(13, .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            }

            if lesson.kind == .test && unlocked && !store.isUnitPassed(lesson.unitId) && store.completedCount(in: lesson.unitId) < 6 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "bolt.fill").foregroundColor(Theme.warning)
                    Text("Đã biết nội dung unit này? Đạt từ 80% ở bài kiểm tra để vượt unit ngay!")
                        .font(.rounded(13, .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.warning.opacity(0.12)))
            }

            Spacer(minLength: 0)

            if unlocked {
                Button(action: onStart) {
                    HStack {
                        Text(record == nil ? "Bắt đầu" : "Luyện lại")
                        Text("+\(lesson.kind.baseXP)+ XP").opacity(0.8)
                    }
                }
                .buttonStyle(BigButtonStyle(color: color))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(store.isUnitReachable(unit?.index ?? 0) ? "Hoàn thành bài trước để mở khóa" : "Vượt qua bài kiểm tra unit trước để mở khóa")
                }
                .font(.rounded(15, .bold))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.cardRaised))
            }
        }
        .padding(22)
        .background(Theme.background.ignoresSafeArea())
    }
}

/// Word list of a unit with mastery and a practice button.
struct UnitWordsView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    let unit: Unit
    @State private var selected: Word?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            router.start(.words(unit.words.map(\.id), title: "Luyện từ Unit \(unit.number)"))
                        }
                    } label: {
                        Label("Luyện tập 12 từ này", systemImage: "play.fill")
                    }
                    .buttonStyle(BigButtonStyle())

                    VStack(spacing: 0) {
                        ForEach(unit.words) { word in
                            Button {
                                selected = word
                            } label: {
                                WordRow(word: word, mastery: store.mastery(of: word))
                            }
                            .buttonStyle(.plain)
                            if word.id != unit.words.last?.id { Divider().padding(.leading, 16) }
                        }
                    }
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    SectionHeader(title: "Mẫu câu giao tiếp")
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(unit.phrases) { phrase in
                            ExampleRow(en: phrase.en, vi: phrase.vi)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
                .padding(18)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("\(unit.emoji) \(unit.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
            .sheet(item: $selected) { word in
                WordDetailSheet(word: word)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

struct WordRow: View {
    let word: Word
    let mastery: MasteryLevel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(word.word)
                        .font(.rounded(17, .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(word.ipa)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.accent.opacity(0.8))
                        .lineLimit(1)
                }
                Text(word.vi)
                    .font(.rounded(13, .medium))
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

/// CEFR description of a level.
struct LevelDetailView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss
    let level: Level

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Text(level.emoji).font(.system(size: 50))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(level.id) · \(level.name)")
                                .font(.rounded(26, .heavy))
                                .foregroundColor(Theme.textPrimary)
                            Text("\(level.nameEn) · \(level.hours) học")
                                .font(.rounded(14, .semibold))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    Text(level.description)
                        .font(.rounded(16, .medium))
                        .foregroundColor(Theme.textPrimary)
                        .card()

                    if let canDo = level.canDo {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("SAU CẤP ĐỘ NÀY BẠN CÓ THỂ", systemImage: "checkmark.seal.fill")
                                .font(.rounded(12, .heavy))
                                .foregroundColor(Theme.levelColor(level))
                            ForEach(canDo, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                                    Text(item)
                                        .font(.rounded(15, .medium))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("\(level.units.count) UNIT", systemImage: "square.stack.3d.up.fill")
                            .font(.rounded(12, .heavy))
                            .foregroundColor(Theme.levelColor(level))
                        ForEach(level.units) { unit in
                            HStack(spacing: 10) {
                                Text(unit.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unit \(unit.number): \(unit.title)")
                                        .font(.rounded(15, .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(unit.grammar.title)
                                        .font(.rounded(12, .medium))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                if store.isUnitPassed(unit.id) {
                                    Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
                .padding(18)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}
