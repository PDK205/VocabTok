import SwiftUI

@main
struct VocabTokApp: App {
    @StateObject private var store = ProgressStore()
    @StateObject private var router = Router()
    @AppStorage("theme") private var theme = "system"
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SoundFX.preload()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .preferredColorScheme(theme == "light" ? .light : (theme == "dark" ? .dark : nil))
                .tint(Theme.accent)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.refreshStreak() }
        }
    }
}

struct SessionLaunch: Identifiable {
    let id = UUID()
    let kind: SessionKind
}

final class Router: ObservableObject {
    enum Tab: Hashable { case learn, practice, library, profile }

    @Published var tab: Tab = .learn
    @Published var session: SessionLaunch?

    func start(_ kind: SessionKind) {
        Haptics.tap()
        session = SessionLaunch(kind: kind)
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var router: Router

    var body: some View {
        TabView(selection: $router.tab) {
            PathView()
                .tabItem { Label("Học", systemImage: "map.fill") }
                .tag(Router.Tab.learn)
            PracticeView()
                .tabItem { Label("Luyện tập", systemImage: "dumbbell.fill") }
                .tag(Router.Tab.practice)
            LibraryView()
                .tabItem { Label("Tài liệu", systemImage: "books.vertical.fill") }
                .tag(Router.Tab.library)
            ProfileView()
                .tabItem { Label("Hồ sơ", systemImage: "person.crop.circle.fill") }
                .tag(Router.Tab.profile)
        }
        .fullScreenCover(item: $router.session) { launch in
            LessonView(kind: launch.kind, store: store)
                .environmentObject(store)
                .environmentObject(router)
        }
        .fullScreenCover(isPresented: Binding(get: { !store.data.onboarded }, set: { _ in })) {
            OnboardingView()
                .environmentObject(store)
        }
    }
}
