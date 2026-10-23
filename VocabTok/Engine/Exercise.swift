import Foundation

struct ChoiceData {
    enum Prompt {
        case word(Word)                         // show an English word, choose its meaning
        case meaning(String, pos: String?)      // show a Vietnamese meaning, choose the English word
        case audio(String)                      // listen, choose what you heard / its meaning
        case sentence(String, hint: String?)    // a sentence with a blank
        case question(String, context: String?) // comprehension question
    }

    let instruction: String
    let prompt: Prompt
    var options: [String]
    let answer: String
    let explanation: String?
}

struct TypeData {
    let instruction: String
    let audio: String?
    let prompt: String?
    let answer: String
    let hint: String?
}

struct BuildData {
    let instruction: String
    let prompt: String
    let audio: String?
    let answerTokens: [String]
    var tiles: [String]
}

struct MatchPair: Identifiable, Hashable {
    let id: String
    let left: String
    let right: String
}

struct SpeakData {
    let text: String
    let translation: String?
    let ipa: String?
}

enum ExerciseContent {
    case intro(Word)
    case choice(ChoiceData)
    case spell(Word, tiles: [Character])
    case type(TypeData)
    case build(BuildData)
    case match([MatchPair])
    case speak(SpeakData)
    case grammarIntro(Grammar)
    case dialogueIntro(Dialogue)
    case readingIntro(Reading)
}

struct Exercise: Identifiable {
    let id = UUID()
    var content: ExerciseContent
    /// Word whose spaced-repetition record this exercise affects.
    var wordId: String?
    /// Shown in the feedback panel.
    var solution: String
    var solutionDetail: String?
    /// Spoken when the answer is revealed.
    var audio: String?

    var isGraded: Bool {
        switch content {
        case .intro, .grammarIntro, .dialogueIntro, .readingIntro: return false
        default: return true
        }
    }

    var isSpeaking: Bool {
        if case .speak = content { return true }
        return false
    }

    var title: String {
        switch content {
        case .intro: return "Từ mới"
        case .choice(let d): return d.instruction
        case .spell: return "Ghép chữ thành từ"
        case .type(let d): return d.instruction
        case .build(let d): return d.instruction
        case .match: return "Ghép cặp từ và nghĩa"
        case .speak: return "Nói câu này"
        case .grammarIntro: return "Ngữ pháp"
        case .dialogueIntro: return "Hội thoại"
        case .readingIntro: return "Bài đọc"
        }
    }

    /// Checks a typed / assembled / selected answer.
    func check(_ input: String) -> (correct: Bool, exact: Bool) {
        switch content {
        case .choice(let d):
            let ok = input == d.answer
            return (ok, ok)
        case .spell(let word, _):
            let ok = TextMatch.normalize(input) == TextMatch.normalize(word.word)
            return (ok, ok)
        case .type(let d):
            return TextMatch.isClose(input, d.answer)
        case .build(let d):
            let ok = TextMatch.normalize(input) == TextMatch.normalize(d.answerTokens.joined(separator: " "))
            return (ok, ok)
        default:
            return (true, true)
        }
    }

    /// A fresh copy (new identity, reshuffled options) used when re-asking a missed question.
    func retryCopy() -> Exercise {
        var copy = Exercise(content: content, wordId: wordId, solution: solution, solutionDetail: solutionDetail, audio: audio)
        switch content {
        case .choice(var d):
            d.options.shuffle()
            copy.content = .choice(d)
        case .spell(let w, let tiles):
            copy.content = .spell(w, tiles: tiles.shuffled())
        case .build(var d):
            d.tiles.shuffle()
            copy.content = .build(d)
        case .match(let pairs):
            copy.content = .match(pairs.shuffled())
        default:
            break
        }
        return copy
    }
}
