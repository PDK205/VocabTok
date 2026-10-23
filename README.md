# VocabTok – Học tiếng Anh A1 → C1

Ứng dụng iOS (SwiftUI, chạy offline hoàn toàn) giúp người Việt học tiếng Anh theo lộ trình CEFR từ A1 đến C1, với phương pháp lặp lại ngắt quãng, chủ động gợi nhớ, luyện nghe – nói – đọc – viết và trò chơi hoá để duy trì động lực.

## Tính năng

**Lộ trình học (tab Học)**
- 5 cấp độ (A1, A2, B1, B2, C1) · 48 unit · 576 từ vựng · 336 bài học
- Mỗi unit có 7 bài: Từ vựng 1, Từ vựng 2, Ngữ pháp, Hội thoại, Đọc hiểu, Luyện nói, Kiểm tra unit
- Mỗi bài nhận 1–3 sao; đạt từ 80% bài kiểm tra để mở unit tiếp theo, có thể kiểm tra vượt unit
- Bài kiểm tra xếp lớp khi bắt đầu để chọn cấp độ phù hợp

**10 dạng bài tập**
Thẻ từ mới (che nghĩa để đoán trước) · chọn nghĩa · chọn từ tiếng Anh · nghe và chọn · điền vào câu · ghép chữ · nghe chép chính tả · sắp xếp câu · ghép cặp · luyện nói có chấm điểm bằng nhận dạng giọng nói. Thêm thẻ ngữ pháp, hội thoại 2 giọng đọc, bài đọc chạm để tra từ.

**Luyện tập**
Ôn tập thông minh (Leitner SRS: 1 → 3 → 7 → 14 → 30 → 60 ngày), Từ hay sai, Nghe chép chính tả, Luyện phát âm, Ghép cặp tốc độ 60 giây, Lướt từ vựng kiểu TikTok, Sổ tay từ vựng.

**Tài liệu**
Lộ trình CEFR & phương pháp học, ngữ pháp theo cấp độ, 12 thì tiếng Anh, bảng phiên âm IPA 44 âm + quy tắc phát âm, 117 động từ bất quy tắc, mẫu câu giao tiếp, từ điển giáo trình.

**Hồ sơ & động lực**
XP và cấp độ, chuỗi ngày học + bảo vệ chuỗi, 3 nhiệm vụ mỗi ngày + rương thưởng, 24 thành tích, biểu đồ XP 7 ngày, nhắc học hằng ngày, giọng Mỹ / Anh / Úc, chỉnh tốc độ đọc, giao diện sáng / tối.

## Cài file IPA

Mỗi lần chạy workflow **Build iOS IPA** (tab Actions → Run workflow) sẽ tạo file `VocabTok.ipa` trong mục Releases. File chưa ký, cài bằng một trong các cách:
- **Sideloadly / AltStore**: ký bằng Apple ID cá nhân (hết hạn sau 7 ngày với tài khoản miễn phí)
- **TrollStore**: cài vĩnh viễn trên các phiên bản iOS được hỗ trợ
- Ký lại bằng chứng chỉ Apple Developer của bạn

Yêu cầu iOS 16 trở lên. Lần đầu dùng bài Luyện nói, app sẽ xin quyền Micro và Nhận dạng giọng nói.

## Chỉnh sửa giáo trình

Nội dung bài học được soạn dạng văn bản dễ đọc trong `content/course/*.txt` (mỗi cấp độ chia 2 file). Sau khi sửa, chạy:

```bash
python3 tools/build_content.py
```

Script sẽ kiểm tra (mỗi unit đủ 12 từ, đáp án nằm trong lựa chọn, không trùng từ giữa các unit...) rồi xuất JSON vào `VocabTok/Resources/Course/`.

Cú pháp một unit:

```
# UNIT a1-u1
title: Chào hỏi & Giới thiệu
titleEn: Greetings & Introductions
emoji: 👋
goal: ...
## words
từ | /ipa/ | loại từ | nghĩa | Câu ví dụ. | Dịch câu ví dụ. | Mẹo nhớ (tuỳ chọn)
## phrases
English phrase | Câu tiếng Việt
## grammar
title: ...
summary: ...
formula: ...
point: Tiêu đề | Nội dung
example: English | Tiếng Việt
mistake: Câu sai | Câu đúng | Giải thích
ex: Câu hỏi có ___ | lựa chọn 1 ; lựa chọn 2 ; lựa chọn 3 | đáp án | giải thích
## dialogue
title: ...
setting: ...
line: A | Tên | English | Tiếng Việt
q: Câu hỏi | a ; b ; c | đáp án
## reading
title: ...
text: ...
vi: ...
q: Câu hỏi | a ; b ; c | đáp án
```

Tài liệu tham khảo (12 thì, IPA, động từ bất quy tắc, phương pháp, bài kiểm tra xếp lớp) nằm trong `VocabTok/Resources/Reference/*.json`.

## Cấu trúc mã nguồn

```
VocabTok/
  App/          Điểm vào app, Router, TabView
  Models/       Model nội dung & tiến độ (SRS, bài học, thống kê ngày)
  Services/     ContentStore, ProgressStore, giọng đọc, nhận dạng giọng nói, âm thanh, nhắc học
  Engine/       Sinh bài tập (LessonEngine), trạng thái bài học, nhiệm vụ & thành tích
  Views/        Path (lộ trình), Lesson (các dạng bài), Practice, Library, Profile, Onboarding
  Resources/    Giáo trình JSON, tài liệu, âm thanh, icon
content/        Nguồn soạn giáo trình
tools/          Script build & kiểm tra giáo trình
```

Build: `brew install xcodegen && xcodegen generate` rồi mở `VocabTok.xcodeproj` bằng Xcode 16+.
