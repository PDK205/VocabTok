import Foundation

// MARK: - Daily quests

struct DailyQuest: Identifiable, Hashable {
    enum Kind: String { case xp, lessons, correct, perfect, speaking, review, minutes }

    let kind: Kind
    let target: Int

    var id: String { "\(kind.rawValue)-\(target)" }

    var title: String {
        switch kind {
        case .xp: return "Kiếm \(target) XP"
        case .lessons: return "Hoàn thành \(target) bài học"
        case .correct: return "Trả lời đúng \(target) câu"
        case .perfect: return "Đạt 100% trong \(target) bài"
        case .speaking: return "Luyện nói \(target) lần"
        case .review: return "Ôn tập \(target) từ"
        case .minutes: return "Học \(target) phút"
        }
    }

    var icon: String {
        switch kind {
        case .xp: return "bolt.fill"
        case .lessons: return "checkmark.seal.fill"
        case .correct: return "target"
        case .perfect: return "star.fill"
        case .speaking: return "mic.fill"
        case .review: return "arrow.triangle.2.circlepath"
        case .minutes: return "clock.fill"
        }
    }

    func progress(in stats: DayStats) -> Int {
        let value: Int
        switch kind {
        case .xp: value = stats.xp
        case .lessons: value = stats.lessons
        case .correct: value = stats.correct
        case .perfect: value = stats.perfect
        case .speaking: value = stats.speaking
        case .review: value = stats.reviewed
        case .minutes: value = stats.seconds / 60
        }
        return min(value, target)
    }

    func isDone(in stats: DayStats) -> Bool { progress(in: stats) >= target }
}

enum QuestBook {
    static let chestXP = 30

    private static let pool: [DailyQuest] = [
        DailyQuest(kind: .lessons, target: 2),
        DailyQuest(kind: .lessons, target: 3),
        DailyQuest(kind: .correct, target: 15),
        DailyQuest(kind: .correct, target: 25),
        DailyQuest(kind: .perfect, target: 1),
        DailyQuest(kind: .speaking, target: 5),
        DailyQuest(kind: .review, target: 10),
        DailyQuest(kind: .minutes, target: 10),
        DailyQuest(kind: .minutes, target: 15)
    ]

    /// Three quests per day: the XP goal plus two that rotate deterministically.
    static func quests(for date: Date, dailyGoal: Int) -> [DailyQuest] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        var picks: [DailyQuest] = [DailyQuest(kind: .xp, target: dailyGoal)]
        var index = (day * 5) % pool.count
        while picks.count < 3 {
            let candidate = pool[index % pool.count]
            if !picks.contains(where: { $0.kind == candidate.kind }) {
                picks.append(candidate)
            }
            index += 3
        }
        return picks
    }
}

// MARK: - Achievements

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let color: String
    let isEarned: (ProgressStore) -> Bool
}

enum AchievementBook {
    static let all: [Achievement] = {
        var list: [Achievement] = [
            Achievement(id: "first_lesson", title: "Khởi đầu", detail: "Hoàn thành bài học đầu tiên", icon: "flag.fill", color: "22C55E") { $0.data.lessonsCompleted >= 1 },
            Achievement(id: "streak_3", title: "Bén lửa", detail: "Chuỗi 3 ngày học liên tiếp", icon: "flame.fill", color: "FF7A1A") { $0.data.bestStreak >= 3 },
            Achievement(id: "streak_7", title: "Một tuần bền bỉ", detail: "Chuỗi 7 ngày học liên tiếp", icon: "flame.fill", color: "F97316") { $0.data.bestStreak >= 7 },
            Achievement(id: "streak_30", title: "Kiên trì", detail: "Chuỗi 30 ngày học liên tiếp", icon: "flame.circle.fill", color: "EF4444") { $0.data.bestStreak >= 30 },
            Achievement(id: "streak_100", title: "Huyền thoại", detail: "Chuỗi 100 ngày học liên tiếp", icon: "crown.fill", color: "EAB308") { $0.data.bestStreak >= 100 },
            Achievement(id: "words_50", title: "Vốn từ 50", detail: "Học 50 từ vựng", icon: "book.fill", color: "0EA5E9") { $0.learnedCount >= 50 },
            Achievement(id: "words_200", title: "Vốn từ 200", detail: "Học 200 từ vựng", icon: "books.vertical.fill", color: "3B82F6") { $0.learnedCount >= 200 },
            Achievement(id: "words_500", title: "Từ điển sống", detail: "Học 500 từ vựng", icon: "graduationcap.fill", color: "6366F1") { $0.learnedCount >= 500 },
            Achievement(id: "mastered_100", title: "Bậc thầy từ vựng", detail: "Thành thạo 100 từ", icon: "brain.head.profile", color: "8B5CF6") { $0.masteredCount >= 100 },
            Achievement(id: "perfect_1", title: "Hoàn hảo", detail: "Đạt 100% trong một bài học", icon: "star.fill", color: "EAB308") { $0.data.perfectLessons >= 1 },
            Achievement(id: "perfect_10", title: "Không tì vết", detail: "Đạt 100% trong 10 bài học", icon: "sparkles", color: "F59E0B") { $0.data.perfectLessons >= 10 },
            Achievement(id: "combo_15", title: "Combo x15", detail: "Trả lời đúng 15 câu liên tiếp", icon: "bolt.fill", color: "F43F5E") { $0.data.maxCombo >= 15 },
            Achievement(id: "speak_50", title: "Diễn giả", detail: "Luyện nói 50 lần", icon: "mic.fill", color: "EC4899") { $0.data.speakingCount >= 50 },
            Achievement(id: "unit_1", title: "Qua môn", detail: "Vượt qua bài kiểm tra unit đầu tiên", icon: "checkmark.seal.fill", color: "10B981") { $0.passedUnitCount >= 1 },
            Achievement(id: "xp_1000", title: "1.000 XP", detail: "Tích lũy 1.000 điểm kinh nghiệm", icon: "bolt.circle.fill", color: "06B6D4") { $0.data.totalXP >= 1000 },
            Achievement(id: "xp_5000", title: "5.000 XP", detail: "Tích lũy 5.000 điểm kinh nghiệm", icon: "bolt.shield.fill", color: "0891B2") { $0.data.totalXP >= 5000 },
            Achievement(id: "speed_20", title: "Tay nhanh", detail: "Ghép 20 cặp trong trò Ghép cặp tốc độ", icon: "hare.fill", color: "84CC16") { $0.data.speedMatchBest >= 20 },
            Achievement(id: "night_owl", title: "Cú đêm", detail: "Học sau 22 giờ", icon: "moon.stars.fill", color: "6366F1") { $0.data.achievements["night_owl"] != nil },
            Achievement(id: "early_bird", title: "Chim sớm", detail: "Học trước 7 giờ sáng", icon: "sunrise.fill", color: "F59E0B") { $0.data.achievements["early_bird"] != nil }
        ]
        for level in ContentStore.shared.levels {
            let id = level.id
            list.append(Achievement(id: "level_\(id)", title: "Hoàn thành \(id)", detail: "Vượt qua mọi unit cấp độ \(id) – \(level.name)", icon: "rosette", color: level.color) { store in
                store.isLevelCompleted(id)
            })
        }
        return list
    }()
}
