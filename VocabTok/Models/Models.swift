import Foundation

struct Topic: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let color: String
}

struct Word: Codable, Identifiable, Hashable {
    let topic: String
    let word: String
    let ipa: String
    let pos: String
    let vi: String
    let ex: String
    let exVi: String
    let tip: String?

    var id: String { word.lowercased() }

    var posLabel: String {
        switch pos {
        case "noun": return "danh từ"
        case "verb": return "động từ"
        case "adj": return "tính từ"
        case "adv": return "trạng từ"
        default: return pos
        }
    }

    /// Example sentence with the target word (or its inflected form) replaced by a blank.
    var blankedExample: String? {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\w*"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(ex.startIndex..., in: ex)
        guard regex.firstMatch(in: ex, range: range) != nil else { return nil }
        return regex.stringByReplacingMatches(in: ex, range: range, withTemplate: "_____")
    }
}

/// Spaced-repetition state of a single word (Leitner boxes).
struct WordProgress: Codable, Hashable {
    var box: Int = 0
    var due: Date = Date()
    var correct: Int = 0
    var wrong: Int = 0
    var lastSeen: Date = Date()

    /// Days to wait before the next review for each box.
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
        // Box 0 words come back after 10 minutes so they reappear in the next lesson.
        due = days == 0 ? now.addingTimeInterval(600) : Calendar.current.startOfDay(for: now).addingTimeInterval(days * 86_400)
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
