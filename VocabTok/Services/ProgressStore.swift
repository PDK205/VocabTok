import Foundation
import SwiftUI

/// What a finished study session reports back.
struct SessionResult {
    var lesson: Lesson?
    var wordResults: [String: Bool] = [:]
    var xp = 0
    var correct = 0
    var total = 0
    var speaking = 0
    var maxCombo = 0
    var seconds = 0
    var reviewed = 0
}

/// What the app shows on the completion screen.
struct SessionOutcome {
    var xp = 0
    var stars = 0
    var accuracy: Double = 1
    var passed = true
    var unitCompleted = false
    var streakExtended = false
    var streak = 0
    var leveledUp = false
    var newLevel = 1
    var newAchievements: [Achievement] = []
}

final class ProgressStore: ObservableObject {
    @Published private(set) var data: UserData

    private let key = "vocabtok.userdata.v3"
    private let content = ContentStore.shared

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

    var dailyGoal: Int { UserDefaults.standard.object(forKey: "dailyGoal") as? Int ?? 50 }

    // MARK: - Onboarding

    func completeOnboarding(name: String, reason: String) {
        data.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        data.goalReason = reason
        data.onboarded = true
        save()
    }

    func setStartLevel(_ levelIndex: Int) {
        let clamped = max(0, min(levelIndex, content.levels.count - 1))
        data.startUnitIndex = content.firstUnitIndex(ofLevel: clamped)
        data.placementLevel = content.levels.indices.contains(clamped) ? content.levels[clamped].id : nil
        save()
    }

    func rename(_ name: String) {
        data.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    // MARK: - Words

    func progress(for word: Word) -> WordProgress? { data.progress[word.id] }
    func mastery(of word: Word) -> MasteryLevel { MasteryLevel(progress: data.progress[word.id]) }

    var learnedCount: Int { data.progress.count }
    var masteredCount: Int { data.progress.values.filter(\.isMastered).count }

    var learnedWords: [Word] {
        content.allWords.filter { data.progress[$0.id] != nil }
    }

    var dueWords: [Word] {
        content.allWords
            .filter { data.progress[$0.id]?.isDue == true }
            .sorted { (data.progress[$0.id]?.due ?? .distantPast) < (data.progress[$1.id]?.due ?? .distantPast) }
    }

    /// Words the learner gets wrong most often.
    var difficultWords: [Word] {
        content.allWords
            .compactMap { word -> (Word, Double)? in
                guard let p = data.progress[word.id], p.wrong > 0 else { return nil }
                let ratio = Double(p.wrong) / Double(p.wrong + p.correct)
                return (word, ratio + Double(5 - min(p.box, 5)) * 0.05)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    func masteryCounts() -> [MasteryLevel: Int] {
        var counts: [MasteryLevel: Int] = [.new: 0, .learning: 0, .familiar: 0, .mastered: 0]
        for word in content.allWords {
            counts[mastery(of: word), default: 0] += 1
        }
        return counts
    }

    func isSaved(_ word: Word) -> Bool { data.savedWords.contains(word.id) }

    func toggleSaved(_ word: Word) {
        if data.savedWords.contains(word.id) {
            data.savedWords.remove(word.id)
        } else {
            data.savedWords.insert(word.id)
        }
        save()
    }

    var savedWords: [Word] { content.allWords.filter { data.savedWords.contains($0.id) } }

    // MARK: - Lessons & unlocking

    func record(for lesson: Lesson) -> LessonRecord? { data.lessonRecords[lesson.id] }
    func isCompleted(_ lesson: Lesson) -> Bool { data.lessonRecords[lesson.id] != nil }
    func stars(for lesson: Lesson) -> Int { data.lessonRecords[lesson.id]?.stars ?? 0 }

    func isUnitPassed(_ unitId: String) -> Bool {
        data.lessonRecords["\(unitId)-\(LessonKind.test.rawValue)"] != nil
    }

    var passedUnitCount: Int { content.units.filter { isUnitPassed($0.id) }.count }

    func isLevelCompleted(_ levelId: String) -> Bool {
        guard let level = content.level(id: levelId), !level.units.isEmpty else { return false }
        return level.units.allSatisfy { isUnitPassed($0.id) }
    }

    func isUnitReachable(_ unitIndex: Int) -> Bool {
        if unitIndex <= data.startUnitIndex { return true }
        guard content.units.indices.contains(unitIndex - 1) else { return false }
        return isUnitPassed(content.units[unitIndex - 1].id)
    }

    func isUnlocked(_ lesson: Lesson) -> Bool {
        guard let unit = content.unit(id: lesson.unitId) else { return false }
        guard isUnitReachable(unit.index) else { return false }
        if unit.index < data.startUnitIndex || isUnitPassed(unit.id) { return true }
        // The unit test is always open so learners can test out of a unit they already know.
        if lesson.kind == .test { return true }
        guard let position = LessonKind.allCases.firstIndex(of: lesson.kind), position > 0 else { return true }
        let previous = Lesson(unitId: lesson.unitId, kind: LessonKind.allCases[position - 1], order: lesson.order - 1)
        return isCompleted(previous)
    }

    /// The next lesson the learner should do.
    var currentLesson: Lesson? {
        content.lessons.first { lesson in
            guard let unit = content.unit(id: lesson.unitId), unit.index >= data.startUnitIndex else { return false }
            return !isCompleted(lesson) && isUnlocked(lesson)
        }
    }

    func completedCount(in unitId: String) -> Int {
        content.lessons(in: unitId).filter { isCompleted($0) }.count
    }

    var currentUnit: Unit? {
        if let lesson = currentLesson { return content.unit(id: lesson.unitId) }
        return content.units.last
    }

    var currentLevel: Level? {
        guard let unit = currentUnit else { return content.levels.first }
        return content.level(of: unit)
    }

    func levelProgress(_ level: Level) -> Double {
        guard !level.units.isEmpty else { return 0 }
        return Double(level.units.filter { isUnitPassed($0.id) }.count) / Double(level.units.count)
    }

    // MARK: - Stats

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    var today: DayStats { data.days[ProgressStore.dayKey(Date())] ?? DayStats() }
    var todayXP: Int { today.xp }

    var accuracy: Double {
        data.answersTotal == 0 ? 0 : Double(data.answersCorrect) / Double(data.answersTotal)
    }

    /// XP for the last 7 days, oldest first.
    var weekXP: [(label: String, xp: Int, isToday: Bool)] {
        let cal = Calendar.current
        let names = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let weekday = cal.component(.weekday, from: day)
            let label = offset == 0 ? "Nay" : names[(weekday - 1) % 7]
            return (label, data.days[ProgressStore.dayKey(day)]?.xp ?? 0, offset == 0)
        }
    }

    /// Whether the learner studied on each of the last 7 days.
    var weekActivity: [(label: String, active: Bool, isToday: Bool)] {
        weekXP.map { ($0.label, $0.xp > 0, $0.isToday) }
    }

    static func xpLevel(for xp: Int) -> (level: Int, progress: Double, remaining: Int) {
        var level = 1
        var remaining = xp
        var need = 150
        while remaining >= need {
            remaining -= need
            level += 1
            need = 150 + (level - 1) * 75
        }
        return (level, Double(remaining) / Double(need), need - remaining)
    }

    var xpLevel: Int { ProgressStore.xpLevel(for: data.totalXP).level }
    var xpLevelProgress: Double { ProgressStore.xpLevel(for: data.totalXP).progress }
    var xpToNextLevel: Int { ProgressStore.xpLevel(for: data.totalXP).remaining }

    var isStreakActiveToday: Bool {
        guard let last = data.lastActiveDay else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Quests

    var todayQuests: [DailyQuest] { QuestBook.quests(for: Date(), dailyGoal: dailyGoal) }
    var allQuestsDone: Bool { todayQuests.allSatisfy { $0.isDone(in: today) } }
    var chestClaimedToday: Bool { data.chestsClaimed.contains(ProgressStore.dayKey(Date())) }

    func claimChest() {
        guard allQuestsDone, !chestClaimedToday else { return }
        data.chestsClaimed.insert(ProgressStore.dayKey(Date()))
        addXP(QuestBook.chestXP)
    }

    // MARK: - Mutations

    func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        let key = ProgressStore.dayKey(Date())
        var day = data.days[key] ?? DayStats()
        day.xp += amount
        data.days[key] = day
        data.totalXP += amount
        save()
    }

    func recordSpeedMatch(score: Int, seconds: Int) -> Int {
        data.speedMatchBest = max(data.speedMatchBest, score)
        let key = ProgressStore.dayKey(Date())
        var day = data.days[key] ?? DayStats()
        day.seconds += seconds
        day.correct += score
        data.days[key] = day
        data.secondsStudied += seconds
        let xp = score * 2
        if xp > 0 {
            _ = bumpStreak(now: Date())
        }
        addXP(xp)
        return xp
    }

    @discardableResult
    func finish(_ result: SessionResult) -> SessionOutcome {
        let now = Date()
        var outcome = SessionOutcome()
        let levelBefore = xpLevel
        let earnedBefore = Set(data.achievements.keys)

        outcome.accuracy = result.total == 0 ? 1 : Double(result.correct) / Double(result.total)
        outcome.stars = outcome.accuracy >= 0.95 ? 3 : (outcome.accuracy >= 0.8 ? 2 : 1)
        let isTest = result.lesson?.kind == .test
        outcome.passed = !isTest || outcome.accuracy >= 0.8

        var xp = result.xp
        if isTest && outcome.passed { xp += 30 }
        let perfect = result.total > 0 && result.correct == result.total
        if perfect { xp += 10 }
        outcome.xp = xp

        // Spaced repetition.
        var newWords = 0
        for (id, ok) in result.wordResults {
            var p = data.progress[id] ?? WordProgress()
            if data.progress[id] == nil { newWords += 1 }
            p.record(perfect: ok, now: now)
            data.progress[id] = p
        }

        // Path progress.
        if let lesson = result.lesson, outcome.passed {
            let wasPassed = isUnitPassed(lesson.unitId)
            var record = data.lessonRecords[lesson.id] ?? LessonRecord(stars: 0, best: 0, count: 0, date: now)
            record.stars = max(record.stars, outcome.stars)
            record.best = max(record.best, outcome.accuracy)
            record.count += 1
            record.date = now
            data.lessonRecords[lesson.id] = record
            outcome.unitCompleted = isTest && !wasPassed
        }

        // Daily statistics.
        let key = ProgressStore.dayKey(now)
        var day = data.days[key] ?? DayStats()
        day.xp += xp
        day.lessons += 1
        day.correct += result.correct
        day.perfect += perfect ? 1 : 0
        day.speaking += result.speaking
        day.reviewed += result.reviewed
        day.newWords += newWords
        day.seconds += result.seconds
        data.days[key] = day

        // Totals.
        data.totalXP += xp
        data.lessonsCompleted += 1
        data.perfectLessons += perfect ? 1 : 0
        data.answersCorrect += result.correct
        data.answersTotal += result.total
        data.speakingCount += result.speaking
        data.maxCombo = max(data.maxCombo, result.maxCombo)
        data.secondsStudied += result.seconds

        outcome.streakExtended = bumpStreak(now: now)
        outcome.streak = data.streak

        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 22 && data.achievements["night_owl"] == nil { data.achievements["night_owl"] = now }
        if hour < 7 && data.achievements["early_bird"] == nil { data.achievements["early_bird"] = now }

        for achievement in AchievementBook.all where data.achievements[achievement.id] == nil && achievement.isEarned(self) {
            data.achievements[achievement.id] = now
        }
        outcome.newAchievements = AchievementBook.all.filter { data.achievements[$0.id] != nil && !earnedBefore.contains($0.id) }

        outcome.newLevel = xpLevel
        outcome.leveledUp = outcome.newLevel > levelBefore
        save()
        return outcome
    }

    /// Returns true when this is the first activity of the day.
    private func bumpStreak(now: Date) -> Bool {
        let cal = Calendar.current
        var extended = false
        if let last = data.lastActiveDay {
            if cal.isDate(last, inSameDayAs: now) {
                extended = false
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: now), cal.isDate(last, inSameDayAs: yesterday) {
                data.streak += 1
                extended = true
            } else {
                data.streak = 1
                extended = true
            }
        } else {
            data.streak = 1
            extended = true
        }
        if extended && data.streak > 0 && data.streak % 7 == 0 {
            data.freezes = min(2, data.freezes + 1)
        }
        data.lastActiveDay = now
        data.bestStreak = max(data.bestStreak, data.streak)
        return extended
    }

    /// Breaks the streak after a missed day, unless a streak freeze can cover it.
    func refreshStreak() {
        guard let last = data.lastActiveDay else { return }
        let cal = Calendar.current
        let gap = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
        if gap == 2 && data.freezes > 0 {
            data.freezes -= 1
            data.lastActiveDay = cal.date(byAdding: .day, value: -1, to: Date())
            save()
        } else if gap >= 2 {
            data.streak = 0
            save()
        }
    }

    func resetAll() {
        let onboarded = data.onboarded
        let name = data.name
        data = UserData()
        data.onboarded = onboarded
        data.name = name
        save()
    }
}
