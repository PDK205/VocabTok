import SwiftUI

/// TikTok-style vertical feed of word cards.
struct WordFeedView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss
    let words: [Word]

    @State private var index = 0
    @State private var dragOffset: CGFloat = 0
    @State private var hideMeaning = false

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            ZStack {
                Color.black.ignoresSafeArea()
                ForEach(words.indices, id: \.self) { i in
                    if abs(i - index) <= 1 {
                        FeedCard(word: words[i], hideMeaning: hideMeaning, saved: store.isSaved(words[i])) {
                            store.toggleSaved(words[i])
                        }
                        .frame(width: geo.size.width, height: height)
                        .offset(y: CGFloat(i - index) * height + dragOffset)
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation.height }
                    .onEnded { value in
                        let threshold = height * 0.15
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            if value.translation.height < -threshold && index < words.count - 1 {
                                index += 1
                            } else if value.translation.height > threshold && index > 0 {
                                index -= 1
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.25)))
                }
                Spacer()
                Text("\(min(index + 1, words.count))/\(words.count)")
                    .font(.rounded(14, .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.black.opacity(0.25)))
                Spacer()
                Button {
                    withAnimation { hideMeaning.toggle() }
                } label: {
                    Image(systemName: hideMeaning ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.25)))
                }
                .accessibilityLabel(hideMeaning ? "Hiện nghĩa" : "Ẩn nghĩa để tự kiểm tra")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onAppear { speakCurrent() }
        .onChange(of: index) { _ in
            Haptics.soft()
            speakCurrent()
        }
        .onDisappear { SpeechManager.shared.stop() }
    }

    private func speakCurrent() {
        guard words.indices.contains(index) else { return }
        let text = words[index].word
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { SpeechManager.shared.speak(text) }
    }
}

private struct FeedCard: View {
    let word: Word
    let hideMeaning: Bool
    let saved: Bool
    let onSave: () -> Void
    @State private var revealed = false

    private var color: Color {
        let unit = ContentStore.shared.unit(id: word.unitId)
        return Theme.levelColor(unit.flatMap { ContentStore.shared.level(of: $0) })
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [color.opacity(0.95), Color(hex: "1E1B4B")], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.06)).frame(width: 320, height: 320).offset(x: 140, y: -260)
            Circle().fill(Color.white.opacity(0.05)).frame(width: 240, height: 240).offset(x: -150, y: 260)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 14) {
                    Spacer()
                    Text(word.posLabel.uppercased())
                        .font(.rounded(12, .heavy))
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.75))
                    Text(word.word)
                        .font(.rounded(52, .heavy))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(word.ipa)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Group {
                        if hideMeaning && !revealed {
                            Text("Chạm để xem nghĩa")
                                .font(.rounded(18, .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().strokeBorder(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                                .onTapGesture { withAnimation { revealed = true } }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(word.vi)
                                    .font(.rounded(24, .heavy))
                                    .foregroundColor(Color(hex: "FDE68A"))
                                Text("“\(word.ex)”")
                                    .font(.rounded(17, .semibold))
                                    .foregroundColor(.white)
                                Text(word.exVi)
                                    .font(.rounded(14, .medium))
                                    .foregroundColor(.white.opacity(0.75))
                                if let tip = word.tip {
                                    Label(tip, systemImage: "lightbulb.fill")
                                        .font(.rounded(13, .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.12)))
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    Spacer().frame(height: 60)
                }
                Spacer(minLength: 12)
                VStack(spacing: 22) {
                    sideButton(icon: "speaker.wave.2.fill", label: "Nghe") { SpeechManager.shared.speak(word.word) }
                    sideButton(icon: "tortoise.fill", label: "Chậm") { SpeechManager.shared.speak(word.word, slow: true) }
                    sideButton(icon: "text.quote", label: "Câu") { SpeechManager.shared.speak(word.ex) }
                    sideButton(icon: saved ? "bookmark.fill" : "bookmark", label: saved ? "Đã lưu" : "Lưu", tint: saved ? Color(hex: "FDE68A") : .white) {
                        Haptics.tap()
                        onSave()
                    }
                    Spacer().frame(height: 70)
                }
            }
            .padding(.horizontal, 22)

            VStack {
                Spacer()
                Label("Vuốt lên để xem từ tiếp theo", systemImage: "chevron.up")
                    .font(.rounded(12, .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
    }

    private func sideButton(icon: String, label: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(tint)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.white.opacity(0.15)))
                Text(label)
                    .font(.rounded(11, .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .buttonStyle(PressableStyle())
    }
}
