import SwiftUI

/// Lightweight confetti burst drawn with Canvas.
struct ConfettiView: View {
    private struct Piece {
        let x: Double
        let speed: Double
        let drift: Double
        let spin: Double
        let size: Double
        let color: Color
        let delay: Double
    }

    private let pieces: [Piece] = {
        let colors: [Color] = [Theme.accent, Theme.success, Theme.warning, Theme.flame, Theme.sky, Color(hex: "EC4899")]
        return (0..<90).map { _ in
            Piece(
                x: Double.random(in: 0...1),
                speed: Double.random(in: 180...380),
                drift: Double.random(in: -60...60),
                spin: Double.random(in: 2...8),
                size: Double.random(in: 6...12),
                color: colors.randomElement() ?? Theme.accent,
                delay: Double.random(in: 0...0.6)
            )
        }
    }()

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                for p in pieces {
                    let local = t - p.delay
                    guard local > 0 else { continue }
                    let y = -20 + local * p.speed
                    guard y < size.height + 20 else { continue }
                    let x = p.x * size.width + sin(local * 2 + p.spin) * p.drift
                    var piece = context
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(local * p.spin))
                    piece.opacity = max(0, 1 - local / 4)
                    piece.fill(Path(roundedRect: CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2), cornerRadius: 2), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
