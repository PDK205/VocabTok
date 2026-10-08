import SwiftUI

enum LearningState {
    case learningBatch
    case quiz
    case quizResult
    case reviewWrongWords
    case retestWrongWords
}

class LearningViewModel: ObservableObject {
    @Published var allWordsPool: [VocabularyWord] = VocabularyBank.words.shuffled()
    @Published var currentBatch: [VocabularyWord] = []
    @Published var currentIndex: Int = 0
    @Published var currentState: LearningState = .learningBatch
    
    @Published var quizQuestions: [QuizQuestion] = []
    @Published var wrongWords: [VocabularyWord] = []
    @Published var reviewIndex: Int = 0
    @Published var totalLearnedCount: Int = 0
    
    private var poolCursor: Int = 0
    
    init() {
        loadNextBatch()
    }

    func loadNextBatch() {
        var batch: [VocabularyWord] = []
        for _ in 0..<10 {
            if poolCursor >= allWordsPool.count {
                allWordsPool.shuffle()
                poolCursor = 0
            }
            batch.append(allWordsPool[poolCursor])
            poolCursor += 1
        }
        currentBatch = batch
        currentIndex = 0
        currentState = .learningBatch
        speakCurrentWord()
    }

    func speakCurrentWord(slow: Bool = false) {
        guard currentIndex < currentBatch.count else { return }
        let word = currentBatch[currentIndex].word
        SpeechManager.shared.speak(text: word, rate: slow ? 0.25 : 0.48)
    }

    func speakCurrentSentence() {
        guard currentIndex < currentBatch.count else { return }
        let sentence = currentBatch[currentIndex].exampleEn
        SpeechManager.shared.speak(text: sentence, rate: 0.45)
    }

    func nextCard() {
        if currentIndex < 9 {
            currentIndex += 1
            speakCurrentWord()
        } else {
            startQuiz()
        }
    }

    func prevCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            speakCurrentWord()
        }
    }

    func startQuiz() {
        generateQuizQuestions(from: currentBatch)
        currentState = .quiz
    }

    private func generateQuizQuestions(from words: [VocabularyWord]) {
        let allMeanings = VocabularyBank.words.map { $0.meaningVi }
        quizQuestions = words.map { word in
            let correctAnswer = word.meaningVi
            var distractors = allMeanings.filter { $0 != correctAnswer }
            distractors.shuffle()
            var options = Array(distractors.prefix(3))
            options.append(correctAnswer)
            options.shuffle()
            return QuizQuestion(word: word, options: options, correctAnswer: correctAnswer)
        }
    }

    func submitQuiz() {
        wrongWords = quizQuestions.filter { !$0.isCorrect }.map { $0.word }
        if wrongWords.isEmpty {
            totalLearnedCount += currentBatch.count
        }
        currentState = .quizResult
    }

    func startReviewingMistakes() {
        reviewIndex = 0
        currentState = .reviewWrongWords
        speakReviewWord()
    }

    func speakReviewWord(slow: Bool = false) {
        guard reviewIndex < wrongWords.count else { return }
        SpeechManager.shared.speak(text: wrongWords[reviewIndex].word, rate: slow ? 0.25 : 0.48)
    }

    func startRetest() {
        generateQuizQuestions(from: wrongWords)
        currentState = .retestWrongWords
    }

    func submitRetest() {
        wrongWords = quizQuestions.filter { !$0.isCorrect }.map { $0.word }
        if wrongWords.isEmpty {
            totalLearnedCount += currentBatch.count
        }
        currentState = .quizResult
    }
}