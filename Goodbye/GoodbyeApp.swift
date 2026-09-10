import SwiftUI
import UserNotifications

@main
struct GoodbyeApp: App {
    @State private var store: Store
    @Environment(\.scenePhase) private var scenePhase
    private let router: NotificationRouter

    init() {
        let store = Store.load()
        _store = State(initialValue: store)
        router = NotificationRouter(store: store)
        UNUserNotificationCenter.current().delegate = router
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                // SwiftUI overrides a format style's own locale with the environment's for
                // `Text(date, format:)`, so pinning per call site does nothing — see
                // Theme.dateLocale. Derived from the app's resolved language, not hard-coded, so
                // this keeps working now that the app is localized rather than English-only.
                .environment(\.locale, Theme.dateLocale)
                // Parked, not removed — see Theme.forcedColorScheme.
                .preferredColorScheme(Theme.forcedColorScheme)
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back after midnight must move "today" along; nothing else needs a timer.
            if phase == .active {
                store.refreshNow()
            }
        }
    }
}
