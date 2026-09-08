import SwiftUI

/// The whole of first run: one screen, one real question, and then you throw something away.
///
/// No welcome frame — the headline is both the pitch and the sentence the options complete. The
/// reminder is asked here rather than left to Settings, because a badly timed nudge kills the habit
/// as surely as no nudge. And it ends by dropping you on Today with the first thing already due:
/// an intention stated is worth little, a thing actually in the bin is the habit's first brick.
///
/// Deliberately **not** built like a paywall, which is what an earlier version accidentally was:
/// boxed options with one highlighted and "365 a year" set off to the right read as pricing tiers,
/// a toggle in a card above a big CTA read as the trial-reminder switch, and grey fine print under
/// the button read as "cancel anytime". So: no boxes, no per-row figures, no card round the
/// reminder, and the reassurance sits up by the question instead of under the commitment.
struct OnboardingView: View {
    @Environment(Store.self) private var store

    @State private var rhythm: Rhythm = .everyOtherDay
    @State private var remindersOn = true
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 19, minute: 0, second: 0, of: Date()
    ) ?? Date()

    /// First run borrows the day's colour, so onboarding already looks like the app.
    private var hue: Hue { Hue.forDay(Date(), calendar: store.calendar) }

    var body: some View {
        // Adding the queue strip pushed the headline off the top at accessibility text sizes, so
        // the screen scrolls when it has to. `minHeight` keeps the spacers doing their work — and
        // the airy layout — whenever it fits, which is every ordinary text size.
        GeometryReader { geo in
            ScrollView {
                content.frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .dailyWash(hue)
    }

    private var content: some View {
        // Three groups, not five loose blocks. Every gap used to be the same size, so nothing read
        // as belonging to anything — and the four rhythms were spread over a third of the screen
        // even though they finish the sentence in the headline. Tight inside a group, generous
        // between: that's the whole fix.
        VStack(alignment: .leading, spacing: 0) {

            // — the question, and the four ways to finish it
            VStack(alignment: .leading, spacing: 0) {
                Text("One thing leaves your life…")
                    .font(Theme.sentence(.title))
                    .foregroundStyle(Theme.ink)

                Text("Pick a rhythm. You can change it whenever.")
                    .font(Theme.text(.subheadline))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Rhythm.allCases) { option in
                        rhythmRow(option)
                    }
                }
                .padding(.top, 14)
            }

            // — what that choice actually means
            VStack(alignment: .leading, spacing: 0) {
                projection

                Text(rhythm.counsel)
                    .font(Theme.text(.footnote))
                    .foregroundStyle(Theme.muted)
                    .frame(minHeight: 38, alignment: .top)
                    .padding(.top, 6)

                // The queue, demonstrated. Jakub's call, and the right one: first run is the
                // moment somebody is curious enough to watch, and watching beats being told.
                QueuePreview()
                    .padding(.top, 12)

                Text("Miss a few days and they wait for you — clear them one at a time, or all at once.")
                    .font(Theme.text(.footnote))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            .padding(.top, 30)

            // All the slack goes here, in one place, rather than being split three ways — three
            // distributed gaps is what made the screen feel like it was drifting apart.
            Spacer(minLength: 26)

            // — and the two things left to set
            VStack(alignment: .leading, spacing: 0) {
                reminderRow

                HoldButton(title: "Hold to start", hue: hue) {
                    start()
                }
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pieces

    /// Four lines of plain text completing the headline. A tick for the one you've picked — the
    /// iOS idiom for choosing from a list, and pointedly not the boxed radio of a pricing tier.
    private func rhythmRow(_ option: Rhythm) -> some View {
        let selected = option == rhythm
        return Button {
            withAnimation(.snappy(duration: 0.2)) { rhythm = option }
        } label: {
            HStack(spacing: 10) {
                Text(option.phrase)
                    .font(Theme.text(.title3, selected ? .heavy : .semibold))
                    .foregroundStyle(selected ? Theme.ink : Theme.muted)
                Spacer()
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(hue.deep)
                    .opacity(selected ? 1 : 0)
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    /// Nobody feels “every other day”. Everybody feels 183 things gone by next September.
    /// One number, in a sentence — not a figure in the margin of a row.
    private var projection: some View {
        // A year interpolated as an Int picks up a grouping separator — "September 2 027".
        let year = (store.calendar.component(.year, from: Date()) + 1)
            .formatted(.number.grouping(.never))
        let month = Date().formatted(.dateTime.month(.wide).locale(Theme.dateLocale))
        return (Text("\(rhythm.yearlyCount)").foregroundStyle(hue.deep)
            + Text(" things gone by \(month) \(year).").foregroundStyle(Theme.ink))
            .font(Theme.text(.title3, .heavy))
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    /// A bare row, not a card. The card was what made this look like the trial-reminder switch.
    private var reminderRow: some View {
        HStack(spacing: 8) {
            Text(remindersOn ? "Nudge me at" : "No reminder")
                .font(Theme.text(.subheadline))
                .foregroundStyle(remindersOn ? Theme.ink : Theme.muted)
            if remindersOn {
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(hue.deep)
            }
            Spacer()
            Toggle("", isOn: $remindersOn)
                .labelsHidden()
                .tint(hue.deep)
        }
        .accessibilityLabel("Daily reminder")
    }

    // MARK: - Commit

    private func start() {
        let parts = store.calendar.dateComponents([.hour, .minute], from: reminderTime)
        Task {
            await store.completeOnboarding(
                rhythm: rhythm,
                remindersOn: remindersOn,
                hour: parts.hour ?? 19,
                minute: parts.minute ?? 0
            )
        }
    }
}
