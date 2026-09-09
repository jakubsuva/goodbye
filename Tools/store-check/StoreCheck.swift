// Scenario check of Store's persistence/backward-compat behaviour and Reminders' pure body(for:)
// string logic, runnable without Xcode. Build command lives in Tools/check.sh.
//
// @MainActor on the whole entry point (rather than sprinkling `await`) because Store is a
// @MainActor class end to end — everything here runs synchronously on that one actor.
import Foundation

var failures = 0
func expect(_ label: String, _ got: Bool) {
    print("\(got ? "ok  " : "FAIL") \(label)")
    if !got { failures += 1 }
}

@main
@MainActor
struct StoreCheck {
    static func main() {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "goodbye-store-check-\(UUID().uuidString)", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // ---------- A. old-format snapshot: keys added since this file could have been written ----------
        let oldURL = dir.appending(path: "old.json")
        let oldJSON = """
        {"entries":[{"id":"9B1F0B4E-3D0E-4B2E-9C3E-000000000001","date":"2026-01-05T09:00:00Z","count":1}],
         "settings":{"rhythm":"everyOtherDay","startDate":"2026-01-01T00:00:00Z",
         "remindersOn":true,"reminderHour":19,"reminderMinute":0,"hasOnboarded":true}}
        """
        try! Data(oldJSON.utf8).write(to: oldURL)
        let old = Store.load(from: oldURL)
        expect("A old snapshot: entry decoded", old.entries.count == 1)
        expect("A old snapshot: missing hasTossedByDrag defaults false", old.settings.hasTossedByDrag == false)
        expect("A old snapshot: missing suggestionsOn defaults true", old.settings.suggestionsOn == true)
        expect("A old snapshot: existing keys still read", old.settings.rhythm == .everyOtherDay)

        // ---------- B. corrupt file: must not crash, falls back to an empty store ----------
        let corruptURL = dir.appending(path: "corrupt.json")
        try! Data("not json at all".utf8).write(to: corruptURL)
        let corrupt = Store.load(from: corruptURL)
        expect("B corrupt file: falls back to empty entries", corrupt.entries.isEmpty)
        expect("B corrupt file: falls back to default settings", corrupt.settings.hasOnboarded == false)

        // ---------- C. a missing file behaves the same as corrupt: defaults, no crash ----------
        let missingURL = dir.appending(path: "does-not-exist.json")
        let missing = Store.load(from: missingURL)
        expect("C missing file: falls back to empty store", missing.entries.isEmpty)

        // ---------- D. round-trip: log something, save, reload from the same URL ----------
        let roundTripURL = dir.appending(path: "roundtrip.json")
        let original = Store.load(from: roundTripURL)
        _ = original.log(3)
        original.save()
        let reloaded = Store.load(from: roundTripURL)
        expect("D round-trip: entry survives save+load", reloaded.entries.count == 1)
        expect("D round-trip: count survives", reloaded.entries.first?.count == 3)

        // ---------- E. Store.log guards against non-positive counts ----------
        let guardStore = Store(fileURL: dir.appending(path: "guard.json"))
        expect("E log(0) is rejected", guardStore.log(0) == nil)
        expect("E log(-1) is rejected", guardStore.log(-1) == nil)
        expect("E rejected logs don't append an entry", guardStore.entries.isEmpty)

        try? FileManager.default.removeItem(at: dir)

        // ---------- F. Reminders.body(for:): singular-with-suggestion, singular, plural ----------
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Prague")!
        let day = cal.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 12))!
        let single = Reminders.body(for: 1, day: day, calendar: cal)
        expect("F body(pile: 1) borrows a suggestion", single.contains("How about"))
        let plural = Reminders.body(for: 3, day: day, calendar: cal)
        expect("F body(pile: 3) is plural, no borrowed suggestion", plural == "3 waiting. Even one counts.")

        print(failures == 0 ? "\nall good" : "\n\(failures) failure(s)")
        exit(failures == 0 ? 0 : 1)
    }
}
