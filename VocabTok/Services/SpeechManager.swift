import AVFoundation

/// Text-to-speech with selectable accent and two distinct voices for dialogues.
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()

    enum Role { case main, speakerA, speakerB }

    private let synthesizer = AVSpeechSynthesizer()
    private var completions: [ObjectIdentifier: () -> Void] = [:]
    private var cachedAccent = ""
    private var voices: [Role: AVSpeechSynthesisVoice] = [:]

    private override init() {
        super.init()
        synthesizer.delegate = self
        SpeechManager.configurePlaybackSession()
    }

    static func configurePlaybackSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    private var accent: String {
        UserDefaults.standard.string(forKey: "accent") ?? "en-US"
    }

    private var baseRate: Float {
        let stored = UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.46
        return Float(stored)
    }

    private var soundOn: Bool {
        UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true
    }

    private func voice(for role: Role) -> AVSpeechSynthesisVoice? {
        if cachedAccent != accent {
            cachedAccent = accent
            voices = SpeechManager.pickVoices(language: accent)
        }
        return voices[role] ?? voices[.main]
    }

    private static func pickVoices(language: String) -> [Role: AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        let ranked = all.sorted { $0.quality.rawValue > $1.quality.rawValue }
        var result: [Role: AVSpeechSynthesisVoice] = [:]
        let main = ranked.first ?? AVSpeechSynthesisVoice(language: language)
        result[.main] = main
        let females = ranked.filter { $0.gender == .female }
        let males = ranked.filter { $0.gender == .male }
        result[.speakerA] = females.first ?? main
        result[.speakerB] = males.first ?? ranked.first { $0.identifier != result[.speakerA]?.identifier } ?? main
        return result
    }

    func speak(_ text: String, slow: Bool = false, role: Role = .main, completion: (() -> Void)? = nil) {
        guard soundOn else {
            completion?()
            return
        }
        SpeechManager.configurePlaybackSession()
        try? AVAudioSession.sharedInstance().setActive(true)
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: role)
        utterance.rate = slow ? max(0.22, baseRate - 0.18) : baseRate
        utterance.preUtteranceDelay = 0.03
        if role != .main, voices[.speakerA]?.identifier == voices[.speakerB]?.identifier {
            // Only one voice installed: change the pitch so speakers still sound different.
            utterance.pitchMultiplier = role == .speakerA ? 1.15 : 0.85
        }
        if let completion {
            completions[ObjectIdentifier(utterance)] = completion
        }
        synthesizer.speak(utterance)
    }

    func stop() {
        completions.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        if let completion = completions.removeValue(forKey: key) {
            DispatchQueue.main.async { completion() }
        }
        // Let background music return to full volume once we stop talking.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, !self.synthesizer.isSpeaking,
                  AVAudioSession.sharedInstance().category == .playback else { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completions.removeValue(forKey: ObjectIdentifier(utterance))
    }
}
