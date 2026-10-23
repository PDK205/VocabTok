import Foundation

// MARK: - Course content (decoded from Resources/Course/*.json)

struct Word: Codable, Identifiable, Hashable {
    let word: String
    let ipa: String
    let pos: String
    let vi: String
    let ex: String
    let exVi: String
    let tip: String?
    /// Filled in by ContentStore after decoding.
    var unitId: String = ""

    enum CodingKeys: String, CodingKey {
        case word, ipa, pos, vi, ex, exVi, tip
    }

    var id: String { word.lowercased() }

    var posLabel: String {
        switch pos {
        case "noun": return "danh từ"
        case "verb": return "động từ"
        case "adj": return "tính từ"
        case "adv": return "trạng từ"
        case "prep": return "giới từ"
        case "pron": return "đại từ"
        case "conj": return "liên từ"
        case "interj": return "thán từ"
        default: return pos
        }
    }

    /// Example sentence with the target word (or an inflected form of it) blanked out.
    var blankedExample: String? {
        let lower = word.lowercased()
        var stems = [lower]
        if lower.hasSuffix("e") { stems.append(String(lower.dropLast())) }
        if lower.hasSuffix("y") { stems.append(String(lower.dropLast()) + "i") }
        for stem in stems {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: stem) + "\\w*"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(ex.startIndex..., in: ex)
            if regex.firstMatch(in: ex, range: range) != nil {
                return regex.stringByReplacingMatches(in: ex, range: range, withTemplate: "_____")
            }
        }
        return nil
    }
}

struct Phrase: Codable, Hashable, Identifiable {
    let en: String
    let vi: String
    var id: String { en }
}

struct GrammarPoint: Codable, Hashable {
    let title: String
    let body: String
}

struct Mistake: Codable, Hashable {
    let wrong: String
    let right: String
    let note: String
}

struct QuizItem: Codable, Hashable {
    let q: String
    let options: [String]
    let answer: String
    let explain: String?
}

struct Grammar: Codable, Hashable {
    let title: String
    let summary: String
    let formulas: [String]
    let points: [GrammarPoint]
    let examples: [Phrase]
    let mistakes: [Mistake]
    let exercises: [QuizItem]
}

struct DialogueLine: Codable, Hashable {
    let speaker: String
    let name: String
    let en: String
    let vi: String
}

struct Dialogue: Codable, Hashable {
    let title: String
    let setting: String
    let lines: [DialogueLine]
    let questions: [QuizItem]
}

struct Reading: Codable, Hashable {
    let title: String
    let text: String
    let vi: String
    let questions: [QuizItem]
}

struct Unit: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let titleEn: String
    let emoji: String
    let goal: String
    var words: [Word]
    let phrases: [Phrase]
    let grammar: Grammar
    let dialogue: Dialogue
    let reading: Reading
    var levelId: String = ""
    /// Position of the unit in the whole course (0-based).
    var index: Int = 0
    /// Position inside its level (1-based, for display).
    var number: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, title, titleEn, emoji, goal, words, phrases, grammar, dialogue, reading
    }
}

struct Level: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameEn: String
    let color: String
    let emoji: String
    let hours: String
    let description: String
    let canDo: [String]?
    var units: [Unit]
    /// Position of the level (0-based).
    var index: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, name, nameEn, color, emoji, hours, description, canDo, units
    }
}

// MARK: - Reference material (Resources/Reference/*.json)

struct Tense: Codable, Identifiable, Hashable {
    let id: String
    let group: String
    let name: String
    let nameVi: String
    let affirmative: String
    let negative: String
    let question: String
    let usage: [String]
    let signals: [String]
    let examples: [Phrase]
    let note: String?
}

struct PhoneticSound: Codable, Hashable, Identifiable {
    let symbol: String
    let examples: [String]
    let tip: String
    var id: String { symbol }
}

struct PhoneticGroup: Codable, Hashable, Identifiable {
    let title: String
    let subtitle: String
    let sounds: [PhoneticSound]
    var id: String { title }
}

struct PhoneticsData: Codable {
    let intro: String
    let groups: [PhoneticGroup]
    let rules: [GrammarPoint]
}

struct IrregularVerb: Codable, Hashable, Identifiable {
    let base: String
    let past: String
    let pp: String
    let vi: String
    var id: String { base }
}

struct GuideItem: Codable, Hashable, Identifiable {
    let icon: String
    let title: String
    let subtitle: String?
    let body: String
    var id: String { title }
}

struct PlanItem: Codable, Hashable, Identifiable {
    let time: String
    let title: String
    let body: String
    var id: String { title }
}

struct Guide: Codable {
    let methods: [GuideItem]
    let howItWorks: [GuideItem]
    let dailyPlan: [PlanItem]
    let tips: [String]
}

struct PlacementItem: Codable, Hashable {
    let level: String
    let q: String
    let options: [String]
    let answer: String
}
