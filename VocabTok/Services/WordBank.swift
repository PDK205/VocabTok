import Foundation

final class WordBank {
    static let shared = WordBank()

    let topics: [Topic]
    let words: [Word]
    private let byId: [String: Word]

    private struct Payload: Codable {
        let topics: [Topic]
        let words: [Word]
    }

    private init() {
        if let url = Bundle.main.url(forResource: "words", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            topics = payload.topics
            words = payload.words
        } else {
            topics = []
            words = []
        }
        byId = Dictionary(words.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    func word(id: String) -> Word? { byId[id] }

    func topic(id: String) -> Topic? { topics.first { $0.id == id } }

    func words(in topicId: String) -> [Word] { words.filter { $0.topic == topicId } }

    /// Deterministic "word of the day".
    var wordOfTheDay: Word? {
        guard !words.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return words[day % words.count]
    }
}
