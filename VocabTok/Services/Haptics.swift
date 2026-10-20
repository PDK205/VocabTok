import UIKit

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
