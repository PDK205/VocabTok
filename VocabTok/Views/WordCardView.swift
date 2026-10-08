import SwiftUI

struct WordCardView: View {
    let word: VocabularyWord
    let index: Int
    let total: Int
    let onPlayNormal: () -> Void
    let onPlaySlow: () -> Void
    let onPlaySentence: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0E15"), Color(hex: "1F1D2B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Từ \(index + 1)/\(total)")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Text(word.word)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Text(word.phonetic)
                            .font(.title3)
                            .foregroundColor(Color.cyan)

                        Text("[\(word.partOfSpeech.uppercased())]")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(6)
                    }

                    HStack(spacing: 16) {
                        Button(action: onPlayNormal) {
                            Label("Nghe loa", systemImage: "speaker.wave.3.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }

                        Button(action: onPlaySlow) {
                            Label("Chậm", systemImage: "tortoise.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 6)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DỊCH NGHĨA")
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                        Text(word.meaningVi)
                            .font(.title3.bold())
                            .foregroundColor(Color.yellow)
                    }

                    Divider().background(Color.white.opacity(0.2))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("VÍ DỤ ANH - VIỆT")
                                .font(.caption2.bold())
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: onPlaySentence) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.cyan)
                            }
                        }

                        Text("“\(word.exampleEn)”")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .italic()

                        Text(word.exampleVi)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.75))
                    }

                    if !word.memoryTip.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(word.memoryTip)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.45))
                .cornerRadius(20)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}