import Foundation

/// Read-only access to every piece of bundled learning content.
final class ContentStore {
    static let shared = ContentStore()

    let levels: [Level]
    let units: [Unit]
    let lessons: [Lesson]
    let allWords: [Word]
    let allPhrases: [(phrase: Phrase, unitId: String)]

    let tenses: [Tense]
    let phonetics: PhoneticsData?
    let irregularVerbs: [IrregularVerb]
    let guide: Guide?
    let placement: [PlacementItem]

    private let wordsById: [String: Word]
    private let unitsById: [String: Unit]
    private let lessonsById: [String: Lesson]
    private let irregularForms: [String: IrregularVerb]

    private init() {
        var levels: [Level] = []
        for id in ["A1", "A2", "B1", "B2", "C1"] {
            if let level: Level = ContentStore.load(id, subdirectory: nil) {
                levels.append(level)
            }
        }

        // Stamp positions and back-references.
        var unitIndex = 0
        for li in levels.indices {
            levels[li].index = li
            for ui in levels[li].units.indices {
                levels[li].units[ui].levelId = levels[li].id
                levels[li].units[ui].index = unitIndex
                levels[li].units[ui].number = ui + 1
                let unitId = levels[li].units[ui].id
                for wi in levels[li].units[ui].words.indices {
                    levels[li].units[ui].words[wi].unitId = unitId
                }
                unitIndex += 1
            }
        }
        self.levels = levels
        let units = levels.flatMap(\.units)
        self.units = units

        var lessons: [Lesson] = []
        for unit in units {
            for kind in LessonKind.allCases {
                lessons.append(Lesson(unitId: unit.id, kind: kind, order: lessons.count))
            }
        }
        self.lessons = lessons

        let words = units.flatMap(\.words)
        self.allWords = words
        self.allPhrases = units.flatMap { unit in unit.phrases.map { (phrase: $0, unitId: unit.id) } }

        wordsById = Dictionary(words.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        unitsById = Dictionary(units.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        lessonsById = Dictionary(lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        tenses = ContentStore.load("tenses", subdirectory: nil) ?? []
        phonetics = ContentStore.load("phonetics", subdirectory: nil)
        let verbs: [IrregularVerb] = ContentStore.load("irregular_verbs", subdirectory: nil) ?? []
        irregularVerbs = verbs
        guide = ContentStore.load("guide", subdirectory: nil)
        placement = ContentStore.load("placement", subdirectory: nil) ?? []

        var forms: [String: IrregularVerb] = [:]
        for verb in verbs {
            for form in ([verb.base] + verb.past.components(separatedBy: "/") + verb.pp.components(separatedBy: "/")) {
                forms[form.lowercased()] = forms[form.lowercased()] ?? verb
            }
        }
        irregularForms = forms
    }

    private static func load<T: Decodable>(_ name: String, subdirectory: String?) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory)
                ?? Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to decode \(name): \(error)")
            return nil
        }
    }

    // MARK: - Lookups

    func word(id: String) -> Word? { wordsById[id.lowercased()] }
    func unit(id: String) -> Unit? { unitsById[id] }
    func lesson(id: String) -> Lesson? { lessonsById[id] }
    func level(id: String) -> Level? { levels.first { $0.id == id } }

    func level(of unit: Unit) -> Level? { level(id: unit.levelId) }

    func lessons(in unitId: String) -> [Lesson] { lessons.filter { $0.unitId == unitId } }

    func firstUnitIndex(ofLevel levelIndex: Int) -> Int {
        guard levels.indices.contains(levelIndex), let first = levels[levelIndex].units.first else { return 0 }
        return first.index
    }

    /// Finds a course word for a token in running text, handling common inflections.
    func lookup(_ token: String) -> Word? {
        let t = token.lowercased().trimmingCharacters(in: CharacterSet.letters.inverted)
        guard t.count > 1 else { return nil }
        if let w = wordsById[t] { return w }
        var candidates: [String] = []
        let suffixes: [(String, String)] = [("ies", "y"), ("ied", "y"), ("es", ""), ("s", ""), ("ed", ""), ("ed", "e"), ("d", ""), ("ing", ""), ("ing", "e"), ("ly", ""), ("er", ""), ("est", "")]
        for (suffix, replacement) in suffixes where t.hasSuffix(suffix) && t.count > suffix.count + 2 {
            candidates.append(String(t.dropLast(suffix.count)) + replacement)
        }
        // Doubled consonant: stopped -> stop, running -> run
        for c in candidates where c.count > 3 {
            let chars = Array(c)
            if chars[chars.count - 1] == chars[chars.count - 2] { candidates.append(String(chars.dropLast())) }
        }
        if let verb = irregularForms[t] { candidates.append(verb.base) }
        for c in candidates {
            if let w = wordsById[c] { return w }
        }
        return nil
    }

    func irregularVerb(for token: String) -> IrregularVerb? {
        irregularForms[token.lowercased().trimmingCharacters(in: CharacterSet.letters.inverted)]
    }

    /// Deterministic word of the day.
    var wordOfTheDay: Word? {
        guard !allWords.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return allWords[(day * 7) % allWords.count]
    }
}
