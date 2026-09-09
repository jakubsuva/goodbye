import Foundation
import UserNotifications

/// Routes a tapped reminder to the Today screen, whatever the app was showing when it went to sleep.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    private let store: Store

    init(store: Store) {
        self.store = store
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            store.wantsToday += 1
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Already looking at the app; a banner would only repeat what's on screen.
        completionHandler([])
    }
}

/// One local notification a day, at the user's hour, only on days when something is waiting.
/// Scheduled two weeks ahead from the current ledger and rebuilt after every change.
enum Reminders {
    /// Only ever called from a moment of intent — finishing onboarding with a nudge switched on,
    /// or switching it on in Settings. Never at launch.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional:
            return true
        default:
            return false
        }
    }

    static func reschedule(settings: AppSettings, ledger: Ledger, calendar: Calendar, now: Date) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard settings.remindersOn, settings.hasOnboarded else { return }

        let today = calendar.startOfDay(for: now)
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let pile = ledger.projectedPile(on: day, settings: settings, today: now, calendar: calendar)
            guard pile > 0 else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = settings.reminderHour
            components.minute = settings.reminderMinute
            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Goodbye"
            content.body = body(for: pile, day: day, calendar: calendar)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "goodbye-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// One line, and for a single thing it borrows the day's suggestion — so the nudge arrives with
    /// somewhere to start rather than just a demand. Internal (not private) so Tools/store-check
    /// can exercise it directly without a real notification center.
    static func body(for pile: Int, day: Date, calendar: Calendar) -> String {
        if pile == 1, let line = SuggestionBank.lines(for: day, calendar: calendar).first {
            return "One thing. How about \(line)?"
        }
        if pile == 1 { return "One thing. Even a small one." }
        return "\(pile) waiting. Even one counts."
    }
}
