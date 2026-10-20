import SwiftUI

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        self.init(
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }

    /// A colour that switches between light and dark appearance.
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

enum Theme {
    static let background = Color.adaptive(light: "F4F5FB", dark: "0E1016")
    static let card = Color.adaptive(light: "FFFFFF", dark: "1A1D27")
    static let cardRaised = Color.adaptive(light: "EEF0F8", dark: "242836")
    static let stroke = Color.adaptive(light: "E3E6F0", dark: "2E3344")
    static let textPrimary = Color.adaptive(light: "1B1D2A", dark: "F3F4F8")
    static let textSecondary = Color.adaptive(light: "6B7086", dark: "9AA0B4")

    static let accent = Color(hex: "6C5CE7")
    static let accentLight = Color(hex: "A29BFE")
    static let success = Color(hex: "22C55E")
    static let danger = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
    static let flame = Color(hex: "FF7A1A")
    static let sky = Color(hex: "0EA5E9")

    static let accentGradient = LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "8E7CFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let flameGradient = LinearGradient(colors: [Color(hex: "FF9F43"), Color(hex: "FF5E3A")], startPoint: .top, endPoint: .bottom)
    static let successGradient = LinearGradient(colors: [Color(hex: "34D399"), Color(hex: "16A34A")], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func card(padding: CGFloat = 18) -> some View { modifier(CardModifier(padding: padding)) }
}

/// Chunky, tactile primary button that squishes when pressed.
struct BigButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var textColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color)
                    .shadow(color: color.opacity(0.35), radius: configuration.isPressed ? 2 : 10, x: 0, y: configuration.isPressed ? 1 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Subtle press feedback for cards and tiles.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var gradient: [Color] = [Theme.accent, Theme.accentLight]

    var body: some View {
        ZStack {
            Circle().stroke(Theme.cardRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(AngularGradient(colors: gradient + [gradient[0]], center: .center), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
        }
    }
}

struct CapsuleProgressBar: View {
    var progress: Double
    var color: Color = Theme.accent
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.cardRaised)
                Capsule()
                    .fill(color)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: height * 0.3)
                            .padding(.horizontal, height * 0.5)
                            .offset(y: -height * 0.15),
                        alignment: .top
                    )
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
    }
}

struct SpeakButton: View {
    let text: String
    var slow = false
    var size: CGFloat = 52

    var body: some View {
        Button {
            Haptics.tap()
            SpeechManager.shared.speak(text, slow: slow)
        } label: {
            Image(systemName: slow ? "tortoise.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(slow ? Theme.sky : Theme.accent))
                .shadow(color: (slow ? Theme.sky : Theme.accent).opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(slow ? "Nghe chậm" : "Nghe phát âm")
    }
}
