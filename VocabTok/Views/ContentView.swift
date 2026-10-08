import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LearningViewModel()

    var body: some View {
        ZStack {
            switch viewModel.currentState {
            case .learningBatch:
                GeometryReader { proxy in
                    let height = proxy.size.height

                    ZStack {
                        ForEach(0..<viewModel.currentBatch.count, id: \.self) { idx in
                            if abs(viewModel.currentIndex - idx) <= 1 {
                                WordCardView(
                                    word: viewModel.currentBatch[idx],
                                    index: idx,
                                    total: viewModel.currentBatch.count,
                                    onPlayNormal: { viewModel.speakCurrentWord() },
                                    onPlaySlow: { viewModel.speakCurrentWord(slow: true) },
                                    onPlaySentence: { viewModel.speakCurrentSentence() }
                                )
                                .offset(y: CGFloat(idx - viewModel.currentIndex) * height)
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height < -60 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.nextCard()
                                    }
                                } else if value.translation.height > 60 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.prevCard()
                                    }
                                }
                            }
                    )
                }
                .ignoresSafeArea()

            case .quiz:
                QuizView(viewModel: viewModel, isRetest: false)

            case .quizResult:
                QuizResultView(viewModel: viewModel)

            case .reviewWrongWords:
                ReviewWrongWordsView(viewModel: viewModel)

            case .retestWrongWords:
                QuizView(viewModel: viewModel, isRetest: true)
            }
        }
    }
}