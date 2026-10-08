import SwiftUI

struct QuizResultView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        ZStack {
            Color(hex: "12141D").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if viewModel.wrongWords.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("XUẤT SẮC! ĐÚNG 100%")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Bạn đã nhớ hoàn toàn các từ này. Tiếp tục lướt để học bộ từ mới!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Button("Lướt tiếp từ mới ->") {
                        viewModel.loadNextBatch()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(14)
                    .padding(.horizontal, 30)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.orange)

                    Text("Bạn chưa đúng hết!")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Có \(viewModel.wrongWords.count) từ bạn làm sai. Bạn cần ôn lại và làm đúng hết thì mới được lướt tiếp.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.wrongWords) { w in
                                HStack {
                                    Text(w.word).bold().foregroundColor(.white)
                                    Spacer()
                                    Text(w.meaningVi).foregroundColor(.yellow)
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200)

                    Button("Bắt đầu ôn tập từ sai") {
                        viewModel.startReviewingMistakes()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(14)
                    .padding(.horizontal, 30)
                }

                Spacer()
            }
        }
    }
}

struct ReviewWrongWordsView: View {
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        ZStack {
            Color(hex: "0D0E15").ignoresSafeArea()

            if viewModel.reviewIndex < viewModel.wrongWords.count {
                let word = viewModel.wrongWords[viewModel.reviewIndex]

                VStack(spacing: 20) {
                    HStack {
                        Text("Ôn từ sai (\(viewModel.reviewIndex + 1)/\(viewModel.wrongWords.count))")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)

                    Spacer()

                    VStack(spacing: 10) {
                        Text(word.word)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        Text(word.phonetic)
                            .font(.title3)
                            .foregroundColor(.cyan)

                        Button(action: {
                            viewModel.speakReviewWord()
                        }) {
                            Label("Nghe lại", systemImage: "speaker.wave.3.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nghĩa: \(word.meaningVi)")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Text("Ví dụ: \(word.exampleEn)")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.white)
                        Text("-> \(word.exampleVi)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                    Spacer()

                    HStack(spacing: 20) {
                        if viewModel.reviewIndex > 0 {
                            Button("Từ trước") {
                                viewModel.reviewIndex -= 1
                                viewModel.speakReviewWord()
                            }
                            .foregroundColor(.white)
                        }

                        Spacer()

                        if viewModel.reviewIndex < viewModel.wrongWords.count - 1 {
                            Button("Từ tiếp theo") {
                                viewModel.reviewIndex += 1
                                viewModel.speakReviewWord()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Kiểm tra lại câu sai") {
                                viewModel.startRetest()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}