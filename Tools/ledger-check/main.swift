// Scenario check of the queue arithmetic and the four rhythms, runnable without Xcode.
// Build command lives in Tools/check.sh.
import Foundation

var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "Europe/Prague")!
func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}
var failures = 0
func expect(_ label: String, _ got: Int, _ want: Int) {
    let ok = got == want
    if !ok { failures += 1 }
    print("\(ok ? "ok  " : "FAIL") \(label): \(got)\(ok ? "" : " (want \(want))")")
}

let monday = day(2026, 9, 7)          // a Monday
let today = day(2026, 9, 7, hour: 18)

// ---------- A. the big clear-out: 31 waiting, 20 at once ----------
var s = AppSettings()
s.rhythm = .everyOtherDay
s.startDate = day(2026, 7, 9)
var entries: [Entry] = []
var l = Ledger.build(entries: entries, settings: s, today: today, calendar: cal)
expect("A due days", l.dueDays.count, 31)
expect("A queue", l.pile, 31)
expect("A today cell", l.dueDays.filter { $0.state == .today }.count, 1)

entries.append(Entry(date: today, count: 20))
l = Ledger.build(entries: entries, settings: s, today: today, calendar: cal)
expect("A queue after 20", l.pile, 11)
// Catching up heals the past: the 20 oldest owed days turn green, 10 stay owed, today is its own.
expect("A caught-up days go green", l.dueDays.filter { $0.state == .done }.count, 20)
expect("A owed matches the queue", l.dueDays.filter { $0.state == .owed }.count, 10)
expect("A today is not owed", l.dueDays.filter { $0.state == .today }.count, 1)
expect("A owed + today == queue",
       l.dueDays.filter { $0.state == .owed || $0.state == .today }.count, l.pile)
expect("A total", l.total, 20)
expect("A extras", l.extras, 0)

entries.append(Entry(date: today, count: 11))
entries.append(Entry(date: today, count: 1))
l = Ledger.build(entries: entries, settings: s, today: today, calendar: cal)
expect("A queue cleared", l.pile, 0)
expect("A nothing owed once cleared", l.dueDays.filter { $0.state == .owed }.count, 0)
expect("A every past day green", l.dueDays.filter { $0.state == .done }.count, 31)
expect("A total 32", l.total, 32)
expect("A extras 1", l.extras, 1)
expect("A can't get ahead (+2d)",
       l.projectedPile(on: cal.date(byAdding: .day, value: 2, to: today)!,
                       settings: s, today: today, calendar: cal), 1)
expect("A nothing due tomorrow",
       l.projectedPile(on: cal.date(byAdding: .day, value: 1, to: today)!,
                       settings: s, today: today, calendar: cal), 0)

// ---------- B. fresh install: first thing due immediately ----------
var b = AppSettings()
b.rhythm = .daily
b.startDate = today
b.hasOnboarded = true
var be: [Entry] = []
var bl = Ledger.build(entries: be, settings: b, today: today, calendar: cal)
expect("B due on install day", bl.pile, 1)
be.append(Entry(date: today, count: 1))
bl = Ledger.build(entries: be, settings: b, today: today, calendar: cal)
expect("B done on the day", bl.dueDays.filter { $0.state == .done }.count, 1)
be.append(Entry(date: today, count: 3))
bl = Ledger.build(entries: be, settings: b, today: today, calendar: cal)
expect("B extras", bl.extras, 3)
expect("B tomorrow still due",
       bl.projectedPile(on: cal.date(byAdding: .day, value: 1, to: today)!,
                        settings: b, today: today, calendar: cal), 1)

// ---------- C. a late entry covers the oldest waiting day, not today's ----------
var c = AppSettings()
c.rhythm = .everyOtherDay
c.startDate = day(2026, 9, 1)  // due 1, 3, 5, 7 Sep
let cl = Ledger.build(entries: [Entry(date: day(2026, 9, 7), count: 1)],
                      settings: c, today: today, calendar: cal)
expect("C queue", cl.pile, 3)
expect("C a late entry greens the oldest", cl.dueDays.first?.state == .done ? 1 : 0, 1)
expect("C today still today", cl.dueDays.last?.state == .today ? 1 : 0, 1)

// ---------- D. the four rhythms over exactly 52 weeks from a Monday ----------
let yearEnd = cal.date(byAdding: .day, value: 363, to: monday)!
for (rhythm, want) in [(Rhythm.daily, 364), (.everyOtherDay, 182), (.twiceAWeek, 104), (.weekly, 52)] {
    let days = rhythm.dueDays(from: monday, through: yearEnd, calendar: cal)
    expect("D \(rhythm.rawValue) over 52 weeks", days.count, want)
}
// The figures onboarding shows, rounded to a calendar year.
for (rhythm, want) in [(Rhythm.daily, 365), (.everyOtherDay, 183), (.twiceAWeek, 104), (.weekly, 52)] {
    expect("D \(rhythm.rawValue) yearlyCount", rhythm.yearlyCount, want)
}
// Twice a week lands on the start weekday and three days later — no hard-coded Monday.
let twice = Rhythm.twiceAWeek.dueDays(from: monday,
                                      through: cal.date(byAdding: .day, value: 13, to: monday)!,
                                      calendar: cal)
expect("D twice-a-week weekdays", Set(twice.map { cal.component(.weekday, from: $0) }).count, 2)
expect("D twice-a-week in a fortnight", twice.count, 4)
let wed = Rhythm.everyOtherDay.nextDueDay(after: today, from: s.startDate, calendar: cal)!
expect("D next due in 2 days",
       cal.dateComponents([.day], from: cal.startOfDay(for: today), to: wed).day!, 2)
expect("D weekly keeps the start weekday",
       cal.component(.weekday, from: Rhythm.weekly.nextDueDay(after: today, from: monday, calendar: cal)!),
       cal.component(.weekday, from: monday))

// ---------- E. the day colour rotates through all eight ----------
var seen = Set<Hue>()
for offset in 0..<8 {
    seen.insert(Hue.forDay(cal.date(byAdding: .day, value: offset, to: monday)!, calendar: cal))
}
expect("E eight colours in eight days", seen.count, 8)
expect("E a suggestion for today", SuggestionBank.lines(for: today, calendar: cal).isEmpty ? 0 : 1, 1)

// ---------- F. the first year as a skeleton ----------
let skeleton = l.firstYear(settings: s, today: today, calendar: cal)
expect("F first-year due days", skeleton.count, 183)
expect("F of which ahead", skeleton.filter { $0.state == .future }.count, 183 - 31)
expect("F nothing ahead is before tomorrow",
       skeleton.filter { $0.state == .future && $0.date <= cal.startOfDay(for: today) }.count, 0)

// ---------- G. the count in the world ----------
expect("G bulk log lands on a milestone", Tally.milestoneCrossed(before: 30, after: 55) ?? 0, 50)
expect("G no milestone twice", Tally.milestoneCrossed(before: 50, after: 51) == nil ? 1 : 0, 1)
// 0 → 34 crosses ten but lands nowhere near it: the comparison line is the honest thing to show.
expect("G overshoot gets none", Tally.milestoneCrossed(before: 0, after: 34) == nil ? 1 : 0, 1)
expect("G big jump landing near does count", Tally.milestoneCrossed(before: 40, after: 104) ?? 0, 100)
expect("G big jump overshooting does not",
       Tally.milestoneCrossed(before: 40, after: 140) == nil ? 1 : 0, 1)

print(failures == 0 ? "\nall good" : "\n\(failures) failure(s)")
exit(failures == 0 ? 0 : 1)
