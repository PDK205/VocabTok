import SwiftUI

/// Presents a new word. The meaning stays hidden until the learner has guessed (active recall).
struct IntroCardView: View {
    @EnvironmentObject private var store: ProgressStore
    let word: Word
    let onContinue: () -> Void
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        Chip(text: "TỪ MỚI", color: Theme.accent, icon: "sparkles")
                        Spacer()
                        Button {
                            Haptics.tap()
                            store.toggleSaved(word)
                        } label: {
                            Image(systemName: store.isSaved(word) ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(store.isSaved(word) ? Theme.warning : Theme.textSecondary)
                        }
                        .accessibilityLabel("Lưu vào sổ tay")
                    }
                    .padding(.top, 12)

                    VStack(spacing: 10) {
                        Text(word.word)
                            .font(.rounded(44, .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text(word.ipa)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.accent)
                            Chip(text: word.posLabel, color: Theme.textSecondary)
                        }
                        HStack(spacing: 16) {
                            SpeakButton(text: word.word, size: 58)
                            SpeakButton(text: word.word, slow: true, size: 58)
                        }
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .card(padding: 22)

                    if revealed {
                        WordInfoCard(word: word)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Theme.accentLight)
                            Text("Thử đoán nghĩa trong đầu trước,\nrồi chạm để xem đáp án")
                                .font(.rounded(15, .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
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

/// Meaning, example and memory tip of a word.
struct WordInfoCard: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NGHĨA").font(.rounded(12, .heavy)).foregroundColor(Theme.textSecondary)
                Text(word.vi)
                    .font(.rounded(22, .heavy))
                    .foregroundColor(Theme.textPrimary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("VÍ DỤ").font(.rounded(12, .heavy)).foregroundColor(Theme.textSecondary)
                    Spacer()
                    Button { SpeechManager.shared.speak(word.ex) } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundColor(Theme.accent)
                    }
                }
                Text(word.ex)
                    .font(.rounded(17, .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(word.exVi)
                    .font(.rounded(14, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            if let tip = word.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundColor(Theme.warning)
                    Text(tip)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.warning.opacity(0.12)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
