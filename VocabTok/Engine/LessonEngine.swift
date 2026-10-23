import Foundation

/// Everything that can be opened in the lesson player.
enum SessionKind: Equatable {
    case lesson(Lesson)
    case review
    case difficult
    case dictation
    case pronunciation
    case words([String], title: String)
}

struct SessionPlan {
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    /// Words whose spaced-repetition state is updated when the session ends.
    var trackedWords: [String]
    var isTest = false
}

/// Builds the exercise list for each kind of session.
struct LessonEngine {
    let store: ProgressStore
    private let content = ContentStore.shared

    static var speakingEnabled: Bool {
        let on = UserDefaults.standard.object(forKey: "speakingOn") as? Bool ?? true
        let pausedUntil = UserDefaults.standard.object(forKey: "speakingPausedUntil") as? Date ?? .distantPast
        return on && pausedUntil < Date()
    }

    func plan(for kind: SessionKind) -> SessionPlan {
        switch kind {
        case .lesson(let lesson):
            guard let unit = content.unit(id: lesson.unitId) else {
                return SessionPlan(title: "Bài học", subtitle: "", exercises: [], trackedWords: [])
            }
            switch lesson.kind {
            case .vocab1: return vocabPlan(unit: unit, words: Array(unit.words.prefix(6)), title: lesson.kind.title)
            case .vocab2: return vocabPlan(unit: unit, words: Array(unit.words.dropFirst(6)), title: lesson.kind.title)
            case .grammar: return grammarPlan(unit: unit)
            case .dialogue: return dialoguePlan(unit: unit)
            case .reading: return readingPlan(unit: unit)
            case .speaking: return speakingPlan(unit: unit)
            case .test: return testPlan(unit: unit)
            }
        case .review:
            let words = Array(store.dueWords.prefix(15))
            let list = words.isEmpty ? Array(store.learnedWords.shuffled().prefix(12)) : words
            return reviewPlan(words: list, title: "Ôn tập thông minh", subtitle: words.isEmpty ? "Luyện tự do các từ đã học" : "\(words.count) từ đến hạn ôn")
        case .difficult:
            return reviewPlan(words: Array(store.difficultWords.prefix(10)), title: "Từ hay sai", subtitle: "Củng cố những từ bạn hay nhầm", doubleUp: true)
        case .dictation:
            return dictationPlan()
        case .pronunciation:
            return pronunciationPlan()
        case .words(let ids, let title):
            let words = ids.compactMap { content.word(id: $0) }
            return reviewPlan(words: Array(words.shuffled().prefix(15)), title: title, subtitle: "\(min(words.count, 15)) từ")
        }
    }

    // MARK: - Path lessons

    private func vocabPlan(unit: Unit, words: [Word], title: String) -> SessionPlan {
        var list: [Exercise] = []
        // Stage 1: meet the words in pairs, each followed by a quick recognition check.
        var i = 0
        while i < words.count {
            let pair = Array(words[i..<min(i + 2, words.count)])
            list += pair.map(intro)
            list += pair.shuffled().map(meaningChoice)
            i += 2
        }
        // Stage 2: match pairs as a quick consolidation game.
        if words.count >= 3 {
            list.append(match(Array(words.shuffled().prefix(5))))
        }
        // Stage 3: active recall, each word with a different kind of exercise.
        var recall: [Exercise] = []
        let makers: [(Word) -> Exercise?] = [{ listenChoice($0) }, { fillBlank($0) }, { reverseChoice($0) }, { spell($0) }, { typeWord($0) }]
        let offset = Int.random(in: 0..<makers.count)
        for (n, word) in words.shuffled().enumerated() {
            let maker = makers[(n + offset) % makers.count]
            recall.append(maker(word) ?? reverseChoice(word))
        }
        if LessonEngine.speakingEnabled, let word = words.randomElement() {
            recall.append(speak(word))
        }
        if let sentenceWord = words.shuffled().first(where: { tokens(of: $0.ex).count <= 9 }),
           let b = build(en: sentenceWord.ex, vi: sentenceWord.exVi) {
            recall.append(b)
        }
        list += spreadOut(recall.shuffled())
        return SessionPlan(title: title, subtitle: "\(unit.emoji) \(unit.title)", exercises: list, trackedWords: words.map(\.id))
    }

    private func grammarPlan(unit: Unit) -> SessionPlan {
        let g = unit.grammar
        var list: [Exercise] = [Exercise(content: .grammarIntro(g), solution: "")]
        var practice = g.exercises.shuffled().map { quiz($0, context: nil) }
        for example in g.examples.shuffled().prefix(2) {
            if let b = build(en: example.en, vi: example.vi) { practice.append(b) }
        }
        if let example = g.examples.filter({ tokens(of: $0.en).count <= 8 }).randomElement() {
            practice.append(dictation(en: example.en, vi: example.vi))
        }
        list += practice.shuffled()
        return SessionPlan(title: "Ngữ pháp", subtitle: g.title, exercises: list, trackedWords: [])
    }

    private func dialoguePlan(unit: Unit) -> SessionPlan {
        let d = unit.dialogue
        var list: [Exercise] = [Exercise(content: .dialogueIntro(d), solution: "")]
        var practice: [Exercise] = d.questions.map { quiz($0, context: nil, instruction: "Trả lời câu hỏi về hội thoại") }
        let phrases = unit.phrases.shuffled()
        practice += phrases.prefix(4).map(phraseMeaning)
        practice += phrases.dropFirst(4).prefix(2).map(phraseListen)
        let shortLines = d.lines.filter { (3...10).contains(tokens(of: $0.en).count) }.shuffled()
        for line in shortLines.prefix(2) {
            if let b = build(en: line.en, vi: line.vi, audio: line.en) { practice.append(b) }
        }
        if let line = d.lines.filter({ (3...7).contains(tokens(of: $0.en).count) }).randomElement() {
            practice.append(dictation(en: line.en, vi: line.vi))
        }
        list += spreadOut(practice.shuffled())
        return SessionPlan(title: "Hội thoại", subtitle: d.title, exercises: list, trackedWords: [])
    }

    private func readingPlan(unit: Unit) -> SessionPlan {
        let r = unit.reading
        var list: [Exercise] = [Exercise(content: .readingIntro(r), solution: "")]
        var practice: [Exercise] = r.questions.map { quiz($0, context: r.text, instruction: "Đọc hiểu") }
        let inText = unit.words.filter { r.text.range(of: $0.word, options: .caseInsensitive) != nil }
        let reviewWords = (inText.isEmpty ? unit.words : inText).shuffled().prefix(3)
        practice += reviewWords.map(meaningChoice)
        let sentences = r.text.components(separatedBy: ". ").map { $0.hasSuffix(".") ? $0 : $0 + "." }
        if let sentence = sentences.filter({ (4...10).contains(tokens(of: $0).count) }).randomElement(),
           let b = build(en: sentence, vi: "Sắp xếp lại câu trong bài đọc", audio: sentence) {
            practice.append(b)
        }
        list += practice
        return SessionPlan(title: "Đọc hiểu", subtitle: r.title, exercises: list, trackedWords: [])
    }

    private func speakingPlan(unit: Unit) -> SessionPlan {
        var list: [Exercise] = []
        for word in unit.words.shuffled().prefix(4) { list.append(speak(word)) }
        for phrase in unit.phrases.shuffled().prefix(3) {
            list.append(Exercise(content: .speak(SpeakData(text: phrase.en, translation: phrase.vi, ipa: nil)),
                                 solution: phrase.en, solutionDetail: phrase.vi, audio: phrase.en))
        }
        for line in unit.dialogue.lines.filter({ tokens(of: $0.en).count <= 10 }).shuffled().prefix(2) {
            list.append(Exercise(content: .speak(SpeakData(text: line.en, translation: line.vi, ipa: nil)),
                                 solution: line.en, solutionDetail: line.vi, audio: line.en))
        }
        // When speaking is switched off, fall back to listening practice so the lesson still works.
        if !LessonEngine.speakingEnabled {
            list = unit.words.shuffled().prefix(4).map { typeWord($0) } + unit.phrases.shuffled().prefix(3).map(phraseListen)
        }
        return SessionPlan(title: "Luyện nói", subtitle: "\(unit.emoji) \(unit.title)", exercises: list, trackedWords: [])
    }

    private func testPlan(unit: Unit) -> SessionPlan {
        var list: [Exercise] = []
        let words = unit.words.shuffled()
        let makers: [(Word) -> Exercise?] = [{ meaningChoice($0) }, { reverseChoice($0) }, { listenChoice($0) }, { fillBlank($0) }, { meaningChoice($0) }]
        for (n, word) in words.prefix(5).enumerated() {
            list.append(makers[n % makers.count](word) ?? meaningChoice(word))
        }
        if let word = words.dropFirst(5).first(where: { $0.word.count <= 10 }) { list.append(spell(word)) }
        list += unit.grammar.exercises.shuffled().prefix(4).map { quiz($0, context: nil) }
        list += unit.phrases.shuffled().prefix(2).map(phraseMeaning)
        if let q = unit.dialogue.questions.randomElement() {
            let context = unit.dialogue.lines.map { "\($0.name): \($0.en)" }.joined(separator: "\n")
            list.append(quiz(q, context: context, instruction: "Hội thoại"))
        }
        if let q = unit.reading.questions.randomElement() {
            list.append(quiz(q, context: unit.reading.text, instruction: "Đọc hiểu"))
        }
        if let example = unit.grammar.examples.randomElement(), let b = build(en: example.en, vi: example.vi) {
            list.append(b)
        }
        let tested = Array(words.prefix(6)).map(\.id)
        var plan = SessionPlan(title: "Kiểm tra unit", subtitle: "\(unit.emoji) \(unit.title) · cần đạt 80%", exercises: spreadOut(list.shuffled()), trackedWords: tested)
        plan.isTest = true
        return plan
    }

    // MARK: - Practice sessions

    private func reviewPlan(words: [Word], title: String, subtitle: String, doubleUp: Bool = false) -> SessionPlan {
        guard !words.isEmpty else {
            return SessionPlan(title: title, subtitle: subtitle, exercises: [], trackedWords: [])
        }
        var list: [Exercise] = []
        if words.count >= 4 {
            list.append(match(Array(words.shuffled().prefix(5))))
        }
        var rest: [Exercise] = []
        for word in words {
            let box = store.progress(for: word)?.box ?? 0
            let makers: [(Word) -> Exercise?]
            switch box {
            case 0...1: makers = [{ meaningChoice($0) }, { listenChoice($0) }, { reverseChoice($0) }]
            case 2...3: makers = [{ reverseChoice($0) }, { fillBlank($0) }, { typeWord($0) }, { listenChoice($0) }]
            default: makers = [{ spell($0) }, { typeWord($0) }, { fillBlank($0) }]
            }
            let maker: (Word) -> Exercise? = makers.randomElement() ?? { w in meaningChoice(w) }
            rest.append(maker(word) ?? reverseChoice(word))
            if doubleUp {
                rest.append((word.word.count <= 10 ? spell(word) : typeWord(word)))
            }
        }
        list += spreadOut(rest.shuffled())
        return SessionPlan(title: title, subtitle: subtitle, exercises: list, trackedWords: words.map(\.id))
    }

    private var studiedUnits: [Unit] {
        let studied = content.units.filter { store.completedCount(in: $0.id) > 0 }
        if !studied.isEmpty { return studied }
        if let current = store.currentUnit { return [current] }
        return Array(content.units.prefix(1))
    }

    private func dictationPlan() -> SessionPlan {
        var pool: [(String, String)] = []
        for unit in studiedUnits {
            pool += unit.phrases.map { ($0.en, $0.vi) }
            pool += unit.words.map { ($0.ex, $0.exVi) }
        }
        let picks = pool.filter { (2...9).contains(tokens(of: $0.0).count) }.shuffled().prefix(10)
        return SessionPlan(title: "Nghe chép chính tả", subtitle: "Nghe câu và gõ lại chính xác",
                           exercises: picks.map { dictation(en: $0.0, vi: $0.1) }, trackedWords: [])
    }

    private func pronunciationPlan() -> SessionPlan {
        let units = studiedUnits
        let words = units.flatMap(\.words).shuffled().prefix(4)
        let phrases = units.flatMap(\.phrases).shuffled().prefix(4)
        var list: [Exercise] = words.map(speak)
        list += phrases.map {
            Exercise(content: .speak(SpeakData(text: $0.en, translation: $0.vi, ipa: nil)), solution: $0.en, solutionDetail: $0.vi, audio: $0.en)
        }
        return SessionPlan(title: "Luyện phát âm", subtitle: "Nói theo mẫu và nhận điểm ngay", exercises: list.shuffled(), trackedWords: [])
    }

    // MARK: - Exercise makers

    private func intro(_ w: Word) -> Exercise {
        Exercise(content: .intro(w), wordId: w.id, solution: w.word, audio: w.word)
    }

    private func meaningChoice(_ w: Word) -> Exercise {
        let options = distractors(for: w.vi, pool: content.allWords, value: { $0.vi }, prefer: { $0.pos == w.pos })
        let data = ChoiceData(instruction: "Chọn nghĩa đúng", prompt: .word(w), options: (options + [w.vi]).shuffled(), answer: w.vi, explanation: nil)
        return Exercise(content: .choice(data), wordId: w.id, solution: "\(w.word) – \(w.vi)", solutionDetail: w.ex, audio: w.word)
    }

    private func reverseChoice(_ w: Word) -> Exercise {
        let options = distractors(for: w.word, pool: content.allWords, value: { $0.word }, prefer: { $0.pos == w.pos })
        let data = ChoiceData(instruction: "Chọn từ tiếng Anh", prompt: .meaning(w.vi, pos: w.posLabel), options: (options + [w.word]).shuffled(), answer: w.word, explanation: nil)
        return Exercise(content: .choice(data), wordId: w.id, solution: "\(w.word) – \(w.vi)", solutionDetail: w.ex, audio: w.word)
    }

    private func listenChoice(_ w: Word) -> Exercise? {
        let options = distractors(for: w.word, pool: content.allWords, value: { $0.word }, prefer: { abs($0.word.count - w.word.count) <= 2 })
        let data = ChoiceData(instruction: "Nghe và chọn từ đúng", prompt: .audio(w.word), options: (options + [w.word]).shuffled(), answer: w.word, explanation: nil)
        return Exercise(content: .choice(data), wordId: w.id, solution: "\(w.word) – \(w.vi)", solutionDetail: w.ipa, audio: w.word)
    }

    private func fillBlank(_ w: Word) -> Exercise? {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: w.word) + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(w.ex.startIndex..., in: w.ex)
        guard regex.firstMatch(in: w.ex, range: range) != nil else { return nil }
        let blanked = regex.stringByReplacingMatches(in: w.ex, range: range, withTemplate: "_____")
        let options = distractors(for: w.word, pool: content.allWords, value: { $0.word }, prefer: { $0.pos == w.pos })
        let data = ChoiceData(instruction: "Điền từ vào chỗ trống", prompt: .sentence(blanked, hint: w.exVi), options: (options + [w.word]).shuffled(), answer: w.word, explanation: nil)
        return Exercise(content: .choice(data), wordId: w.id, solution: w.ex, solutionDetail: w.exVi, audio: w.ex)
    }

    private func spell(_ w: Word) -> Exercise {
        let letters = Array(w.word.lowercased())
        var tiles = letters.shuffled()
        var attempts = 0
        while tiles == letters && letters.count > 1 && attempts < 10 {
            tiles.shuffle()
            attempts += 1
        }
        return Exercise(content: .spell(w, tiles: tiles), wordId: w.id, solution: "\(w.word) – \(w.vi)", solutionDetail: w.ipa, audio: w.word)
    }

    private func typeWord(_ w: Word) -> Exercise {
        let data = TypeData(instruction: "Nghe và viết lại từ", audio: w.word, prompt: nil, answer: w.word, hint: w.vi)
        return Exercise(content: .type(data), wordId: w.id, solution: "\(w.word) – \(w.vi)", solutionDetail: w.ipa, audio: w.word)
    }

    private func speak(_ w: Word) -> Exercise {
        Exercise(content: .speak(SpeakData(text: w.word, translation: w.vi, ipa: w.ipa)), wordId: nil, solution: w.word, solutionDetail: w.vi, audio: w.word)
    }

    private func match(_ words: [Word]) -> Exercise {
        let pairs = words.map { MatchPair(id: $0.id, left: $0.word, right: $0.vi) }
        return Exercise(content: .match(pairs), solution: "Ghép đúng tất cả các cặp")
    }

    private func phraseMeaning(_ p: Phrase) -> Exercise {
        let options = distractors(for: p.vi, pool: content.allPhrases.map(\.phrase), value: { $0.vi }, prefer: { _ in true })
        let data = ChoiceData(instruction: "Chọn nghĩa của câu", prompt: .sentence(p.en, hint: nil), options: (options + [p.vi]).shuffled(), answer: p.vi, explanation: nil)
        return Exercise(content: .choice(data), solution: p.en, solutionDetail: p.vi, audio: p.en)
    }

    private func phraseListen(_ p: Phrase) -> Exercise {
        let options = distractors(for: p.vi, pool: content.allPhrases.map(\.phrase), value: { $0.vi }, prefer: { _ in true })
        let data = ChoiceData(instruction: "Nghe và chọn nghĩa", prompt: .audio(p.en), options: (options + [p.vi]).shuffled(), answer: p.vi, explanation: nil)
        return Exercise(content: .choice(data), solution: p.en, solutionDetail: p.vi, audio: p.en)
    }

    private func quiz(_ item: QuizItem, context: String?, instruction: String = "Chọn đáp án đúng") -> Exercise {
        let prompt: ChoiceData.Prompt = item.q.contains("___") && context == nil ? .sentence(item.q, hint: nil) : .question(item.q, context: context)
        let data = ChoiceData(instruction: instruction, prompt: prompt, options: item.options.shuffled(), answer: item.answer, explanation: item.explain)
        let filled = item.q.contains("___") ? item.q.replacingOccurrences(of: "___", with: item.answer) : item.answer
        let speakable = filled.contains("(") ? nil : filled
        return Exercise(content: .choice(data), solution: filled, solutionDetail: item.explain, audio: speakable)
    }

    private func dictation(en: String, vi: String) -> Exercise {
        let data = TypeData(instruction: "Nghe và gõ lại câu", audio: en, prompt: nil, answer: en, hint: vi)
        return Exercise(content: .type(data), solution: en, solutionDetail: vi, audio: en)
    }

    private func build(en: String, vi: String, audio: String? = nil) -> Exercise? {
        let answer = tokens(of: en)
        guard (3...12).contains(answer.count) else { return nil }
        let lowered = Set(answer.map { $0.lowercased() })
        let others = content.allPhrases.map(\.phrase.en).shuffled().prefix(6).flatMap { tokens(of: $0) }
        var extras: [String] = []
        for token in others where !lowered.contains(token.lowercased()) && !extras.contains(token) {
            extras.append(token)
            if extras.count == 2 { break }
        }
        let data = BuildData(instruction: "Sắp xếp thành câu đúng", prompt: vi, audio: audio, answerTokens: answer, tiles: (answer + extras).shuffled())
        return Exercise(content: .build(data), solution: en, solutionDetail: vi, audio: en)
    }

    // MARK: - Helpers

    /// Words of a sentence without surrounding punctuation.
    private func tokens(of sentence: String) -> [String] {
        sentence.split(separator: " ").map { token in
            String(token).trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"“”()"))
        }.filter { !$0.isEmpty }
    }

    private func distractors<T>(for correct: String, pool: [T], value: (T) -> String, prefer: (T) -> Bool, count: Int = 3) -> [String] {
        let candidates = pool.filter { value($0) != correct }
        let preferred = candidates.filter(prefer).shuffled()
        let others = candidates.filter { !prefer($0) }.shuffled()
        var picks: [String] = []
        for item in preferred + others {
            let v = value(item)
            if !picks.contains(v) && v.lowercased() != correct.lowercased() {
                picks.append(v)
            }
            if picks.count == count { break }
        }
        return picks
    }

    /// Avoid asking about the same word twice in a row.
    private func spreadOut(_ list: [Exercise]) -> [Exercise] {
        var items = list
        guard items.count > 2 else { return items }
        for j in 1..<items.count {
            guard let current = items[j].wordId, current == items[j - 1].wordId else { continue }
            if let swap = items.indices.first(where: { $0 > j && items[$0].wordId != current }) {
                items.swapAt(j, swap)
            }
        }
        return items
    }
}
