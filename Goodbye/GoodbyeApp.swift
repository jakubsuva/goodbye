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
                // `Text(date, format:)`, so pinning it per call site silently did nothing. The
                // app's copy is English; this makes its dates English too, on a phone set to
                // any region. (Without it, en_US@rg=czzzzz renders "Monday 7. 9.")
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
