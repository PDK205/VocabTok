import Foundation
import SwiftUI

/// Everything the user has achieved, persisted to UserDefaults as JSON.
struct UserData: Codable {
    var progress: [String: WordProgress] = [:]
    var totalXP: Int = 0
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastActiveDay: Date?
    /// XP earned per day, keyed by "yyyy-MM-dd".
    var xpByDay: [String: Int] = [:]
    var lessonsCompleted: Int = 0
    var answersCorrect: Int = 0
    var answersTotal: Int = 0
}

final class ProgressStore: ObservableObject {
    @Published private(set) var data: UserData

    private let key = "vocabtok.userdata.v2"
    private let bank = WordBank.shared

    init() {
        if let raw = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserData.self, from: raw) {
            data = decoded
        } else {
            data = UserData()
        }
        refreshStreak()
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: key)
        }
    }

    // MARK: - Queries

    func progress(for word: Word) -> WordProgress? { data.progress[word.id] }

    func mastery(of word: Word) -> MasteryLevel { MasteryLevel(progress: data.progress[word.id]) }

    var dueWords: [Word] {
        bank.words
            .filter { data.progress[$0.id]?.isDue == true }
            .sorted { (data.progress[$0.id]?.due ?? .distantPast) < (data.progress[$1.id]?.due ?? .distantPast) }
    }

    func newWords(in topicId: String? = nil) -> [Word] {
        bank.words.filter { data.progress[$0.id] == nil && (topicId == nil || $0.topic == topicId) }
    }

    var learnedCount: Int { data.progress.count }
    var masteredCount: Int { data.progress.values.filter(\.isMastered).count }

    func learnedCount(in topicId: String) -> Int {
        bank.words(in: topicId).filter { data.progress[$0.id] != nil }.count
    }

    func masteredRatio(in topicId: String) -> Double {
        let words = bank.words(in: topicId)
        guard !words.isEmpty else { return 0 }
        let score = words.reduce(0.0) { acc, w in
            acc + Double(min(data.progress[w.id]?.box ?? 0, WordProgress.masteredBox)) / Double(WordProgress.masteredBox)
        }
        return score / Double(words.count)
    }

    var accuracy: Double {
        data.answersTotal == 0 ? 0 : Double(data.answersCorrect) / Double(data.answersTotal)
    }

    var todayXP: Int { data.xpByDay[Self.dayKey(Date())] ?? 0 }

    /// XP for the last 7 days, oldest first.
    var weekXP: [(label: String, xp: Int, isToday: Bool)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let label = offset == 0 ? "Nay" : formatter.string(from: day)
            return (label, data.xpByDay[Self.dayKey(day)] ?? 0, offset == 0)
        }
    }

    var level: Int { Self.level(for: data.totalXP).level }
    var levelProgress: Double { Self.level(for: data.totalXP).progress }
    var xpToNextLevel: Int { Self.level(for: data.totalXP).remaining }

    /// Level n needs n * 100 XP to complete.
    static func level(for xp: Int) -> (level: Int, progress: Double, remaining: Int) {
        var level = 1
        var remaining = xp
        while remaining >= level * 100 {
            remaining -= level * 100
            level += 1
        }
        return (level, Double(remaining) / Double(level * 100), level * 100 - remaining)
    }

    var isStreakActiveToday: Bool {
        guard let last = data.lastActiveDay else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Mutations

    struct LessonOutcome {
        var results: [String: Bool]   // word id -> answered perfectly
        var xp: Int
        var correct: Int
        var total: Int
    }

    func apply(_ outcome: LessonOutcome) {
        let now = Date()
        for (id, perfect) in outcome.results {
            var p = data.progress[id] ?? WordProgress()
            p.record(perfect: perfect, now: now)
            data.progress[id] = p
        }
        data.totalXP += outcome.xp
        data.xpByDay[Self.dayKey(now), default: 0] += outcome.xp
        data.lessonsCompleted += 1
        data.answersCorrect += outcome.correct
        data.answersTotal += outcome.total
        bumpStreak(now: now)
        save()
    }

    func resetAll() {
        data = UserData()
        save()
    }

    private func bumpStreak(now: Date) {
        let cal = Calendar.current
        if let last = data.lastActiveDay {
            if cal.isDate(last, inSameDayAs: now) {
                // already counted today
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: now), cal.isDate(last, inSameDayAs: yesterday) {
                data.streak += 1
            } else {
                data.streak = 1
            }
        } else {
            data.streak = 1
        }
        data.lastActiveDay = now
        data.bestStreak = max(data.bestStreak, data.streak)
    }

    /// A streak breaks if the user skipped a full day.
    private func refreshStreak() {
        guard let last = data.lastActiveDay else { return }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
        if days > 1 {
            data.streak = 0
            save()
        }
    }

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
