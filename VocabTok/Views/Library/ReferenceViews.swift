import SwiftUI

// MARK: - Grammar list

struct GrammarListView: View {
    @State private var query = ""
    private let content = ContentStore.shared

    var body: some View {
        List {
            ForEach(content.levels) { level in
                let units = level.units.filter { query.isEmpty || $0.grammar.title.localizedCaseInsensitiveContains(query) || $0.title.localizedCaseInsensitiveContains(query) }
                if !units.isEmpty {
                    Section {
                        ForEach(units) { unit in
                            NavigationLink {
                                ScrollView {
                                    GrammarContentView(grammar: unit.grammar).padding(18)
                                }
                                .background(Theme.background.ignoresSafeArea())
                                .navigationTitle("\(level.id) · Unit \(unit.number)")
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(unit.grammar.title)
                                        .font(.rounded(15, .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Unit \(unit.number) · \(unit.emoji) \(unit.title)")
                                        .font(.rounded(12, .medium))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    } header: {
                        Text("\(level.emoji) \(level.id) · \(level.name)")
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Tìm chủ điểm ngữ pháp")
        .navigationTitle("Ngữ pháp")
    }
}

// MARK: - Tenses

struct TensesView: View {
    private let content = ContentStore.shared

    var body: some View {
        List {
            ForEach(["Hiện tại", "Quá khứ", "Tương lai"], id: \.self) { group in
                Section(group) {
                    ForEach(content.tenses.filter { $0.group == group }) { tense in
                        NavigationLink {
                            TenseDetailView(tense: tense)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tense.nameVi)
                                    .font(.rounded(16, .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(tense.name) · \(tense.affirmative)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .navigationTitle("12 thì tiếng Anh")
    }
}

struct TenseDetailView: View {
    let tense: Tense

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tense.nameVi)
                        .font(.rounded(28, .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(tense.name)
                        .font(.rounded(15, .semibold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("CÔNG THỨC", systemImage: "function")
                        .font(.rounded(12, .heavy))
                        .foregroundColor(Theme.accent)
                    formulaRow("Khẳng định", tense.affirmative, Theme.success)
                    formulaRow("Phủ định", tense.negative, Theme.danger)
                    formulaRow("Câu hỏi", tense.question, Theme.sky)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                VStack(alignment: .leading, spacing: 10) {
                    Label("CÁCH DÙNG", systemImage: "checklist")
                        .font(.rounded(12, .heavy))
                        .foregroundColor(Theme.warning)
                    ForEach(tense.usage, id: \.self) { usage in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill").font(.system(size: 6)).padding(.top, 7).foregroundColor(Theme.warning)
                            Text(usage).font(.rounded(15, .medium)).foregroundColor(Theme.textPrimary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                VStack(alignment: .leading, spacing: 10) {
                    Label("DẤU HIỆU NHẬN BIẾT", systemImage: "eye.fill")
                        .font(.rounded(12, .heavy))
                        .foregroundColor(Theme.pink)
                    FlowLayout(spacing: 6, lineSpacing: 6) {
                        ForEach(tense.signals, id: \.self) { signal in
                            Chip(text: signal, color: Theme.pink)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Label("VÍ DỤ", systemImage: "text.quote")
                        .font(.rounded(12, .heavy))
                        .foregroundColor(Theme.sky)
                    ForEach(tense.examples) { example in
                        ExampleRow(en: example.en, vi: example.vi)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                if let note = tense.note {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill").foregroundColor(Theme.warning)
                        Text(note).font(.rounded(14, .medium)).foregroundColor(Theme.textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.warning.opacity(0.12)))
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formulaRow(_ label: String, _ formula: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.rounded(12, .bold)).foregroundColor(color)
            Text(formula)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(0.1)))
        }
    }
}

// MARK: - Phonetics

struct PhoneticsView: View {
    private let data = ContentStore.shared.phonetics
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]
    @State private var selected: PhoneticSound?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let data {
                    Text(data.intro)
                        .font(.rounded(14, .medium))
                        .foregroundColor(Theme.textSecondary)
                    ForEach(data.groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: group.title, subtitle: group.subtitle)
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(group.sounds) { sound in
                                    Button {
                                        Haptics.tap()
                                        selected = sound
                                        if let first = sound.examples.first { SpeechManager.shared.speak(first) }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text("/\(sound.symbol)/")
                                                .font(.system(size: 26, weight: .bold))
                                                .foregroundColor(Theme.accent)
                                            Text(sound.examples.prefix(2).joined(separator: ", "))
                                                .font(.rounded(12, .semibold))
                                                .foregroundColor(Theme.textSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                    }
                    SectionHeader(title: "Quy tắc phát âm quan trọng")
                    ForEach(data.rules, id: \.self) { rule in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(rule.title).font(.rounded(16, .bold)).foregroundColor(Theme.textPrimary)
                            Text(rule.body)
                                .font(.rounded(14, .medium))
                                .foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card(padding: 16)
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Bảng phiên âm IPA")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { sound in
            SoundDetailSheet(sound: sound)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct SoundDetailSheet: View {
    let sound: PhoneticSound

    var body: some View {
        VStack(spacing: 18) {
            Text("/\(sound.symbol)/")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(sound.tip)
                .font(.rounded(15, .medium))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                ForEach(sound.examples, id: \.self) { example in
                    Button {
                        SpeechManager.shared.speak(example)
                    } label: {
                        Label(example, systemImage: "speaker.wave.2.fill")
                            .font(.rounded(16, .bold))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Theme.accent.opacity(0.12)))
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Irregular verbs

struct IrregularVerbsView: View {
    @State private var query = ""
    private let verbs = ContentStore.shared.irregularVerbs.sorted { $0.base < $1.base }

    private var filtered: [IrregularVerb] {
        guard !query.isEmpty else { return verbs }
        let q = query.lowercased()
        return verbs.filter { $0.base.contains(q) || $0.past.contains(q) || $0.pp.contains(q) || $0.vi.lowercased().contains(q) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("V1").frame(maxWidth: .infinity, alignment: .leading)
                    Text("V2").frame(maxWidth: .infinity, alignment: .leading)
                    Text("V3").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.rounded(12, .heavy))
                .foregroundColor(Theme.accent)
                ForEach(filtered) { verb in
                    Button {
                        SpeechManager.shared.speak("\(verb.base), \(verb.past.replacingOccurrences(of: "/", with: ", ")), \(verb.pp.replacingOccurrences(of: "/", with: ", "))")
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(verb.base).frame(maxWidth: .infinity, alignment: .leading)
                                Text(verb.past).frame(maxWidth: .infinity, alignment: .leading)
                                Text(verb.pp).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.rounded(15, .bold))
                            .foregroundColor(Theme.textPrimary)
                            Text(verb.vi)
                                .font(.rounded(12, .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            } footer: {
                Text("Chạm vào một dòng để nghe cả 3 dạng của động từ.")
            }
        }
        .searchable(text: $query, prompt: "Tìm động từ hoặc nghĩa")
        .navigationTitle("Động từ bất quy tắc")
    }
}

// MARK: - Phrasebook

struct PhrasebookView: View {
    @State private var query = ""
    private let content = ContentStore.shared

    var body: some View {
        List {
            ForEach(content.units) { unit in
                let phrases = unit.phrases.filter { query.isEmpty || $0.en.localizedCaseInsensitiveContains(query) || $0.vi.localizedCaseInsensitiveContains(query) }
                if !phrases.isEmpty {
                    Section("\(unit.emoji) \(unit.levelId) · \(unit.title)") {
                        ForEach(phrases) { phrase in
                            Button {
                                SpeechManager.shared.speak(phrase.en)
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(phrase.en)
                                            .font(.rounded(15, .bold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text(phrase.vi)
                                            .font(.rounded(13, .medium))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(Theme.accent)
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Tìm mẫu câu (Anh hoặc Việt)")
        .navigationTitle("Mẫu câu giao tiếp")
    }
}

// MARK: - Dictionary

struct DictionaryView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var query = ""
    @State private var selected: Word?
    private let content = ContentStore.shared

    private var results: [Word] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return content.allWords.filter { $0.word.lowercased().hasPrefix(q) || $0.vi.lowercased().contains(q) }
            .sorted { a, b in
                let aStarts = a.word.lowercased().hasPrefix(q)
                let bStarts = b.word.lowercased().hasPrefix(q)
                if aStarts != bStarts { return aStarts }
                return a.word < b.word
            }
    }

    var body: some View {
        List {
            if query.isEmpty {
                ForEach(content.levels) { level in
                    Section("\(level.emoji) \(level.id) · \(level.name)") {
                        ForEach(level.units) { unit in
                            DisclosureGroup("\(unit.emoji) Unit \(unit.number): \(unit.title)") {
                                ForEach(unit.words) { word in
                                    Button { selected = word } label: {
                                        WordRow(word: word, mastery: store.mastery(of: word))
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets())
                                }
                            }
                            .font(.rounded(15, .semibold))
                        }
                    }
                }
            } else if results.isEmpty {
                EmptyStateView(emoji: "🔍", title: "Không tìm thấy", message: "Thử tìm bằng từ tiếng Anh hoặc nghĩa tiếng Việt khác.")
                    .listRowBackground(Color.clear)
            } else {
                ForEach(results) { word in
                    Button { selected = word } label: {
                        WordRow(word: word, mastery: store.mastery(of: word))
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .searchable(text: $query, prompt: "Tìm từ tiếng Anh hoặc nghĩa tiếng Việt")
        .navigationTitle("Từ điển")
        .sheet(item: $selected) { word in
            WordDetailSheet(word: word).presentationDetents([.medium, .large])
        }
    }
}
