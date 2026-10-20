import SwiftUI

struct LessonCompleteView: View {
    @ObservedObject var vm: LessonViewModel
    let onDone: () -> Void
    @State private var appeared = false

    private var title: String {
        switch vm.accuracy {
        case 1: return "Hoàn hảo! 🏆"
        case 0.8...: return "Làm tốt lắm! 🎉"
        case 0.5...: return "Cố gắng tốt! 💪"
        default: return "Đã xong bài! 🌱"
        }
    }

    private var durationText: String {
        let seconds = Int(vm.duration)
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)p \(seconds % 60)s"
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(Theme.warning.opacity(0.15))
                            .frame(width: 150, height: 150)
                            .scaleEffect(appeared ? 1 : 0.4)
                        Image(systemName: vm.accuracy == 1 ? "trophy.fill" : "star.fill")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "FFD43B"), Theme.warning], startPoint: .top, endPoint: .bottom))
                            .rotationEffect(.degrees(appeared ? 0 : -30))
                            .scaleEffect(appeared ? 1 : 0.2)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("Bạn đã hoàn thành bài học hôm nay")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    HStack(spacing: 10) {
                        ResultTile(title: "XP", value: "+\(vm.xp)", icon: "bolt.fill", color: Theme.warning)
                        ResultTile(title: "Chính xác", value: "\(Int(vm.accuracy * 100))%", icon: "target", color: Theme.success)
                        ResultTile(title: "Combo", value: "\(vm.maxCombo)", icon: "flame.fill", color: Theme.flame)
                        ResultTile(title: "Thời gian", value: durationText, icon: "clock.fill", color: Theme.sky)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                    if !vm.mistakeWords.isEmpty {
                        wordList(title: "Cần ôn thêm", subtitle: "Sẽ được nhắc lại sớm", words: vm.mistakeWords, color: Theme.warning)
                    }
                    if !vm.perfectWords.isEmpty {
                        wordList(title: "Đã nhớ tốt", subtitle: "Lần ôn tiếp theo sẽ giãn ra", words: vm.perfectWords, color: Theme.success)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 110)
            }

            VStack {
                Spacer()
                Button("Tiếp tục", action: onDone)
                    .buttonStyle(BigButtonStyle(color: Theme.success))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(colors: [Theme.background.opacity(0), Theme.background], startPoint: .top, endPoint: .center)
                            .ignoresSafeArea()
                    )
            }

            ConfettiView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) { appeared = true }
        }
    }

    private func wordList(title: String, subtitle: String, words: [Word], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            ForEach(words) { word in
                HStack {
                    Text(word.word)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(word.vi)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .card()
    }
}

private struct ResultTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(color.opacity(0.12)))
    }
}
