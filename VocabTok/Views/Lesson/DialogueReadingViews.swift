import SwiftUI

// MARK: - Dialogue

/// Chat-style dialogue with two voices, line highlighting and optional translation.
struct DialoguePlayerView: View {
    let dialogue: Dialogue
    @State private var showTranslation = false
    @State private var playingIndex: Int?
    @State private var isPlayingAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dialogue.title)
                    .font(.rounded(24, .heavy))
                    .foregroundColor(Theme.textPrimary)
                Text(dialogue.setting)
                    .font(.rounded(14, .medium))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: 10) {
                Button(action: togglePlayAll) {
                    Label(isPlayingAll ? "Dừng" : "Nghe cả bài", systemImage: isPlayingAll ? "stop.fill" : "play.fill")
                        .font(.rounded(14, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.accent))
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranslation.toggle() }
                } label: {
                    Label(showTranslation ? "Ẩn dịch" : "Hiện dịch", systemImage: "character.bubble")
                        .font(.rounded(14, .bold))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.accent.opacity(0.12)))
                }
            }

            VStack(spacing: 12) {
                ForEach(Array(dialogue.lines.enumerated()), id: \.offset) { index, line in
                    bubble(line: line, index: index)
                }
            }
        }
        .onDisappear {
            isPlayingAll = false
            SpeechManager.shared.stop()
        }
    }

    private func bubble(line: DialogueLine, index: Int) -> some View {
        let isA = line.speaker == "A"
        let active = playingIndex == index
        return HStack(alignment: .bottom, spacing: 8) {
            if !isA { Spacer(minLength: 40) }
            if isA { avatar(line.name, color: Theme.accent) }
            VStack(alignment: isA ? .leading : .trailing, spacing: 4) {
                Text(line.name)
                    .font(.rounded(11, .heavy))
                    .foregroundColor(Theme.textSecondary)
                Text(line.en)
                    .font(.rounded(16, .semibold))
                    .foregroundColor(isA ? Theme.textPrimary : .white)
                    .multilineTextAlignment(isA ? .leading : .trailing)
                if showTranslation {
                    Text(line.vi)
                        .font(.rounded(13, .medium))
                        .foregroundColor(isA ? Theme.textSecondary : .white.opacity(0.85))
                        .multilineTextAlignment(isA ? .leading : .trailing)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isA ? Theme.card : Theme.accent)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(active ? Theme.warning : Color.clear, lineWidth: 2.5)
            )
            .scaleEffect(active ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: active)
            .onTapGesture { play(index: index, continueAll: false) }
            if !isA { avatar(line.name, color: Theme.pink) }
            if isA { Spacer(minLength: 40) }
        }
    }

    private func avatar(_ name: String, color: Color) -> some View {
        Text(String(name.prefix(1)))
            .font(.rounded(14, .heavy))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Circle().fill(color.gradient))
    }

    private func togglePlayAll() {
        Haptics.tap()
        if isPlayingAll {
            isPlayingAll = false
            playingIndex = nil
            SpeechManager.shared.stop()
        } else {
            isPlayingAll = true
            play(index: 0, continueAll: true)
        }
    }

    private func play(index: Int, continueAll: Bool) {
        guard dialogue.lines.indices.contains(index) else {
            playingIndex = nil
            isPlayingAll = false
            return
        }
        if !continueAll { isPlayingAll = false }
        let line = dialogue.lines[index]
        playingIndex = index
        SpeechManager.shared.speak(line.en, role: line.speaker == "A" ? .speakerA : .speakerB) {
            if continueAll && isPlayingAll {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if isPlayingAll { play(index: index + 1, continueAll: true) }
                }
            } else if playingIndex == index {
                playingIndex = nil
            }
        }
    }
}

struct DialogueIntroView: View {
    let dialogue: Dialogue
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Chip(text: "HỘI THOẠI", color: Theme.sky, icon: "bubble.left.and.bubble.right.fill")
                        .padding(.top, 12)
                    DialoguePlayerView(dialogue: dialogue)
                    Text("Mẹo: nghe cả bài trước, sau đó chạm vào từng câu để nghe lại và nói theo (shadowing).")
                        .font(.rounded(13, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
            Button("Tiếp tục làm bài", action: onContinue)
                .buttonStyle(BigButtonStyle(color: Theme.sky))
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Reading

/// Reading passage where every word can be tapped to look it up.
struct ReadingContentView: View {
    let reading: Reading
    @State private var showTranslation = false
    @State private var lookup: Word?
    @State private var verb: IrregularVerb?

    private var tokens: [String] { reading.text.split(separator: " ").map(String.init) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(reading.title)
                .font(.rounded(24, .heavy))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    if SpeechManager.shared.isSpeaking {
                        SpeechManager.shared.stop()
                    } else {
                        SpeechManager.shared.speak(reading.text)
                    }
                } label: {
                    Label("Nghe bài đọc", systemImage: "play.fill")
                        .font(.rounded(14, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.success))
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranslation.toggle() }
                } label: {
                    Label(showTranslation ? "Ẩn dịch" : "Xem bản dịch", systemImage: "character.bubble")
                        .font(.rounded(14, .bold))
                        .foregroundColor(Theme.success)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.success.opacity(0.12)))
                }
            }

            FlowLayout(spacing: 5, lineSpacing: 7) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                    let known = ContentStore.shared.lookup(token)
                    Text(token)
                        .font(.rounded(17, .medium))
                        .foregroundColor(Theme.textPrimary)
                        .underline(known != nil, color: Theme.accent.opacity(0.5))
                        .onTapGesture { tap(token) }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.card))

            Text("Chạm vào một từ để nghe và xem nghĩa. Từ gạch chân có trong giáo trình.")
                .font(.rounded(12, .medium))
                .foregroundColor(Theme.textSecondary)

            if showTranslation {
                Text(reading.vi)
                    .font(.rounded(15, .medium))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(3)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.cardRaised))
                    .transition(.opacity)
            }
        }
        .sheet(item: $lookup) { word in
            WordDetailSheet(word: word)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $verb) { verb in
            VerbSheet(verb: verb)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .onDisappear { SpeechManager.shared.stop() }
    }

    private func tap(_ token: String) {
        let clean = token.trimmingCharacters(in: CharacterSet.letters.inverted)
        guard !clean.isEmpty else { return }
        Haptics.tap()
        SpeechManager.shared.speak(clean)
        if let word = ContentStore.shared.lookup(clean) {
            lookup = word
        } else if let v = ContentStore.shared.irregularVerb(for: clean) {
            verb = v
        }
    }
}

struct VerbSheet: View {
    let verb: IrregularVerb

    var body: some View {
        VStack(spacing: 14) {
            Text(verb.base)
                .font(.rounded(32, .heavy))
                .foregroundColor(Theme.textPrimary)
            Text(verb.vi)
                .font(.rounded(17, .semibold))
                .foregroundColor(Theme.textSecondary)
            HStack(spacing: 10) {
                verbForm("V1", verb.base)
                verbForm("V2", verb.past)
                verbForm("V3", verb.pp)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }

    private func verbForm(_ label: String, _ value: String) -> some View {
        Button {
            SpeechManager.shared.speak(value.replacingOccurrences(of: "/", with: ", "))
        } label: {
            VStack(spacing: 4) {
                Text(label).font(.rounded(12, .heavy)).foregroundColor(Theme.accent)
                Text(value).font(.rounded(16, .bold)).foregroundColor(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
        }
        .buttonStyle(PressableStyle())
    }
}

struct ReadingIntroView: View {
    let reading: Reading
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Chip(text: "ĐỌC HIỂU", color: Theme.success, icon: "book.fill")
                        .padding(.top, 12)
                    ReadingContentView(reading: reading)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
            Button("Trả lời câu hỏi", action: onContinue)
                .buttonStyle(BigButtonStyle(color: Theme.success))
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
    }
}
