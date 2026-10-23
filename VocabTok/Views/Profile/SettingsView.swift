import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("dailyGoal") private var dailyGoal = 50
    @AppStorage("accent") private var accent = "en-US"
    @AppStorage("speechRate") private var speechRate = 0.46
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("effectsOn") private var effectsOn = true
    @AppStorage("hapticsOn") private var hapticsOn = true
    @AppStorage("speakingOn") private var speakingOn = true
    @AppStorage("theme") private var theme = "system"
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var name = ""
    @State private var confirmReset = false
    @State private var showPlacement = false
    @State private var permissionDenied = false

    private var reminderDate: Binding<Date> {
        Binding(get: {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
        }, set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderHour = c.hour ?? 20
            reminderMinute = c.minute ?? 0
            if reminderOn { Reminders.schedule(hour: reminderHour, minute: reminderMinute, name: store.data.name) }
        })
    }

    var body: some View {
        Form {
            Section("Cá nhân") {
                HStack {
                    Text("Tên của bạn")
                    TextField("Tên", text: $name)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { store.rename(name) }
                }
                Picker("Mục tiêu mỗi ngày", selection: $dailyGoal) {
                    Text("Thư giãn · 30 XP").tag(30)
                    Text("Bình thường · 50 XP").tag(50)
                    Text("Nghiêm túc · 100 XP").tag(100)
                    Text("Cấp tốc · 150 XP").tag(150)
                }
            }

            Section {
                Toggle("Nhắc học mỗi ngày", isOn: Binding(get: { reminderOn }, set: toggleReminder))
                if reminderOn {
                    DatePicker("Giờ nhắc", selection: reminderDate, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Nhắc nhở")
            } footer: {
                Text(permissionDenied ? "Bạn đã tắt thông báo cho app. Hãy bật lại trong Cài đặt iPhone → VocabTok → Thông báo." : "Một lời nhắc nhẹ mỗi ngày giúp bạn giữ chuỗi học.")
            }

            Section("Giọng đọc & âm thanh") {
                Picker("Giọng", selection: $accent) {
                    Text("🇺🇸 Anh – Mỹ").tag("en-US")
                    Text("🇬🇧 Anh – Anh").tag("en-GB")
                    Text("🇦🇺 Anh – Úc").tag("en-AU")
                }
                VStack(alignment: .leading) {
                    Text("Tốc độ đọc")
                    Slider(value: $speechRate, in: 0.3...0.6, step: 0.02) {
                        Text("Tốc độ")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise.fill")
                    } maximumValueLabel: {
                        Image(systemName: "hare.fill")
                    }
                }
                Button("Nghe thử") { SpeechManager.shared.speak("Hello! Learning English is fun with VocabTok.") }
                Toggle("Tự phát âm khi hiện từ", isOn: $autoPlay)
                Toggle("Giọng đọc", isOn: $soundOn)
                Toggle("Hiệu ứng âm thanh", isOn: $effectsOn)
                Toggle("Rung phản hồi", isOn: $hapticsOn)
            }

            Section {
                Toggle("Bài tập luyện nói", isOn: $speakingOn)
            } footer: {
                Text("Tắt nếu bạn thường học ở nơi không tiện nói to. Bài luyện nói sẽ được thay bằng bài nghe.")
            }

            Section("Giao diện") {
                Picker("Chế độ", selection: $theme) {
                    Text("Tự động").tag("system")
                    Text("Sáng").tag("light")
                    Text("Tối").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("Lộ trình") {
                Button("Làm lại bài kiểm tra xếp lớp") { showPlacement = true }
                if let placement = store.data.placementLevel {
                    HStack {
                        Text("Cấp độ xuất phát")
                        Spacer()
                        Text(placement).foregroundColor(Theme.textSecondary)
                    }
                }
            }

            Section {
                Button("Xoá toàn bộ tiến độ", role: .destructive) { confirmReset = true }
            } footer: {
                Text("VocabTok \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") · \(ContentStore.shared.units.count) unit · \(ContentStore.shared.allWords.count) từ vựng · Học offline hoàn toàn.")
            }
        }
        .navigationTitle("Cài đặt")
        .onAppear { name = store.data.name }
        .onDisappear { if name != store.data.name { store.rename(name) } }
        .confirmationDialog("Xoá toàn bộ tiến độ học?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Xoá tất cả", role: .destructive) { store.resetAll() }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Mọi bài học, từ vựng, XP và thành tích sẽ bị xoá. Không thể hoàn tác.")
        }
        .fullScreenCover(isPresented: $showPlacement) {
            PlacementTestView { levelIndex in
                store.setStartLevel(levelIndex)
                showPlacement = false
            }
        }
    }

    private func toggleReminder(_ on: Bool) {
        if on {
            Reminders.requestPermission { granted in
                permissionDenied = !granted
                reminderOn = granted
                if granted { Reminders.schedule(hour: reminderHour, minute: reminderMinute, name: store.data.name) }
            }
        } else {
            reminderOn = false
            Reminders.cancel()
        }
    }
}
