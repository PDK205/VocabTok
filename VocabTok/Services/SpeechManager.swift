import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession Error: \(error)")
        }
    }

    func speak(text: String, rate: Float = 0.48) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
}