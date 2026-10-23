import AVFoundation
import UIKit
import UserNotifications

// MARK: - Haptics

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func celebrate() {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { generator.impactOccurred(intensity: 0.7) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { generator.impactOccurred(intensity: 0.4) }
    }
}

// MARK: - Sound effects

enum SoundFX: String, CaseIterable {
    case correct, wrong, complete, tap, unlock, combo

    private static var players: [SoundFX: AVAudioPlayer] = [:]

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "effectsOn") as? Bool ?? true
    }

    static func preload() {
        for sound in SoundFX.allCases where players[sound] == nil {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = sound == .tap ? 0.35 : 0.6
            player.prepareToPlay()
            players[sound] = player
        }
    }

    func play() {
        guard SoundFX.enabled else { return }
        if SoundFX.players[self] == nil { SoundFX.preload() }
        guard let player = SoundFX.players[self] else { return }
        player.currentTime = 0
        player.play()
    }
}

// MARK: - Daily reminders

enum Reminders {
    private static let messages: [(String, String)] = [
        ("Đến giờ học rồi! 📚", "Chỉ 5 phút hôm nay để giữ chuỗi ngày học nhé."),
        ("Từ vựng đang chờ bạn 🧠", "Ôn lại vài từ trước khi chúng bị quên mất."),
        ("Giữ lửa nào! 🔥", "Một bài học ngắn là đủ để duy trì chuỗi ngày."),
        ("Tiếng Anh mỗi ngày ✨", "Bạn đang tiến bộ rất tốt, tiếp tục thôi!"),
        ("Thử thách hôm nay 🎯", "Hoàn thành nhiệm vụ hằng ngày để nhận rương thưởng."),
        ("Luyện nói chút nhé 🎤", "Nói to vài câu tiếng Anh để phát âm chuẩn hơn."),
        ("Cuối tuần vui vẻ 🌈", "Dành 10 phút ôn lại những gì đã học trong tuần.")
    ]

    static func requestPermission(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func schedule(hour: Int, minute: Int, name: String) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for weekday in 1...7 {
            let message = messages[(weekday - 1) % messages.count]
            let content = UNMutableNotificationContent()
            content.title = name.isEmpty ? message.0 : "\(name) ơi, \(message.0.prefix(1).lowercased())\(message.0.dropFirst())"
            content.body = message.1
            content.sound = .default
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "daily-\(weekday)", content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
