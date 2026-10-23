import Foundation

// MARK: - Lessons on the learning path

enum LessonKind: String, CaseIterable, Codable {
    case vocab1, vocab2, grammar, dialogue, reading, speaking, test

    var title: String {
        switch self {
        case .vocab1: return "Từ vựng 1"
        case .vocab2: return "Từ vựng 2"
        case .grammar: return "Ngữ pháp"
        case .dialogue: return "Hội thoại"
        case .reading: return "Đọc hiểu"
        case .speaking: return "Luyện nói"
        case .test: return "Kiểm tra unit"
        }
    }

    var icon: String {
        switch self {
        case .vocab1: return "textformat.abc"
        case .vocab2: return "character.book.closed.fill"
        case .grammar: return "puzzlepiece.extension.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        case .reading: return "book.fill"
        case .speaking: return "mic.fill"
        case .test: return "crown.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .vocab1, .vocab2: return "Học 6 từ mới qua thẻ từ, nghe, ghép cặp, đánh vần"
        case .grammar: return "Hiểu công thức, lỗi thường gặp và luyện tập ngay"
        case .dialogue: return "Nghe hội thoại thực tế và học mẫu câu giao tiếp"
        case .reading: return "Đọc đoạn văn, chạm để tra từ và trả lời câu hỏi"
        case .speaking: return "Nói theo mẫu, app chấm điểm phát âm của bạn"
        case .test: return "Đạt từ 80% để hoàn thành unit và mở unit tiếp theo"
        }
    }

    var baseXP: Int { self == .test ? 40 : 20 }
}

struct Lesson: Identifiable, Hashable {
    let unitId: String
    let kind: LessonKind
    /// Global position on the path.
    let order: Int

    var id: String { "\(unitId)-\(kind.rawValue)" }
}

struct LessonRecord: Codable, Hashable {
    var stars: Int
    var best: Double
    var count: Int
    var date: Date
}

// MARK: - Spaced repetition

/// Leitner-box spaced-repetition state of one word.
struct WordProgress: Codable, Hashable {
    var box: Int = 0
    var due: Date = Date()
    var correct: Int = 0
    var wrong: Int = 0
    var lastSeen: Date = Date()

    /// Days to wait before the next review, per box.
    static let intervals: [Double] = [0, 1, 3, 7, 14, 30, 60]
    static let masteredBox = 5

    var isMastered: Bool { box >= WordProgress.masteredBox }
    var isDue: Bool { due <= Date() }

    mutating func record(perfect: Bool, now: Date = Date()) {
        if perfect {
            box = min(box + 1, WordProgress.intervals.count - 1)
            correct += 1
        } else {
            box = max(box - 2, 0)
            wrong += 1
        }
        lastSeen = now
        let days = WordProgress.intervals[box]
        if days == 0 {
            // Struggling words come back within the hour.
            due = now.addingTimeInterval(20 * 60)
        } else {
            due = Calendar.current.startOfDay(for: now).addingTimeInterval(days * 86_400)
        }
    }
}

enum MasteryLevel: Int, CaseIterable {
    case new, learning, familiar, mastered

    init(progress: WordProgress?) {
        guard let p = progress else { self = .new; return }
        if p.isMastered { self = .mastered }
        else if p.box >= 2 { self = .familiar }
        else { self = .learning }
    }

    var label: String {
        switch self {
        case .new: return "Chưa học"
        case .learning: return "Đang học"
        case .familiar: return "Đã quen"
        case .mastered: return "Thành thạo"
        }
    }
}

// MARK: - Daily statistics

struct DayStats: Codable, Hashable {
    var xp = 0
    var lessons = 0
    var correct = 0
    var perfect = 0
    var speaking = 0
    var reviewed = 0
    var newWords = 0
    var seconds = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        lessons = try c.decodeIfPresent(Int.self, forKey: .lessons) ?? 0
        correct = try c.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        perfect = try c.decodeIfPresent(Int.self, forKey: .perfect) ?? 0
        speaking = try c.decodeIfPresent(Int.self, forKey: .speaking) ?? 0
        reviewed = try c.decodeIfPresent(Int.self, forKey: .reviewed) ?? 0
        newWords = try c.decodeIfPresent(Int.self, forKey: .newWords) ?? 0
        seconds = try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 0
    }
}

// MARK: - Everything persisted about the learner

struct UserData: Codable {
    var onboarded = false
    var name = ""
    var goalReason = ""
    var startUnitIndex = 0
    var placementLevel: String?

    var progress: [String: WordProgress] = [:]
    var lessonRecords: [String: LessonRecord] = [:]
    var savedWords: Set<String> = []

    var totalXP = 0
    var streak = 0
    var bestStreak = 0
    var freezes = 0
    var lastActiveDay: Date?
    var days: [String: DayStats] = [:]

    var lessonsCompleted = 0
    var perfectLessons = 0
    var answersCorrect = 0
    var answersTotal = 0
    var speakingCount = 0
    var maxCombo = 0
    var secondsStudied = 0
    var speedMatchBest = 0

    var achievements: [String: Date] = [:]
    var chestsClaimed: Set<String> = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        goalReason = try c.decodeIfPresent(String.self, forKey: .goalReason) ?? ""
        startUnitIndex = try c.decodeIfPresent(Int.self, forKey: .startUnitIndex) ?? 0
        placementLevel = try c.decodeIfPresent(String.self, forKey: .placementLevel)
        progress = try c.decodeIfPresent([String: WordProgress].self, forKey: .progress) ?? [:]
        lessonRecords = try c.decodeIfPresent([String: LessonRecord].self, forKey: .lessonRecords) ?? [:]
        savedWords = try c.decodeIfPresent(Set<String>.self, forKey: .savedWords) ?? []
        totalXP = try c.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        freezes = try c.decodeIfPresent(Int.self, forKey: .freezes) ?? 0
        lastActiveDay = try c.decodeIfPresent(Date.self, forKey: .lastActiveDay)
        days = try c.decodeIfPresent([String: DayStats].self, forKey: .days) ?? [:]
        lessonsCompleted = try c.decodeIfPresent(Int.self, forKey: .lessonsCompleted) ?? 0
        perfectLessons = try c.decodeIfPresent(Int.self, forKey: .perfectLessons) ?? 0
        answersCorrect = try c.decodeIfPresent(Int.self, forKey: .answersCorrect) ?? 0
        answersTotal = try c.decodeIfPresent(Int.self, forKey: .answersTotal) ?? 0
        speakingCount = try c.decodeIfPresent(Int.self, forKey: .speakingCount) ?? 0
        maxCombo = try c.decodeIfPresent(Int.self, forKey: .maxCombo) ?? 0
        secondsStudied = try c.decodeIfPresent(Int.self, forKey: .secondsStudied) ?? 0
        speedMatchBest = try c.decodeIfPresent(Int.self, forKey: .speedMatchBest) ?? 0
        achievements = try c.decodeIfPresent([String: Date].self, forKey: .achievements) ?? [:]
        chestsClaimed = try c.decodeIfPresent(Set<String>.self, forKey: .chestsClaimed) ?? []
    }
}
