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
        Color(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

enum Theme {
    static let background = Color.adaptive(light: "F4F5FB", dark: "0E1016")
    static let card = Color.adaptive(light: "FFFFFF", dark: "1A1D27")
    static let cardRaised = Color.adaptive(light: "EEF0F8", dark: "252937")
    static let stroke = Color.adaptive(light: "E3E6F0", dark: "2F3446")
    static let textPrimary = Color.adaptive(light: "1B1D2A", dark: "F3F4F8")
    static let textSecondary = Color.adaptive(light: "6B7086", dark: "9AA0B4")

    static let accent = Color(hex: "6C5CE7")
    static let accentLight = Color(hex: "A29BFE")
    static let success = Color(hex: "22C55E")
    static let danger = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
    static let flame = Color(hex: "FF7A1A")
    static let sky = Color(hex: "0EA5E9")
    static let pink = Color(hex: "EC4899")
    static let gold = Color(hex: "FACC15")
    static let ice = Color(hex: "38BDF8")

    static let accentGradient = LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "8E7CFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let flameGradient = LinearGradient(colors: [Color(hex: "FFB347"), Color(hex: "FF5E3A")], startPoint: .top, endPoint: .bottom)
    static let goldGradient = LinearGradient(colors: [Color(hex: "FDE047"), Color(hex: "F59E0B")], startPoint: .top, endPoint: .bottom)

    static func levelColor(_ level: Level?) -> Color {
        Color(hex: level?.color ?? "6C5CE7")
    }

    static func gradient(_ hex: String) -> LinearGradient {
        let base = Color(hex: hex)
        return LinearGradient(colors: [base, base.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func card(padding: CGFloat = 18, radius: CGFloat = 22) -> some View {
        modifier(CardModifier(padding: padding, radius: radius))
    }
}

/// Chunky, tactile primary button that squishes when pressed.
struct BigButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var textColor: Color = .white
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(17, .bold))
            .foregroundColor(enabled ? textColor : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(enabled ? color : Theme.cardRaised)
                    .shadow(color: enabled ? color.opacity(0.35) : .clear, radius: configuration.isPressed ? 2 : 10, x: 0, y: configuration.isPressed ? 1 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(16, .bold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color.opacity(0.12)))
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
    var colors: [Color] = [Theme.accent, Theme.accentLight]

    var body: some View {
        ZStack {
            Circle().stroke(Theme.cardRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(AngularGradient(colors: colors + [colors[0]], center: .center), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
                    .frame(width: max(progress > 0 ? height : 0, geo.size.width * min(max(progress, 0), 1)))
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: height * 0.28)
                            .padding(.horizontal, height * 0.5)
                            .offset(y: -height * 0.14),
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
    var color: Color = Theme.accent

    var body: some View {
        Button {
            Haptics.tap()
            SpeechManager.shared.speak(text, slow: slow)
        } label: {
            Image(systemName: slow ? "tortoise.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(slow ? Theme.sky : color))
                .shadow(color: (slow ? Theme.sky : color).opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(slow ? "Nghe chậm" : "Nghe phát âm")
    }
}

struct Chip: View {
    let text: String
    var color: Color = Theme.accent
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.rounded(12, .bold))
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.13)))
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.rounded(13, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconBadge: View {
    let icon: String
    var color: Color = Theme.accent
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(color.gradient))
    }
}

struct StatTile: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.rounded(20, .heavy))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.rounded(12, .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}

struct EmptyStateView: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 56))
            Text(title)
                .font(.rounded(19, .heavy))
                .foregroundColor(Theme.textPrimary)
            Text(message)
                .font(.rounded(14, .medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}

/// Wraps children onto multiple lines (word tiles, tappable reading text).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if lineWidth > 0 && lineWidth + spacing + size.width > maxWidth {
                totalHeight += lineHeight + lineSpacing
                widest = max(widest, lineWidth)
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += (lineWidth > 0 ? spacing : 0) + size.width
            lineHeight = max(lineHeight, size.height)
        }
        totalHeight += lineHeight
        widest = max(widest, lineWidth)
        return CGSize(width: proposal.width ?? widest, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(LayoutSubview, CGSize)]] = [[]]
        var lineWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if lineWidth > 0 && lineWidth + spacing + size.width > bounds.width {
                rows.append([])
                lineWidth = 0
            }
            rows[rows.count - 1].append((view, size))
            lineWidth += (lineWidth > 0 ? spacing : 0) + size.width
        }
        var y = bounds.minY
        for row in rows {
            let rowWidth = row.reduce(0) { $0 + $1.1.width } + spacing * CGFloat(max(row.count - 1, 0))
            let rowHeight = row.map(\.1.height).max() ?? 0
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - rowWidth) / 2
            case .trailing: x = bounds.maxX - rowWidth
            default: x = bounds.minX
            }
            for (view, size) in row {
                view.place(at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}
