import SwiftUI

@main
struct VocabTokApp: App {
    @StateObject private var store = ProgressStore()
    @AppStorage("theme") private var theme = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(theme == "light" ? .light : theme == "dark" ? .dark : nil)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var lesson: LessonLaunch? = nil

    var body: some View {
        TabView {
            HomeView(startLesson: start)
                .tabItem { Label("Học", systemImage: "graduationcap.fill") }
            TopicsView(startLesson: start)
                .tabItem { Label("Chủ đề", systemImage: "square.grid.2x2.fill") }
            ProfileView()
                .tabItem { Label("Tiến độ", systemImage: "chart.bar.fill") }
        }
        .fullScreenCover(item: $lesson) { launch in
            LessonView(mode: launch.mode, store: store)
        }
    }

    private func start(_ mode: LessonMode) {
        Haptics.tap()
        lesson = LessonLaunch(mode: mode)
    }
}

struct LessonLaunch: Identifiable {
    let id = UUID()
    let mode: LessonMode
}
