# Goodbye

Every other day, one thing leaves the flat. iOS 17+, SwiftUI, no server, no account, no red anywhere.

The design lives in the code and in **Design system** below; the working documents that got us
here are gone on purpose, because a design doc that has to chase the code never pays for itself.

## Before the first build

Xcode isn't installed on this Mac — only Command Line Tools. It has to come down from the App
Store (~15 GB) and be opened once so it installs the iOS platform, then:

    sudo xcode-select -s /Applications/Xcode.app

## Run in the Simulator

    open Goodbye.xcodeproj

Scheme **Goodbye**, any iPhone simulator, Run.

## On your iPhone, without the App Store (free)

1. Target Goodbye → Signing & Capabilities → Team: add your Apple ID (Personal Team).
2. Plug the phone in, choose it as the run destination, Run.
3. On the phone: Settings → General → VPN & Device Management → trust the developer.
4. A free team expires the build after 7 days — run it from Xcode again to renew.

## Verify without Xcode

    ./Tools/check.sh

Typechecks every source file against the macOS SDK and runs 34 scenario tests over the queue
arithmetic and the four rhythms.

## Built and run

Verified on the iPhone 17 simulator (iOS 26.5, Xcode 26.6) on 7 September 2026: first run, the
hold-to-start commit, the notification prompt landing in context, drag-to-toss, the caught-up
screen, History, and a 34-item queue cleared 20 at once. Three bugs found by looking that the
typecheck could not catch:

- A year interpolated as an `Int` into `Text` picked up a grouping separator — "September 2 027".
- Asset colours named `Mint` / `Pink` / `Teal` collide with SwiftUI's own `Color`; the room hues
  are all prefixed `Room*` now.
- **SwiftUI overrides a format style's own locale with the environment's** for
  `Text(date, format:)`, so pinning `.locale()` per call site silently did nothing. On a phone set
  to `en_US@rg=czzzzz` the date read "Monday 7. 9."; the locale is pinned at the app root instead.

## What's in it beyond the loop

- **Undo.** Four seconds after any log, single or bulk. A satisfying toss needs a safe undo, or
  people toss carefully — and a careful gesture isn't a pleasant one.
- **The goodbye.** The note is a farewell addressed to the thing: *Goodbye, the mug from Lisbon.*
  Offered only after a single toss, because that's the only entry it can unambiguously belong to;
  a batch of twenty gets its note by tapping the row in History. Both fields are
  autocapitalisation-off — the note is a fragment inside a sentence, not a sentence.
- **The count in the world.** Under the total, the same number in other words — *Roughly a shelf.*
  — and on the day a round number goes by, one sentence instead of a badge. `Tally` handles a bulk
  log that jumps clean over a milestone.
- **The first year as a skeleton.** History draws every due day of the first year from day one:
  green where you were there, amber where you weren't (hollow while still owed), white for the
  days ahead. Each thing that goes fills a square that was already waiting for it.
- **A tapped reminder lands on Today**, popping whatever was open.

Deliberately still absent: streaks, levels, points, badges, confetti, an avatar, charts, sharing,
a disposal form. Playful in the surface, never in the mechanics.

## How it works

One JSON file in the app's Application Support folder holds entries (date, count, note, room) and
settings. Everything else is derived, nothing else is stored:

- **The queue** is due days elapsed minus things logged, floored at zero. Entries cover due days
  oldest-first and can't cover a day later than themselves, so you can catch up but never get
  ahead — leftovers count toward your total, not toward next week.
- **The mosaic** in History colours each due day by the room its entry came from.
- **Reminders** are scheduled two weeks ahead from the same arithmetic, one a day, only on days
  when something is waiting.

Changing the rhythm or the start date never breaks history; it just recolours it.

## Design system

- **Base is neutral**, and each screen is washed with 5% of the day's room hue (11% in the dark).
  Two earlier passes — a dusty beige, then a warm cream — both read gloomy, the cream because a
  warm ground muddies the five cool rooms.
- **Eight rooms, two tones each.** `bright` fills shapes and draws objects; `deep` carries anything
  with text in or on it. `OnDeep` is the label colour that pairs with a `deep` fill — it flips to
  near-black in the dark, where `deep` becomes a pale tint.
- **SF Rounded**, heavy weights. Ships with iOS.
- **Objects, not abstractions.** `Zone.symbol` and `Suggestion.symbol` are SF Symbol stand-ins for
  the eighteen hand-built `Path` drawings in the design doc; they swap out one at a time.

## Icon

    swift Tools/make-icon.swift Goodbye/Assets.xcassets/AppIcon.appiconset

Nine rooms, one already empty.

## Not in it, on purpose

Streaks, levels, points, badges, confetti, an avatar, charts, sharing, accounts, sync, ads,
subscriptions, a red badge on the icon, more than one reminder a day. Playful in the surface,
never in the mechanics — a broken streak is a debt, and the queue already forgives you.

## If the project file won't open

    brew install xcodegen && xcodegen

Regenerates `Goodbye.xcodeproj` from `project.yml`.
