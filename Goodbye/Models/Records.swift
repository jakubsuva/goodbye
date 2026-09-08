import Foundation

/// One act of letting go: when, and how many things.
///
/// Deliberately not *what*. Recording the item would mean the app asks you to catalogue your own
/// belongings on the way out, which is the opposite of the point — and every screen that showed the
/// item was quietly lying anyway, because the app only ever knew what it had *suggested*.
/// One thing left. That's the whole record.
struct Entry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var count: Int

    init(id: UUID = UUID(), date: Date, count: Int) {
        self.id = id
        self.date = date
        self.count = count
    }
}

struct AppSettings: Codable, Equatable {
    var rhythm: Rhythm = .everyOtherDay
    var startDate: Date = Calendar.current.startOfDay(for: Date())
    var remindersOn = true
    var reminderHour = 19
    var reminderMinute = 0
    var suggestionsOn = true
    /// First run asks one screen's worth of questions, once.
    var hasOnboarded = false
    /// Set the first time something is dragged out. The hint that both ways work shows until then,
    /// then gets out of the way for good.
    var hasTossedByDrag = false

    init() {}

    /// Missing keys fall back to defaults, so files written by older versions keep loading.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        rhythm = try container.decodeIfPresent(Rhythm.self, forKey: .rhythm) ?? defaults.rhythm
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? defaults.startDate
        remindersOn = try container.decodeIfPresent(Bool.self, forKey: .remindersOn) ?? defaults.remindersOn
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour) ?? defaults.reminderHour
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? defaults.reminderMinute
        suggestionsOn = try container.decodeIfPresent(Bool.self, forKey: .suggestionsOn) ?? defaults.suggestionsOn
        hasOnboarded = try container.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? defaults.hasOnboarded
        hasTossedByDrag = try container.decodeIfPresent(Bool.self, forKey: .hasTossedByDrag) ?? defaults.hasTossedByDrag
    }
}
