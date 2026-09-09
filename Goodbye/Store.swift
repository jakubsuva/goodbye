import Foundation
import Observation

/// Everything the app knows, in one place: entries, settings, and "now". Persisted as one JSON file.
@MainActor
@Observable
final class Store {
    var entries: [Entry] = []
    var settings = AppSettings()
    /// The app's idea of the current moment. Refreshed when the app becomes active.
    var now = Date()
    /// Bumped when a reminder is tapped, so Today comes forward whatever was on screen.
    var wantsToday = 0
    let calendar = Calendar.current

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Derived

    var ledger: Ledger {
        Ledger.build(entries: entries, settings: settings, today: now, calendar: calendar)
    }

    /// The colour of the day. Rotates daily; means nothing beyond that.
    var todayHue: Hue {
        Hue.forDay(now, calendar: calendar)
    }

    var lastEntry: Entry? {
        entries.max(by: { $0.date < $1.date })
    }

    /// Whether anything went out today. The farewell belongs to the moment you let something go,
    /// so on a day you didn't, the app has no business saying it.
    var didLogToday: Bool {
        guard let last = lastEntry else { return false }
        return calendar.isDate(last.date, inSameDayAs: now)
    }

    /// The round number the most recent entry carried the total past, if it did so today.
    var milestoneCrossedToday: Int? {
        guard let last = lastEntry, calendar.isDate(last.date, inSameDayAs: now) else { return nil }
        let total = ledger.total
        return Tally.milestoneCrossed(before: total - last.count, after: total)
    }

    // MARK: - Actions

    @discardableResult
    func log(_ count: Int) -> Entry? {
        guard count > 0 else { return nil }
        let entry = Entry(date: Date(), count: count)
        entries.append(entry)
        refreshNow()
        persist()
        return entry
    }

    /// The only way back: the undo that rides along with the toast.
    func delete(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&settings)
        settingsChanged()
    }

    func settingsChanged() {
        persist()
    }

    func refreshNow() {
        now = Date()
    }

    // MARK: - First run

    /// Writes the one screen's worth of answers, then asks for notification permission — in context,
    /// right after the user said they want a nudge, rather than cold at launch.
    func completeOnboarding(rhythm: Rhythm, remindersOn: Bool, hour: Int, minute: Int) async {
        refreshNow()
        settings.rhythm = rhythm
        settings.remindersOn = remindersOn
        settings.reminderHour = hour
        settings.reminderMinute = minute
        // Start day = install day = a due day, so the first thing is waiting immediately.
        settings.startDate = calendar.startOfDay(for: now)
        settings.hasOnboarded = true
        save()

        if remindersOn {
            let granted = await Reminders.requestAuthorization()
            if !granted {
                settings.remindersOn = false
                save()
                return
            }
        }
        await syncReminders()
    }

    // MARK: - Reminders

    /// Called when the Settings toggle is switched on, so the prompt again lands on intent.
    func enableReminders() async {
        let granted = await Reminders.requestAuthorization()
        settings.remindersOn = granted
        save()
        await syncReminders()
    }

    func syncReminders() async {
        await Reminders.reschedule(settings: settings, ledger: ledger, calendar: calendar, now: now)
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var entries: [Entry]
        var settings: AppSettings
    }

    /// `url` is injectable so tests can point at a temp file instead of the real Application
    /// Support data — see Tools/store-check.
    static func load(from url: URL = defaultFileURL()) -> Store {
        let store = Store(fileURL: url)
        if let data = try? Data(contentsOf: url),
           let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            store.entries = snapshot.entries
            store.settings = snapshot.settings
        }
        return store
    }

    private func persist() {
        save()
        Task { await syncReminders() }
    }

    func save() {
        do {
            let data = try Self.encoder.encode(Snapshot(entries: entries, settings: settings))
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Goodbye: save failed — \(error)")
        }
    }

    /// Writes the same JSON to a temporary file for sharing.
    func exportURL() throws -> URL {
        let data = try Self.encoder.encode(Snapshot(entries: entries, settings: settings))
        let url = FileManager.default.temporaryDirectory.appending(path: "Goodbye export.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    nonisolated static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appending(path: "Goodbye", directoryHint: .isDirectory)
            .appending(path: "data.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
