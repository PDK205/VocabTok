import Foundation

struct VocabularyWord: Identifiable, Hashable {
    let id: UUID = UUID()
    let word: String
    let phonetic: String
    let partOfSpeech: String
    let meaningVi: String
    let exampleEn: String
    let exampleVi: String
    let memoryTip: String
}

struct QuizQuestion: Identifiable {
    let id: UUID = UUID()
    let word: VocabularyWord
    let options: [String]
    let correctAnswer: String
    var selectedAnswer: String? = nil

    var isCorrect: Bool {
        selectedAnswer == correctAnswer
    }
}

struct VocabularyBank {
    static let words: [VocabularyWord] = [
        VocabularyWord(word: "Resilient", phonetic: "/rɪˈzɪl.jənt/", partOfSpeech: "adj", meaningVi: "Kiên cường, mau phục hồi", exampleEn: "She is resilient and never gives up.", exampleVi: "Cô ấy kiên cường và không bao giờ bỏ cuộc.", memoryTip: "Như chiếc lò xo: nén xuống rồi lại bật lên."),
        VocabularyWord(word: "Persevere", phonetic: "/ˌpɜː.sɪˈvɪər/", partOfSpeech: "verb", meaningVi: "Kiên trì, bền chí", exampleEn: "You will succeed if you persevere.", exampleVi: "Bạn sẽ thành công nếu kiên trì đến cùng.", memoryTip: "Per-severe: vượt qua sự khắc nghiệt (severe)."),
        VocabularyWord(word: "Serendipity", phonetic: "/ˌser.ənˈdɪp.ə.ti/", partOfSpeech: "noun", meaningVi: "Sự tình cờ may mắn", exampleEn: "Meeting you was pure serendipity.", exampleVi: "Gặp bạn là một sự may mắn tình cờ.", memoryTip: "Đi tìm đá cuội mà nhặt được viên kim cương."),
        VocabularyWord(word: "Diligent", phonetic: "/ˈdɪl.ɪ.dʒənt/", partOfSpeech: "adj", meaningVi: "Chăm chỉ, siêng năng", exampleEn: "Diligent practice makes perfection.", exampleVi: "Luyện tập chăm chỉ tạo nên sự hoàn hảo.", memoryTip: "Trái nghĩa với 'lazy'."),
        VocabularyWord(word: "Eloquent", phonetic: "/ˈel.ə.kwənt/", partOfSpeech: "adj", meaningVi: "Lưu loát, hùng biện", exampleEn: "His speech was remarkably eloquent.", exampleVi: "Bài phát biểu của anh ấy lưu loát đáng kinh ngạc.", memoryTip: "Gốc từ 'loqu' liên quan đến khả năng nói."),
        VocabularyWord(word: "Inevitable", phonetic: "/ɪnˈev.ɪ.tə.bəl/", partOfSpeech: "adj", meaningVi: "Không thể tránh khỏi", exampleEn: "Change is an inevitable part of life.", exampleVi: "Thay đổi là điều tất yếu trong cuộc sống.", memoryTip: "In (không) + evitable (có thể tránh)."),
        VocabularyWord(word: "Ambiguous", phonetic: "/æmˈbɪɡ.ju.əs/", partOfSpeech: "adj", meaningVi: "Mơ hồ, nước đôi", exampleEn: "His answer was too ambiguous.", exampleVi: "Câu trả lời của anh ấy quá mơ hồ.", memoryTip: "Ambi: hai phía, nói không rõ lập trường."),
        VocabularyWord(word: "Pragmatic", phonetic: "/præɡˈmæt.ɪk/", partOfSpeech: "adj", meaningVi: "Thực tế, thực dụng", exampleEn: "We need a pragmatic approach.", exampleVi: "Chúng ta cần một cách tiếp cận thực tế.", memoryTip: "Tập trung hành động thực tiễn hơn là lý thuyết."),
        VocabularyWord(word: "Metaphor", phonetic: "/ˈmet.ə.fɔːr/", partOfSpeech: "noun", meaningVi: "Phép ẩn dụ", exampleEn: "Time is money is a metaphor.", exampleVi: "Thời gian là vàng bạc là một phép ẩn dụ.", memoryTip: "So sánh ngầm hai sự vật với nhau."),
        VocabularyWord(word: "Ephemeral", phonetic: "/ɪˈfem.ər.əl/", partOfSpeech: "adj", meaningVi: "Phù du, chóng tàn", exampleEn: "Fame can be ephemeral.", exampleVi: "Danh vọng có thể rất phù du.", memoryTip: "Giống như cầu vồng, xuất hiện rồi biến mất."),
        VocabularyWord(word: "Empower", phonetic: "/ɪmˈpaʊ.ər/", partOfSpeech: "verb", meaningVi: "Trao quyền, tiếp sức mạnh", exampleEn: "Education empowers people.", exampleVi: "Giáo dục tiếp thêm sức mạnh cho con người.", memoryTip: "Em + Power: nạp năng lượng/sức mạnh."),
        VocabularyWord(word: "Lucid", phonetic: "/ˈluː.sɪd/", partOfSpeech: "adj", meaningVi: "Rõ ràng, minh bạch", exampleEn: "She gave a lucid explanation.", exampleVi: "Cô ấy giải thích rất rõ ràng, sáng tỏ.", memoryTip: "Lucid dream: giấc mơ sáng rõ."),
        VocabularyWord(word: "Tenacious", phonetic: "/təˈneɪ.ʃəs/", partOfSpeech: "adj", meaningVi: "Ngoan cường, dai dẳng", exampleEn: "He has a tenacious grip on his dream.", exampleVi: "Anh ấy kiên quyết bám chặt lấy ước mơ.", memoryTip: "Giữ chặt không chịu buông tay."),
        VocabularyWord(word: "Compassion", phonetic: "/kəmˈpæʃ.ən/", partOfSpeech: "noun", meaningVi: "Lòng trắc ẩn, từ bi", exampleEn: "Show compassion to those in need.", exampleVi: "Hãy thể hiện lòng thương xót với người khó khăn.", memoryTip: "Thấu hiểu và cảm thông sâu sắc."),
        VocabularyWord(word: "Versatile", phonetic: "/ˈvɜː.sə.taɪl/", partOfSpeech: "adj", meaningVi: "Linh hoạt, đa năng", exampleEn: "He is a versatile actor.", exampleVi: "Anh ấy là một diễn viên đa năng.", memoryTip: "Có thể thích nghi trong nhiều hoàn cảnh.")
    ]
}