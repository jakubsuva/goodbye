import Foundation

/// How often a thing is due. Due days are computed from the start date; nothing is stored per day,
/// so changing the rhythm never breaks history — it just recolours it.
///
/// All four are plain arithmetic on days elapsed since the start day, which means no hard-coded
/// weekdays: a weekly rhythm lands on whichever weekday you happened to begin on.
enum Rhythm: String, Codable, CaseIterable, Identifiable {
    case daily
    case everyOtherDay
    case twiceAWeek
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Every day"
        case .everyOtherDay: return "Every other day"
        case .twiceAWeek: return "Twice a week"
        case .weekly: return "Once a week"
        }
    }

    /// Lower case, because in onboarding these complete the sentence “One thing leaves the flat…”.
    var phrase: String {
        switch self {
        case .daily: return "every day"
        case .everyOtherDay: return "every other day"
        case .twiceAWeek: return "twice a week"
        case .weekly: return "once a week"
        }
    }

    /// Shown next to the date on the Today screen.
    var shortTitle: String { phrase }

    /// Due days in a year — the number that makes the choice concrete during onboarding.
    var yearlyCount: Int {
        switch self {
        case .daily: return 365
        case .everyOtherDay: return 183
        case .twiceAWeek: return 104
        case .weekly: return 52
        }
    }

    /// One line of counsel per rhythm. Daily talks you down on purpose: enthusiasm on day one and
    /// a broken run on day four is how this habit actually dies.
    var counsel: String {
        switch self {
        case .daily: return "365 is a lot. Start slower — speeding up is easy, starting again isn't."
        case .everyOtherDay: return "Enough to notice. Rare enough to keep."
        case .twiceAWeek: return "Two evenings a week, always the same two."
        case .weekly: return "Gentle. The same day each week adds up anyway."
        }
    }

    /// Whether `day` is a due day, counting from `start`. Only calendar days matter, never times.
    func isDue(_ day: Date, from start: Date, calendar: Calendar) -> Bool {
        guard let elapsed = daysSinceStart(day, from: start, calendar: calendar) else { return false }
        switch self {
        case .daily: return true
        case .everyOtherDay: return elapsed % 2 == 0
        case .twiceAWeek: return elapsed % 7 == 0 || elapsed % 7 == 3
        case .weekly: return elapsed % 7 == 0
        }
    }

    /// Every due day from `start` through `end`, inclusive, as start-of-day dates in ascending order.
    func dueDays(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            if isDue(day, from: start, calendar: calendar) {
                result.append(day)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The first due day strictly after `day`, if there is one within two weeks.
    func nextDueDay(after day: Date, from start: Date, calendar: Calendar) -> Date? {
        var candidate = calendar.startOfDay(for: day)
        for _ in 0..<14 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { return nil }
            candidate = next
            if isDue(candidate, from: start, calendar: calendar) {
                return candidate
            }
        }
        return nil
    }

    /// Whole days from the start day to `day`, or nil if `day` is before the start.
    private func daysSinceStart(_ day: Date, from start: Date, calendar: Calendar) -> Int? {
        let first = calendar.startOfDay(for: start)
        let target = calendar.startOfDay(for: day)
        guard target >= first,
              let elapsed = calendar.dateComponents([.day], from: first, to: target).day
        else { return nil }
        return elapsed
    }
}
