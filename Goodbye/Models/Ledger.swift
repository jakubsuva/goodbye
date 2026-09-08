import Foundation

/// One due day and what became of it.
struct DueDay: Identifiable, Hashable {
    enum State: Hashable {
        case done     // covered — on the day, or later when you caught up
        case owed     // a past due day you haven't covered yet; these are the queue
        case today    // today's due day, still open
        case future   // hasn't come round yet
    }

    let date: Date
    let state: State
    var id: Date { date }
}

/// The whole arithmetic of the app, derived from entries and settings. Nothing here is stored.
///
/// Entries cover due days oldest-first, and an entry can only cover due days on or before its own
/// date. Whatever an entry has left over after that is an "extra": it counts toward the total,
/// never toward a future due day. That is how you can catch up but not get ahead.
struct Ledger {
    /// Due days from the start through today.
    var dueDays: [DueDay] = []
    /// Due days up to today that nothing has covered yet.
    var pile = 0
    /// Everything ever logged.
    var total = 0
    /// Logged things that didn't cover any due day.
    var extras = 0

    static func build(entries: [Entry], settings: AppSettings, today: Date, calendar: Calendar) -> Ledger {
        let todayDay = calendar.startOfDay(for: today)
        let days = settings.rhythm.dueDays(from: settings.startDate, through: todayDay, calendar: calendar)

        var cursor = 0
        var extras = 0

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let entryDay = calendar.startOfDay(for: entry.date)
            var remaining = entry.count
            while remaining > 0, cursor < days.count, days[cursor] <= entryDay {
                cursor += 1
                remaining -= 1
            }
            extras += remaining
        }

        let dueDays = days.enumerated().map { index, day -> DueDay in
            if index < cursor { return DueDay(date: day, state: .done) }
            if day == todayDay { return DueDay(date: day, state: .today) }
            return DueDay(date: day, state: .owed)
        }

        return Ledger(
            dueDays: dueDays,
            pile: days.count - cursor,
            total: entries.reduce(0) { $0 + $1.count },
            extras: extras
        )
    }

    /// The first year, whole: everything through today from the ledger, then the due days still
    /// ahead as `.future`. This is the skeleton History draws, so the mosaic has its shape from day
    /// one and each thing that goes fills a square that was already waiting for it.
    func firstYear(settings: AppSettings, today: Date, calendar: Calendar) -> [DueDay] {
        let todayDay = calendar.startOfDay(for: today)
        guard let end = calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: settings.startDate)),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: end)
        else { return dueDays }
        // Counted from the real start day, so the rhythm keeps its phase; then only what's ahead.
        let ahead = settings.rhythm.dueDays(from: settings.startDate, through: lastDay, calendar: calendar)
            .filter { $0 > todayDay }
            .map { DueDay(date: $0, state: .future) }
        return dueDays + ahead
    }

    /// The pile on a later day, assuming nothing else gets logged. Used to decide which reminders to schedule.
    func projectedPile(on day: Date, settings: AppSettings, today: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: today)
        let target = calendar.startOfDay(for: day)
        guard target > start else { return pile }
        var count = pile
        var cursor = start
        while let next = calendar.date(byAdding: .day, value: 1, to: cursor), next <= target {
            if settings.rhythm.isDue(next, from: settings.startDate, calendar: calendar) {
                count += 1
            }
            cursor = next
        }
        return count
    }
}
