import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: LearningViewModel
    @State private var currentQuestionIndex: Int = 0
    let isRetest: Bool

    var body: some View {
        ZStack {
            Color(hex: "12141D").ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(isRetest ? "ÔN LẠI TỪ CHƯA ĐẠT" : "KIỂM TRA 10 CÂU")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("🔒 Khóa xem lại - Chọn câu trả lời chính xác")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(currentQuestionIndex + 1)/\(viewModel.quizQuestions.count)")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)

                ProgressView(value: Double(currentQuestionIndex + 1), total: Double(viewModel.quizQuestions.count))
                    .tint(.yellow)
                    .padding(.horizontal, 20)

                Spacer()

                if currentQuestionIndex < viewModel.quizQuestions.count {
                    let q = viewModel.quizQuestions[currentQuestionIndex]
                    VStack(spacing: 12) {
                        Text("Từ này có nghĩa là gì?")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text(q.word.word)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(q.word.phonetic)
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        ForEach(q.options, id: \.self) { option in
                            Button(action: {
                                viewModel.quizQuestions[currentQuestionIndex].selectedAnswer = option
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.body.bold())
                                        .foregroundColor(q.selectedAnswer == option ? .black : .white)
                                    Spacer()
                                    if q.selectedAnswer == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding()
                                .background(q.selectedAnswer == option ? Color.yellow : Color.white.opacity(0.1))
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                HStack(spacing: 16) {
                    if currentQuestionIndex > 0 {
                        Button("Câu trước") {
                            currentQuestionIndex -= 1
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    if currentQuestionIndex < viewModel.quizQuestions.count - 1 {
                        Button("Tiếp theo") {
                            currentQuestionIndex += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .foregroundColor(.black)
                    } else {
                        Button("Nộp bài & Chấm điểm") {
                            if isRetest {
                                viewModel.submitRetest()
                            } else {
                                viewModel.submitQuiz()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}