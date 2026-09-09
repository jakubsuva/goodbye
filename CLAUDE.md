# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Goodbye: a personal iOS 17+ SwiftUI app, no server, no account. Every other day (or whatever
rhythm is chosen), one thing leaves. `README.md` is the source of truth for the design system
(colour/type rules) and the product's own reasoning about itself ("what's not in it, on purpose") —
read it before UI or product changes rather than duplicating it here.

## Commands

- **Regenerate the Xcode project** (after editing `project.yml`, or if the project file won't open):
  `brew install xcodegen && xcodegen`
- **Verify without Xcode**: `./Tools/check.sh` — typechecks every file in `Goodbye/` against the
  macOS SDK, then builds and runs the scenario tests in `Tools/ledger-check/main.swift` (the queue
  arithmetic and all four rhythms). There's no per-test filter — it's one binary; to check a single
  scenario, add or edit an `expect(...)` call there and rerun the script.
- **Run in the Simulator**: `open Goodbye.xcodeproj`, scheme `Goodbye`, any iPhone destination, Run.
  Bundle id is `com.jakubsuva.goodbye`. When driving the simulator directly (e.g. via the iOS
  Simulator MCP tool) instead of Xcode: `simctl launch` runs the binary already **installed**, so a
  rebuild without a `simctl install` first will launch stale code.
- **Pin the day's colour** (otherwise the only way to see a `Hue` besides today's is to wait):
  `SIMCTL_CHILD_GOODBYE_HUE=<sun|sky|mint|coral|violet|teal|pink|lime> xcrun simctl launch <udid> com.jakubsuva.goodbye`
  (debug builds only).
- **Contact sheet** of simulator screenshots, one view instead of ten launches:
  `swift Tools/contact-sheet.swift <out.png> <cols> <label=file.png> ...`
- **Audit SF Symbols** the app references (catches a bad name or an inverted-convention symbol):
  `swift Tools/symbol-audit.swift <out.png> <name> ...`
- **Regenerate the app icon**: `swift Tools/make-icon.swift Goodbye/Assets.xcassets/AppIcon.appiconset`

## Architecture

### Single source of truth, everything else derived

`Store` (`@Observable`, `@MainActor`, `Goodbye/Store.swift`) holds only `entries: [Entry]` and
`settings: AppSettings`, persisted as one JSON snapshot at
`Application Support/Goodbye/data.json`. Every number the app shows — the queue, the running
total, the History mosaic — is recomputed on demand from `entries` + `settings` + "now", never
stored. `Ledger.build(...)` is the one function that does this; it's pure and takes `today`/
`calendar` as parameters, which is what makes it testable from `Tools/ledger-check`.

### The queue arithmetic (`Ledger` + `Rhythm`)

- `Rhythm` (daily / everyOtherDay / twiceAWeek / weekly) is pure arithmetic on days-elapsed-since-
  `settings.startDate` — no stored per-day state, no hardcoded weekdays. Changing the rhythm or the
  start date never breaks history; `Ledger.build` just recomputes `dueDays` from scratch on the fly.
- `Ledger.build` walks entries oldest-first and lets each one cover due days on or before its own
  date only, in order. Whatever's left over after covering is `extras`: it counts toward `total`
  but can never cover a future due day. That's the "catch up, never get ahead" rule — don't touch
  this loop without rerunning `Tools/check.sh`.
- `Ledger.firstYear(...)` extends `dueDays` with `.future` entries through the first anniversary of
  `startDate` — that's the skeleton `HistoryView`'s mosaic renders from day one, before anything's
  logged.

### `Hue`: the colour of the day, not a category

`Hue` (sun/sky/mint/coral/violet/teal/pink/lime, `Models/Hue.swift`) is derived purely from the
calendar's ordinal day (`Hue.forDay`), two tones each (`bright` fills shapes, `deep` carries text,
paired with `Theme.onBright`/`Theme.onDeep`). This used to be `Zone`, a household room that also
tagged each entry and grouped suggestions — that coupling is gone. A `Hue` means nothing beyond
"today looks different from yesterday", and `Entry` carries no colour or category at all.

### What `Entry` deliberately doesn't record

`Entry` (`Models/Records.swift`) is only `(id, date, count)` — no item name, no room, no note.
Two previously-built features (a per-toss farewell note, room tagging) were removed on purpose: the
app only ever knew what it had *suggested*, never what actually left, so any screen that displayed
"what left" was quietly lying. Don't reintroduce a field here without reintroducing that problem.

### View tree

`RootView` switches on `settings.hasOnboarded` between `OnboardingView` (single-screen first run,
ends by calling `Store.completeOnboarding`) and a `NavigationStack(TodayView)` with History/Settings
pushed via `Route`. `TodayView` is the one screen most sessions see: drag-to-toss or tap "Gone",
`LogSeveralSheet` for a bulk clear-out, an inline undo toast. `HistoryView` renders
`Ledger.firstYear` as a mosaic grid (done/owed/future) with no item list, by design.
`Reminders`/`NotificationRouter` (`Goodbye/Reminders.swift`) schedule up to 14 days of local
notifications from the projected pile; tapping one bumps `Store.wantsToday`, which `RootView`/
`TodayView` watch to force the nav stack back to Today regardless of what was open.

### Theme and dark mode

`Theme` (`Views/Theme.swift`) centralizes colour as named asset lookups and type as
`Font.TextStyle` — never a fixed point size, since a fixed size is why large-text testers had
links that never grew. Dark mode is intentionally **parked, not removed**: every asset carries a
dark variant and `DailyWash` has a dark branch, but `Theme.forcedColorScheme = .light`
short-circuits the system lookup. Reinstating it means setting that to `nil`, but the palette
(especially the warm hues) was tuned against a white ground and reads muddy on the current dark
variants — treat that as a design pass, not a flag flip.

### Two recurring `Text`/date gotchas

- `Text(date, format:)` resolves the format style's locale from the **environment**, not from a
  `.locale()` call on the style itself — `GoodbyeApp.swift` pins
  `.environment(\.locale, Theme.dateLocale)` at the root for this reason. A locale bug here isn't
  fixed by chasing `.locale()` at the call site.
- An `Int` interpolated directly into a `Text` (e.g. a year) picks up the user's grouping separator
  ("2 027"). `OnboardingView.projection` works around it with `.formatted(.number.grouping(.never))`
  — reuse that pattern for any other bare year/count interpolated into `Text`.
