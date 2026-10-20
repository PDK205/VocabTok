import SwiftUI

enum ExerciseKind {
    case intro       // present a new word
    case meaning     // English word -> pick Vietnamese meaning
    case reverse     // Vietnamese meaning -> pick English word
    case listen      // hear the word -> pick English word
    case fillBlank   // complete the example sentence
    case spell       // arrange letter tiles

    var title: String {
        switch self {
        case .intro: return "Từ mới"
        case .meaning: return "Chọn nghĩa đúng"
        case .reverse: return "Chọn từ tiếng Anh"
        case .listen: return "Nghe và chọn từ"
        case .fillBlank: return "Điền vào chỗ trống"
        case .spell: return "Ghép chữ thành từ"
        }
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let word: Word
    let kind: ExerciseKind
    var options: [String] = []
    var tiles: [Character] = []

    var answer: String {
        kind == .meaning ? word.vi : word.word.lowercased()
    }
}

enum LessonMode: Equatable {
    case daily                // due reviews + new words
    case review               // due reviews only
    case topic(String)        // new words from a topic + its due reviews
}

enum AnswerState {
    case answering, correct, wrong
}

final class LessonViewModel: ObservableObject {
    @Published private(set) var steps: [Exercise] = []
    @Published private(set) var index = 0
    @Published private(set) var state: AnswerState = .answering
    @Published private(set) var selected: String?
    @Published private(set) var combo = 0
    @Published private(set) var maxCombo = 0
    @Published private(set) var xp = 0
    @Published private(set) var finished = false
    @Published private(set) var lastXPGain = 0

    private(set) var correctCount = 0
    private(set) var answeredCount = 0
    private(set) var newWordIds: [String] = []
    private(set) var lessonWords: [Word] = []
    private var mistakes: Set<String> = []
    private let startedAt = Date()
    private let store: ProgressStore
    private let bank = WordBank.shared

    init(mode: LessonMode, store: ProgressStore) {
        self.store = store
        build(mode: mode)
    }

    var current: Exercise? { index < steps.count ? steps[index] : nil }

    /// Fraction of steps done, for the top progress bar.
    var progress: Double {
        steps.isEmpty ? 0 : Double(index + (state == .answering ? 0 : 1)) / Double(steps.count)
    }

    var accuracy: Double { answeredCount == 0 ? 1 : Double(correctCount) / Double(answeredCount) }
    private(set) var duration: TimeInterval = 0
    var perfectWords: [Word] { lessonWords.filter { !mistakes.contains($0.id) } }
    var mistakeWords: [Word] { lessonWords.filter { mistakes.contains($0.id) } }

    // MARK: - Building

    private func build(mode: LessonMode) {
        let newPerLesson = UserDefaults.standard.object(forKey: "newPerLesson") as? Int ?? 5
        var reviews: [Word]
        var fresh: [Word]

        switch mode {
        case .daily:
            reviews = Array(store.dueWords.prefix(10))
            fresh = Array(store.newWords().prefix(newPerLesson))
        case .review:
            reviews = Array(store.dueWords.prefix(15))
            fresh = []
        case .topic(let id):
            reviews = Array(store.dueWords.filter { $0.topic == id }.prefix(8))
            fresh = Array(store.newWords(in: id).prefix(newPerLesson))
        }

        // Nothing scheduled: practise words already learned so the user can always play.
        if reviews.isEmpty && fresh.isEmpty {
            var learned = bank.words.filter { store.progress(for: $0) != nil }
            if case .topic(let id) = mode { learned = learned.filter { $0.topic == id } }
            reviews = Array(learned.shuffled().prefix(8))
        }

        newWordIds = fresh.map(\.id)
        lessonWords = fresh + reviews

        var result: [Exercise] = []
        // Stage 1: introduce new words in pairs, each followed by a quick recognition check.
        var i = 0
        while i < fresh.count {
            let pair = Array(fresh[i..<min(i + 2, fresh.count)])
            result += pair.map { make(.intro, for: $0) }
            result += pair.shuffled().map { make(.meaning, for: $0) }
            i += 2
        }

        // Stage 2: harder recall for new words, mixed with reviews.
        var mixed: [Exercise] = fresh.map { make([ExerciseKind.listen, .fillBlank, .reverse, .spell].randomElement() ?? .reverse, for: $0) }
        mixed += reviews.map { (word: Word) -> Exercise in
            let box = store.progress(for: word)?.box ?? 0
            let kinds: [ExerciseKind]
            switch box {
            case 0...1: kinds = [.meaning, .listen, .reverse]
            case 2...3: kinds = [.reverse, .fillBlank, .listen, .spell]
            default: kinds = [.spell, .fillBlank, .reverse]
            }
            return make(kinds.randomElement() ?? .meaning, for: word)
        }
        result += spreadOut(mixed.shuffled())
        steps = result

        if let first = steps.first { autoSpeak(first) }
    }

    /// Avoid the same word appearing twice in a row.
    private func spreadOut(_ list: [Exercise]) -> [Exercise] {
        var items = list
        for j in 1..<max(items.count, 1) where items[j].word.id == items[j - 1].word.id {
            if let swap = items.indices.first(where: { $0 > j && items[$0].word.id != items[j - 1].word.id }) {
                items.swapAt(j, swap)
            }
        }
        return items
    }

    private func make(_ kind: ExerciseKind, for word: Word) -> Exercise {
        var kind = kind
        if kind == .fillBlank && word.blankedExample == nil { kind = .reverse }
        var ex = Exercise(word: word, kind: kind)
        switch kind {
        case .intro:
            break
        case .meaning:
            ex.options = options(for: word, value: \.vi)
        case .reverse, .listen, .fillBlank:
            ex.options = options(for: word, value: { $0.word.lowercased() })
        case .spell:
            let letters = Array(word.word.lowercased())
            var shuffled = letters.shuffled()
            var attempts = 0
            while shuffled == letters && letters.count > 1 && attempts < 10 {
                shuffled.shuffle()
                attempts += 1
            }
            ex.tiles = shuffled
        }
        return ex
    }

    /// Correct answer plus three distractors, preferring the same part of speech.
    private func options(for word: Word, value: (Word) -> String) -> [String] {
        let correct = value(word)
        let others = bank.words.filter { $0.id != word.id && value($0) != correct }
        let samePos = others.filter { $0.pos == word.pos }.shuffled()
        let rest = others.filter { $0.pos != word.pos }.shuffled()
        var picks: [String] = []
        for candidate in (samePos + rest).map(value) where !picks.contains(candidate) {
            picks.append(candidate)
            if picks.count == 3 { break }
        }
        return (picks + [correct]).shuffled()
    }

    // MARK: - Answering

    func submit(_ answer: String) {
        guard state == .answering, let ex = current else { return }
        selected = answer
        answeredCount += 1
        let isCorrect = answer.lowercased() == ex.answer.lowercased()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if isCorrect {
                correctCount += 1
                combo += 1
                maxCombo = max(maxCombo, combo)
                lastXPGain = 10 + min(combo - 1, 5) * 2
                xp += lastXPGain
                state = .correct
            } else {
                combo = 0
                lastXPGain = 0
                mistakes.insert(ex.word.id)
                state = .wrong
                // Retry the same word a little later in the lesson.
                let retry = make(ex.kind, for: ex.word)
                let position = min(index + 3, steps.count)
                steps.insert(retry, at: position)
            }
        }

        if isCorrect {
            Haptics.success()
            SpeechManager.shared.speak(ex.word.word)
        } else {
            Haptics.error()
        }
    }

    /// Introduction cards are not graded.
    func acknowledgeIntro() {
        xp += 2
        advance()
    }

    func advance() {
        Haptics.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selected = nil
            state = .answering
            if index + 1 < steps.count {
                index += 1
            } else {
                finish()
            }
        }
        if !finished, let ex = current { autoSpeak(ex) }
    }

    private func autoSpeak(_ ex: Exercise) {
        let autoPlay = UserDefaults.standard.object(forKey: "autoPlay") as? Bool ?? true
        guard autoPlay || ex.kind == .listen else { return }
        guard ex.kind == .intro || ex.kind == .listen || ex.kind == .meaning else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            SpeechManager.shared.speak(ex.word.word)
        }
    }

    private func finish() {
        duration = Date().timeIntervalSince(startedAt)
        xp += 15
        if mistakes.isEmpty && answeredCount > 0 { xp += 10 }
        var results: [String: Bool] = [:]
        for w in lessonWords { results[w.id] = !mistakes.contains(w.id) }
        store.apply(.init(results: results, xp: xp, correct: correctCount, total: answeredCount))
        finished = true
        Haptics.celebrate()
    }
}
