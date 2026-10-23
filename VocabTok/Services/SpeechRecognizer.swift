import AVFoundation
import Speech

/// Live English speech recognition used to grade pronunciation exercises.
final class SpeechRecognizer: ObservableObject {
    enum Status { case unknown, authorized, denied, unavailable }

    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var status: Status = .unknown
    @Published private(set) var level: Float = 0

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    init() {
        if recognizer == nil {
            status = .unavailable
        } else if SFSpeechRecognizer.authorizationStatus() == .authorized,
                  AVAudioSession.sharedInstance().recordPermission == .granted {
            status = .authorized
        }
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        guard recognizer != nil else {
            status = .unavailable
            completion(false)
            return
        }
        SFSpeechRecognizer.requestAuthorization { auth in
            guard auth == .authorized else {
                DispatchQueue.main.async {
                    self.status = .denied
                    completion(false)
                }
                return
            }
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.status = granted ? .authorized : .denied
                    completion(granted)
                }
            }
        }
    }

    func start() {
        guard status == .authorized, let recognizer, recognizer.isAvailable else { return }
        stop()
        SpeechManager.shared.stop()
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                self?.updateLevel(buffer)
            }
            engine.prepare()
            try engine.start()
            isRecording = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self.finishAudio()
                    }
                }
            }
        } catch {
            stop()
        }
    }

    private func updateLevel(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        var sum: Float = 0
        for i in stride(from: 0, to: count, by: 8) { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(max(count / 8, 1)))
        DispatchQueue.main.async { self.level = min(1, rms * 12) }
    }

    private func finishAudio() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        isRecording = false
        level = 0
    }

    func stop() {
        finishAudio()
        task?.cancel()
        task = nil
        request = nil
        SpeechManager.configurePlaybackSession()
    }
}

/// Compares what the learner said (or typed) with the expected text.
enum TextMatch {
    static func normalize(_ text: String) -> String {
        let replaced = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
        let allowed = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: "' "))
        let filtered = String(replaced.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " })
        return filtered.split(separator: " ").joined(separator: " ")
    }

    static func words(_ text: String) -> [String] {
        normalize(text).split(separator: " ").map(String.init)
    }

    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            prev = cur
        }
        return prev[b.count]
    }

    /// Typing check that forgives a small typo.
    static func isClose(_ input: String, _ answer: String) -> (correct: Bool, exact: Bool) {
        let a = normalize(input), b = normalize(answer)
        if a == b { return (true, true) }
        let allowed = max(1, b.count / 12)
        return (distance(a, b) <= allowed && !a.isEmpty, false)
    }

    /// Word-by-word pronunciation score.
    static func score(spoken: String, expected: String) -> (score: Double, matched: [Bool]) {
        let target = words(expected)
        var heard = words(spoken)
        guard !target.isEmpty else { return (0, []) }
        var matched: [Bool] = []
        for word in target {
            if let idx = heard.firstIndex(where: { $0 == word || (word.count >= 3 && distance($0, word) <= 1) }) {
                matched.append(true)
                heard.remove(at: idx)
            } else {
                matched.append(false)
            }
        }
        let score = Double(matched.filter { $0 }.count) / Double(target.count)
        return (score, matched)
    }
}
