import SwiftUI

enum AnswerState {
    case answering, correct, wrong
}

final class LessonViewModel: ObservableObject {
    @Published private(set) var exercises: [Exercise]
    @Published private(set) var index = 0
    @Published private(set) var state: AnswerState = .answering
    @Published private(set) var selected: String?
    @Published private(set) var combo = 0
    @Published private(set) var lastXPGain = 0
    @Published private(set) var feedbackNote: String?
    @Published private(set) var finished = false
    @Published private(set) var outcome: SessionOutcome?

    let kind: SessionKind
    let title: String
    let subtitle: String
    let isTest: Bool
    private let trackedWords: [String]
    private let store: ProgressStore

    private(set) var xp = 0
    private(set) var maxCombo = 0
    private(set) var correctCount = 0
    private(set) var answeredCount = 0
    private(set) var speakingCount = 0
    private(set) var mistakes: Set<String> = []
    private let startedAt = Date()
    private(set) var duration: TimeInterval = 0
    /// Number of graded questions in the original plan (tests show "x / total").
    let plannedQuestions: Int

    init(kind: SessionKind, store: ProgressStore) {
        self.kind = kind
        self.store = store
        let plan = LessonEngine(store: store).plan(for: kind)
        exercises = plan.exercises
        title = plan.title
        subtitle = plan.subtitle
        isTest = plan.isTest
        trackedWords = plan.trackedWords
        plannedQuestions = plan.exercises.filter(\.isGraded).count
    }

    var current: Exercise? { exercises.indices.contains(index) ? exercises[index] : nil }
    var isEmpty: Bool { exercises.isEmpty }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(index + (state == .answering ? 0 : 1)) / Double(exercises.count)
    }

    var accuracy: Double { answeredCount == 0 ? 1 : Double(correctCount) / Double(answeredCount) }

    var lesson: Lesson? {
        if case .lesson(let lesson) = kind { return lesson }
        return nil
    }

    var trackedWordList: [Word] { trackedWords.compactMap { ContentStore.shared.word(id: $0) } }
    var mistakeWords: [Word] { trackedWordList.filter { mistakes.contains($0.id) } }

    // MARK: - Answering

    func submit(_ answer: String) {
        guard state == .answering, let ex = current else { return }
        selected = answer
        let result = ex.check(answer)
        feedbackNote = (result.correct && !result.exact) ? "Gần đúng! Chú ý chính tả: \(ex.solution)" : nil
        grade(correct: result.correct, exercise: ex)
    }

    /// Called by the match-pairs game when every pair has been found.
    func completeMatch(mistakenIds: Set<String>) {
        guard state == .answering, let ex = current else { return }
        mistakes.formUnion(mistakenIds)
        feedbackNote = mistakenIds.isEmpty ? nil : "Bạn nhầm \(mistakenIds.count) cặp – các từ này sẽ được ôn lại."
        answeredCount += 1
        correctCount += 1
        registerCorrect(exercise: ex)
    }

    func submitSpeech(passed: Bool, score: Double) {
        guard state == .answering, let ex = current else { return }
        speakingCount += 1
        feedbackNote = passed ? "Phát âm đạt \(Int(score * 100))%" : "Bạn đạt \(Int(score * 100))%. Nghe lại mẫu và thử lần sau nhé!"
        grade(correct: passed, exercise: ex)
    }

    /// Skips speaking: optionally pauses all speaking exercises for 15 minutes.
    func skipSpeaking(pauseAll: Bool) {
        guard state == .answering else { return }
        if pauseAll {
            UserDefaults.standard.set(Date().addingTimeInterval(15 * 60), forKey: "speakingPausedUntil")
            let head = Array(exercises.prefix(index + 1))
            let tail = exercises.dropFirst(index + 1).filter { !$0.isSpeaking }
            exercises = head + tail
        }
        advance()
    }

    private func grade(correct: Bool, exercise ex: Exercise) {
        answeredCount += 1
        if correct {
            correctCount += 1
            registerCorrect(exercise: ex)
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                combo = 0
                lastXPGain = 0
                state = .wrong
                if let id = ex.wordId { mistakes.insert(id) }
                if !isTest && !ex.isSpeaking {
                    let position = min(index + 3, exercises.count)
                    exercises.insert(ex.retryCopy(), at: position)
                }
            }
            Haptics.error()
            SoundFX.wrong.play()
        }
    }

    private func registerCorrect(exercise ex: Exercise) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            combo += 1
            maxCombo = max(maxCombo, combo)
            let base = isTest ? 8 : 10
            lastXPGain = base + min(max(combo - 1, 0), 5) * 2
            xp += lastXPGain
            state = .correct
        }
        Haptics.success()
        if combo > 0 && combo % 5 == 0 {
            SoundFX.combo.play()
        } else {
            SoundFX.correct.play()
        }
        if let audio = ex.audio, !ex.isSpeaking {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                SpeechManager.shared.speak(audio)
            }
        }
    }

    /// For ungraded cards (new word, grammar notes, dialogue, reading).
    func acknowledge() {
        if case .intro = current?.content { xp += 2 }
        advance()
    }

    func advance() {
        SpeechManager.shared.stop()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            selected = nil
            feedbackNote = nil
            state = .answering
            if index + 1 < exercises.count {
                index += 1
            } else {
                finish()
            }
        }
        if !finished { autoSpeakCurrent() }
    }

    func autoSpeakCurrent() {
        guard let ex = current else { return }
        let autoPlay = UserDefaults.standard.object(forKey: "autoPlay") as? Bool ?? true
        var text: String?
        var required = false
        switch ex.content {
        case .intro(let w): text = w.word
        case .choice(let d):
            switch d.prompt {
            case .word(let w): text = w.word
            case .audio(let a): text = a; required = true
            default: break
            }
        case .type(let d): text = d.audio; required = true
        case .speak(let d): text = d.text
        case .build(let d): text = d.audio
        default: break
        }
        guard let speech = text, autoPlay || required else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            SpeechManager.shared.speak(speech)
        }
    }

    private func finish() {
        duration = Date().timeIntervalSince(startedAt)
        if answeredCount == 0 && !exercises.contains(where: { !$0.isGraded }) {
            finished = true
            return
        }
        var result = SessionResult()
        result.lesson = lesson
        for id in trackedWords { result.wordResults[id] = !mistakes.contains(id) }
        result.xp = xp + 15
        result.correct = correctCount
        result.total = answeredCount
        result.speaking = speakingCount
        result.maxCombo = maxCombo
        result.seconds = Int(duration)
        if case .lesson = kind {} else { result.reviewed = trackedWords.count }
        if let lesson, lesson.kind == .vocab1 || lesson.kind == .vocab2 { result.reviewed = 0 }
        outcome = store.finish(result)
        finished = true
        Haptics.celebrate()
        SoundFX.complete.play()
    }
}
