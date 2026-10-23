import SwiftUI

/// Full grammar explanation: summary, formulas, key points, examples, common mistakes.
struct GrammarContentView: View {
    let grammar: Grammar
    var showPractice = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(grammar.title)
                .font(.rounded(26, .heavy))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(grammar.summary)
                .font(.rounded(16, .medium))
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.accent.opacity(0.1)))

            if !grammar.formulas.isEmpty {
                block(title: "CÔNG THỨC", icon: "function", color: Theme.accent) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(grammar.formulas, id: \.self) { formula in
                            Text(formula)
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardRaised))
                        }
                    }
                }
            }

            if !grammar.points.isEmpty {
                block(title: "GHI NHỚ", icon: "lightbulb.fill", color: Theme.warning) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(grammar.points.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.rounded(13, .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Theme.warning))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.title)
                                        .font(.rounded(16, .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(point.body)
                                        .font(.rounded(15, .regular))
                                        .foregroundColor(Theme.textSecondary)
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }

            if !grammar.examples.isEmpty {
                block(title: "VÍ DỤ", icon: "text.quote", color: Theme.sky) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(grammar.examples) { example in
                            ExampleRow(en: example.en, vi: example.vi)
                        }
                    }
                }
            }

            if !grammar.mistakes.isEmpty {
                block(title: "LỖI THƯỜNG GẶP", icon: "exclamationmark.triangle.fill", color: Theme.danger) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(grammar.mistakes, id: \.self) { mistake in
                            VStack(alignment: .leading, spacing: 5) {
                                Label(mistake.wrong, systemImage: "xmark.circle.fill")
                                    .foregroundColor(Theme.danger)
                                    .strikethrough(true, color: Theme.danger.opacity(0.6))
                                Label(mistake.right, systemImage: "checkmark.circle.fill")
                                    .foregroundColor(Theme.success)
                                Text(mistake.note)
                                    .font(.rounded(13, .medium))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .font(.rounded(15, .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func block<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.rounded(12, .heavy))
                .foregroundColor(color)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
    }
}

struct ExampleRow: View {
    let en: String
    let vi: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                SpeechManager.shared.speak(en)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.accent.opacity(0.12)))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(en)
                    .font(.rounded(15, .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(vi)
                    .font(.rounded(13, .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GrammarIntroView: View {
    let grammar: Grammar
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Chip(text: "NGỮ PHÁP", color: Theme.accent, icon: "puzzlepiece.extension.fill")
                        .padding(.top, 12)
                    GrammarContentView(grammar: grammar)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
            Button("Đã hiểu, làm bài tập", action: onContinue)
                .buttonStyle(BigButtonStyle())
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
    }
}
