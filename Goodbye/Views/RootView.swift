import SwiftUI

enum Route: Hashable {
    case history
    case settings
}

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var path = NavigationPath()

    var body: some View {
        if store.settings.hasOnboarded {
            NavigationStack(path: $path) {
                TodayView()
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            NavigationLink(value: Route.history) {
                                Label("History", systemImage: "square.grid.3x3")
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            NavigationLink(value: Route.settings) {
                                Label("Settings", systemImage: "gearshape")
                            }
                        }
                    }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .history: HistoryView()
                        case .settings: SettingsView()
                        }
                    }
            }
            .tint(store.todayHue.deep)
            // A tapped reminder lands on Today with the card ready, whatever was open before.
            .onChange(of: store.wantsToday) { _, _ in
                path = NavigationPath()
            }
            .transition(.opacity)
        } else {
            OnboardingView()
                .transition(.opacity)
        }
    }
}
