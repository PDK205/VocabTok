import SwiftUI

/// 60-second matching game.
struct SpeedMatchView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case ready, playing, finished }

    @State private var phase: Phase = .ready
    @State private var timeLeft: Double = 60
    @State private var score = 0
    @State private var board: [MatchPair] = []
    @State private var leftOrder: [MatchPair] = []
    @State private var rightOrder: [MatchPair] = []
    @State private var matched: Set<String> = []
    @State private var selectedLeft: String?
    @State private var selectedRight: String?
    @State private var wrong: Set<String> = []
    @State private var earnedXP = 0
    @State private var pool: [Word] = []
    @State private var poolIndex = 0

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let total: Double = 60

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch phase {
            case .ready: readyView
            case .playing: playingView
            case .finished: finishedView
            }
        }
        .onReceive(timer) { _ in
            guard phase == .playing else { return }
            timeLeft -= 0.1
            if timeLeft <= 0 { end() }
        }
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            Spacer()
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(Theme.goldGradient)
            Text("Ghép cặp tốc độ")
                .font(.rounded(30, .heavy))
                .foregroundColor(Theme.textPrimary)
            Text("Ghép càng nhiều cặp từ – nghĩa càng tốt trong 60 giây. Ghép sai bị trừ 3 giây!")
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if store.data.speedMatchBest > 0 {
                Chip(text: "Kỷ lục của bạn: \(store.data.speedMatchBest) cặp", color: Theme.warning, icon: "trophy.fill")
            }
            Spacer()
            Button("Bắt đầu!", action: start)
                .buttonStyle(BigButtonStyle(color: Theme.warning))
        }
        .padding(24)
    }

    private var playingView: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Button { end() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.textSecondary)
                }
                CapsuleProgressBar(progress: max(timeLeft, 0) / total, color: timeLeft < 10 ? Theme.danger : Theme.warning, height: 14)
                Text("\(Int(ceil(max(timeLeft, 0))))s")
                    .font(.rounded(16, .heavy))
                    .foregroundColor(timeLeft < 10 ? Theme.danger : Theme.textPrimary)
                    .frame(width: 44)
            }
            HStack {
                Text("Điểm")
                    .font(.rounded(15, .bold))
                    .foregroundColor(Theme.textSecondary)
                Text("\(score)")
                    .font(.rounded(34, .heavy))
                    .foregroundColor(Theme.warning)
                    .contentTransition(.numericText())
                Spacer()
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(leftOrder) { pair in
                        MatchTile(text: pair.left, state: state(pair.id, left: true), english: true) { tap(pair.id, left: true) }
                    }
                }
                VStack(spacing: 10) {
                    ForEach(rightOrder) { pair in
                        MatchTile(text: pair.right, state: state(pair.id, left: false), english: false) { tap(pair.id, left: false) }
                    }
                }
            }
            Spacer()
        }
        .padding(18)
    }

    private var finishedView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(score >= store.data.speedMatchBest && score > 0 ? "Kỷ lục mới! 🏆" : "Hết giờ! ⏰")
                .font(.rounded(30, .heavy))
                .foregroundColor(Theme.textPrimary)
            Text("\(score)")
                .font(.rounded(80, .heavy))
                .foregroundStyle(Theme.goldGradient)
            Text("cặp từ đã ghép")
                .font(.rounded(16, .semibold))
                .foregroundColor(Theme.textSecondary)
            HStack(spacing: 12) {
                Chip(text: "+\(earnedXP) XP", color: Theme.warning, icon: "bolt.fill")
                Chip(text: "Kỷ lục: \(store.data.speedMatchBest)", color: Theme.accent, icon: "trophy.fill")
            }
            Spacer()
            Button("Chơi lại", action: start)
                .buttonStyle(BigButtonStyle(color: Theme.warning))
            Button("Đóng") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .overlay { if score > 0 { ConfettiView() } }
    }

    private func state(_ id: String, left: Bool) -> MatchTile.TileState {
        if matched.contains(id) { return .matched }
        if wrong.contains((left ? "L" : "R") + id) { return .wrong }
        if (left ? selectedLeft : selectedRight) == id { return .selected }
        return .idle
    }

    private func start() {
        let learned = store.learnedWords
        pool = (learned.count >= 8 ? learned : learned + ContentStore.shared.allWords.prefix(60)).shuffled()
        poolIndex = 0
        score = 0
        timeLeft = total
        earnedXP = 0
        newBoard()
        withAnimation { phase = .playing }
    }

    private func newBoard() {
        var pairs: [MatchPair] = []
        var used = Set<String>()
        while pairs.count < 4 && !pool.isEmpty {
            let word = pool[poolIndex % pool.count]
            poolIndex += 1
            if used.contains(word.vi) || used.contains(word.id) { if poolIndex > pool.count * 2 { break } else { continue } }
            used.insert(word.vi)
            used.insert(word.id)
            pairs.append(MatchPair(id: word.id, left: word.word, right: word.vi))
        }
        board = pairs
        leftOrder = pairs.shuffled()
        rightOrder = pairs.shuffled()
        matched = []
        selectedLeft = nil
        selectedRight = nil
    }

    private func tap(_ id: String, left: Bool) {
        guard phase == .playing, !matched.contains(id) else { return }
        Haptics.tap()
        if left {
            selectedLeft = id
            if let pair = board.first(where: { $0.id == id }) { SpeechManager.shared.speak(pair.left) }
        } else {
            selectedRight = id
        }
        guard let l = selectedLeft, let r = selectedRight else { return }
        if l == r {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _ = matched.insert(l)
                score += 1
            }
            SoundFX.tap.play()
            selectedLeft = nil
            selectedRight = nil
            if matched.count == board.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeInOut(duration: 0.2)) { newBoard() }
                }
            }
        } else {
            let keys: Set<String> = ["L" + l, "R" + r]
            wrong.formUnion(keys)
            timeLeft = max(0, timeLeft - 3)
            Haptics.error()
            selectedLeft = nil
            selectedRight = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { wrong.subtract(keys) }
        }
    }

    private func end() {
        guard phase == .playing else { return }
        let played = Int(total - max(timeLeft, 0))
        earnedXP = store.recordSpeedMatch(score: score, seconds: played)
        SoundFX.complete.play()
        Haptics.celebrate()
        withAnimation { phase = .finished }
    }
}
