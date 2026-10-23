import SwiftUI

struct WordDetailSheet: View {
    @EnvironmentObject private var store: ProgressStore
    let word: Word

    private var unit: Unit? { ContentStore.shared.unit(id: word.unitId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.word)
                            .font(.rounded(34, .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text(word.ipa).foregroundColor(Theme.accent)
                            Chip(text: word.posLabel, color: Theme.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(spacing: 10) {
                        SpeakButton(text: word.word, size: 46)
                        SpeakButton(text: word.word, slow: true, size: 46)
                    }
                }
                WordInfoCard(word: word)
                HStack {
                    MasteryDots(level: store.mastery(of: word))
                    Text(store.mastery(of: word).label)
                        .font(.rounded(14, .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    if let unit {
                        Text("\(unit.levelId) · Unit \(unit.number)")
                            .font(.rounded(13, .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                Button {
                    Haptics.tap()
                    store.toggleSaved(word)
                } label: {
                    Label(store.isSaved(word) ? "Đã lưu trong sổ tay" : "Lưu vào sổ tay", systemImage: store.isSaved(word) ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.warning))
            }
            .padding(22)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct MasteryDots: View {
    let level: MasteryLevel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1..<4, id: \.self) { i in
                Capsule()
                    .fill(i <= level.rawValue ? color : Theme.cardRaised)
                    .frame(width: 14, height: 6)
            }
        }
        .accessibilityLabel(level.label)
    }

    private var color: Color {
        switch level {
        case .new: return Theme.cardRaised
        case .learning: return Theme.warning
        case .familiar: return Theme.sky
        case .mastered: return Theme.success
        }
    }
}
