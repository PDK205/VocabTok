import SwiftUI

/// Pronunciation practice graded with speech recognition (falls back to self-assessment).
struct SpeakExerciseView: View {
    let data: SpeakData
    let state: AnswerState
    let onResult: (Bool, Double) -> Void
    let onSkip: (Bool) -> Void

    @StateObject private var recognizer = SpeechRecognizer()
    @State private var attempts = 0
    @State private var bestScore: Double = 0
    @State private var matched: [Bool] = []
    @State private var message: String?
    @State private var stopWork: DispatchWorkItem?
    @State private var pulse = false

    private var expectedWords: [String] {
        data.text.split(separator: " ").map(String.init)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Nói câu này")
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            VStack(spacing: 12) {
                coloredText
                if let ipa = data.ipa {
                    Text(ipa).font(.system(size: 17)).foregroundColor(Theme.accent)
                }
                if let translation = data.translation {
                    Text(translation)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 16) {
                    SpeakButton(text: data.text, size: 48)
                    SpeakButton(text: data.text, slow: true, size: 48)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .card(padding: 20)

            if recognizer.status == .denied || recognizer.status == .unavailable {
                selfCheck
            } else {
                transcriptBox
                Spacer(minLength: 0)
                micButton
            }

            HStack(spacing: 18) {
                Button("Không nói được lúc này") { onSkip(true) }
                Button("Bỏ qua") { onSkip(false) }
            }
            .font(.rounded(14, .bold))
            .foregroundColor(Theme.textSecondary)
            .opacity(state == .answering ? 1 : 0)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
        .onDisappear {
            stopWork?.cancel()
            recognizer.stop()
        }
    }

    private var coloredText: some View {
        FlowLayout(spacing: 6, lineSpacing: 6, alignment: .center) {
            ForEach(Array(expectedWords.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(.rounded(expectedWords.count == 1 ? 40 : 24, .heavy))
                    .foregroundColor(color(forWordAt: index))
            }
        }
    }

    private func color(forWordAt index: Int) -> Color {
        guard matched.indices.contains(index) else { return Theme.textPrimary }
        return matched[index] ? Theme.success : Theme.danger
    }

    private var transcriptBox: some View {
        VStack(spacing: 6) {
            Text(recognizer.isRecording ? "Đang nghe..." : (recognizer.transcript.isEmpty ? "Chạm micro rồi đọc to" : "Bạn đã nói:"))
                .font(.rounded(13, .bold))
                .foregroundColor(Theme.textSecondary)
            Text(recognizer.transcript.isEmpty ? "…" : recognizer.transcript)
                .font(.rounded(18, .semibold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 30)
            if let message {
                Text(message)
                    .font(.rounded(13, .semibold))
                    .foregroundColor(Theme.warning)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.cardRaised))
    }

    private var micButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(Theme.pink.opacity(0.18))
                    .frame(width: 128, height: 128)
                    .scaleEffect(recognizer.isRecording ? 1 + CGFloat(recognizer.level) * 0.35 : 0.85)
                    .animation(.easeOut(duration: 0.12), value: recognizer.level)
                Circle()
                    .fill(recognizer.isRecording ? Theme.danger : Theme.pink)
                    .frame(width: 92, height: 92)
                    .shadow(color: Theme.pink.opacity(0.4), radius: 12, y: 6)
                Image(systemName: recognizer.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(state != .answering)
        .overlay(alignment: .bottom) {
            Text(recognizer.isRecording ? "Chạm để dừng" : (attempts > 0 ? "Thử lại (\(attempts)/3)" : "Chạm để nói"))
                .font(.rounded(12, .bold))
                .foregroundColor(Theme.textSecondary)
                .offset(y: 22)
        }
        .padding(.bottom, 24)
    }

    private var selfCheck: some View {
        VStack(spacing: 14) {
            Text(recognizer.status == .unavailable
                 ? "Thiết bị chưa hỗ trợ nhận dạng giọng nói. Hãy nghe mẫu, đọc to theo rồi tự đánh giá."
                 : "Bạn chưa cấp quyền micro / nhận dạng giọng nói. Hãy nghe mẫu, đọc to theo rồi tự đánh giá. (Có thể bật quyền trong Cài đặt iPhone.)")
                .font(.rounded(14, .medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                Button("Chưa tốt") { onResult(false, 0) }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.danger))
                Button("Tôi nói được 👍") { onResult(true, 1) }
                    .buttonStyle(BigButtonStyle(color: Theme.success))
            }
            .disabled(state != .answering)
        }
    }

    private func toggleRecording() {
        guard state == .answering else { return }
        Haptics.tap()
        if recognizer.isRecording {
            stopAndEvaluate()
            return
        }
        if recognizer.status == .unknown {
            recognizer.requestAccess { granted in
                if granted { startRecording() }
            }
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        message = nil
        matched = []
        recognizer.start()
        let seconds = min(10, 3 + Double(expectedWords.count) * 0.7)
        let work = DispatchWorkItem { stopAndEvaluate() }
        stopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func stopAndEvaluate() {
        stopWork?.cancel()
        guard recognizer.isRecording || !recognizer.transcript.isEmpty else { return }
        recognizer.stop()
        // Give the recogniser a moment to deliver its last partial result.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let result = TextMatch.score(spoken: recognizer.transcript, expected: data.text)
            withAnimation(.easeInOut(duration: 0.2)) { matched = result.matched }
            bestScore = max(bestScore, result.score)
            attempts += 1
            let passMark = expectedWords.count == 1 ? 1.0 : 0.7
            if result.score >= passMark {
                onResult(true, result.score)
            } else if attempts >= 3 {
                onResult(false, bestScore)
            } else if recognizer.transcript.isEmpty {
                message = "Mình chưa nghe thấy gì. Hãy nói to và rõ hơn nhé."
            } else {
                message = "Gần đúng rồi! Những từ màu đỏ cần phát âm rõ hơn. Nghe mẫu rồi thử lại."
            }
        }
    }
}
