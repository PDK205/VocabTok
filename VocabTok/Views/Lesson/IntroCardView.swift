import SwiftUI

/// Presents a new word. The meaning is hidden at first so the learner guesses before revealing
/// (active recall is much stickier than passive reading).
struct IntroCardView: View {
    let word: Word
    let onContinue: () -> Void
    @State private var revealed = false

    private var topic: Topic? { WordBank.shared.topic(id: word.topic) }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("TỪ MỚI")
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accent.opacity(0.12)))
                    .padding(.top, 12)

                    VStack(spacing: 10) {
                        if let topic { Text(topic.emoji).font(.system(size: 44)) }
                        Text(word.word)
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text(word.ipa)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.accent)
                            Text(word.posLabel)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.cardRaised))
                                .foregroundColor(Theme.textSecondary)
                        }
                        HStack(spacing: 16) {
                            SpeakButton(text: word.word, size: 56)
                            SpeakButton(text: word.word, slow: true, size: 56)
                        }
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .card(padding: 22)

                    if revealed {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NGHĨA").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundColor(Theme.textSecondary)
                                Text(word.vi)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("VÍ DỤ").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Button { SpeechManager.shared.speak(word.ex) } label: {
                                        Image(systemName: "speaker.wave.2.fill").foregroundColor(Theme.accent)
                                    }
                                }
                                Text(word.ex)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Text(word.exVi)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            if let tip = word.tip {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill").foregroundColor(Theme.warning)
                                    Text(tip)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.warning.opacity(0.12)))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Theme.accentLight)
                            Text("Thử đoán nghĩa trong đầu trước,\nrồi chạm để xem đáp án")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Theme.stroke, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture(perform: reveal)
                    }
                }
                .padding(.horizontal, 18)
            }

            Button(revealed ? "Đã nhớ, tiếp tục" : "Xem nghĩa") {
                if revealed { onContinue() } else { reveal() }
            }
            .buttonStyle(BigButtonStyle(color: revealed ? Theme.success : Theme.accent))
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    private func reveal() {
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { revealed = true }
    }
}
