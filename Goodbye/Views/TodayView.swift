import SwiftUI

/// The only screen you see on a good day. Three states: due, behind, caught up.
struct TodayView: View {
    @Environment(Store.self) private var store

    @State private var showSeveral = false
    @State private var step = 0
    @State private var dragOffset = CGSize.zero
    @State private var isTossing = false
    @State private var undoable: Entry?
    @State private var undoTask: Task<Void, Never>?

    private var hue: Hue { store.todayHue }

    var body: some View {
        let ledger = store.ledger
        VStack(spacing: 0) {
            MetaRow(date: store.now, rhythm: store.settings.rhythm)
            if ledger.pile == 0 {
                caughtUp(ledger)
            } else {
                pending(ledger)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dailyWash(hue)
        .washedBar()
        .overlay(alignment: .bottom) {
            if let entry = undoable {
                UndoToast(count: entry.count, hue: hue) {
                    store.delete(entry)
                    undoTask?.cancel()
                    undoable = nil
                }
                // Above the bottom cluster, so it never sits on the links you'd want next.
                .padding(.bottom, 150)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: undoable)
        .sheet(isPresented: $showSeveral) {
            LogSeveralSheet(pile: ledger.pile, hue: hue) { entry in
                arm(undo: entry)
            }
        }
        .sensoryFeedback(.success, trigger: store.entries.count)
    }

    // MARK: - Due / behind

    @ViewBuilder
    private func pending(_ ledger: Ledger) -> some View {
        let pile = ledger.pile
        VStack(alignment: .leading, spacing: 0) {
            // The numeric transition belongs to the count only: applied to the question as well, it
            // made the Text single-line and large text settings clipped it to "Who's leavin…".
            Group {
                if pile == 1 {
                    Text("Who's leaving today?")
                } else {
                    Text("\(pile) in the queue.").contentTransition(.numericText())
                }
            }
            .font(Theme.sentence())
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 32)

            if store.settings.suggestionsOn {
                suggestionLine.padding(.top, 14)
            }

            Spacer(minLength: 16)

            // Centred in what's left, so the void splits into two small gaps instead of one big one.
            VStack(spacing: 12) {
                ItemCard(hue: hue, symbol: ItemSymbol.forDay(store.now, calendar: store.calendar), pile: pile)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(dragOffset.height * 0.12))
                    .opacity(isTossing ? 0 : 1)
                    .gesture(dragGesture)
                    // The drag is invisible to VoiceOver, so the card is a button for it too.
                    .accessibilityElement()
                    .accessibilityLabel(pile == 1 ? "One thing to let go of" : "\(pile) in the queue")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double tap to let one go")
                    .accessibilityAction { complete() }

                // Both ways work, and neither was discoverable. Retires once you've dragged one.
                if !store.settings.hasTossedByDrag {
                    Text("Drag it out — or tap the button")
                        .font(Theme.text(.caption2, .semibold))
                        .foregroundStyle(Theme.muted)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 16)

            // "Gone" alone reads as "all done" when a queue is showing, so it says what it does.
            Button(pile > 1 ? "One gone" : "Gone") { complete() }
                .buttonStyle(PillButtonStyle(hue: hue))

            if pile > 1 {
                Button("Had a big clear-out? Log them at once") { showSeveral = true }
                    .font(Theme.text(.footnote, .heavy))
                    .foregroundStyle(hue.deep)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }

            CountLine(total: ledger.total)
                .padding(.top, 11)
        }
    }

    /// Inspiration, and nothing more: one line, a refresh, no record of which one you took.
    private var suggestionLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            // Same trap as the headline one level down: inside an HStack the line truncates unless
            // it's told it may grow vertically.
            (Text("Not sure? ").foregroundStyle(Theme.muted)
                + Text(currentLine).foregroundStyle(Theme.ink))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                withAnimation(.snappy(duration: 0.2)) { step += 1 }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(hue.deep)
                    // The icon stays small; the tap target doesn't — 44pt is the HIG minimum.
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Another suggestion")
        }
        .font(Theme.text(.footnote))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Caught up

    @ViewBuilder
    private func caughtUp(_ ledger: Ledger) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            VStack(spacing: 0) {
                CaughtUpMark(hue: hue)

                // The point of the screen: you are done. Everything else is a footnote to it.
                Text("All clear.")
                    .font(Theme.sentence(.largeTitle))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 24)

                // A round number is the one thing that earns a line of its own up here.
                if let milestone = store.milestoneCrossedToday {
                    Text(Tally.sentence(for: milestone))
                        .font(Theme.text(.subheadline, .bold))
                        .foregroundStyle(hue.deep)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }

                Text(closing)
                    .font(Theme.text(.subheadline))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)
            }
            Spacer(minLength: 8)

            // The running total, demoted to a signature. Nice to know, not what you came for.
            Text("\(ledger.total) gone")
                .font(Theme.text(.caption, .semibold))
                .foregroundStyle(Theme.muted)
                .monospacedDigit()

            // Was "Log another anyway" — five testers read "anyway" as taking on debt. It doesn't:
            // anything past the queue counts toward the total and never toward a future day.
            Button("One more") { arm(undo: store.log(1)) }
                .font(Theme.text(.footnote, .bold))
                .foregroundStyle(hue.deep)
                .buttonStyle(.plain)
                .padding(.top, 14)
        }
    }

    /// The app's own name is what it says when you're done — but only on a day you did something.
    private var closing: String {
        guard store.didLogToday else { return String(localized: "Nothing due today.\n\(backLine)") }
        return String(localized: "Goodbye.\n\(backLine)")
    }

    /// “See you Wednesday.” — when the app will ask again.
    private var backLine: String {
        let settings = store.settings
        guard let next = settings.rhythm.nextDueDay(
            after: store.now, from: settings.startDate, calendar: store.calendar
        ) else { return "" }
        let days = store.calendar.dateComponents(
            [.day], from: store.calendar.startOfDay(for: store.now), to: next
        ).day ?? 0
        if days == 1 { return String(localized: "See you tomorrow.") }
        if days < 7 { return String(localized: "See you \(next.formatted(.dateTime.weekday(.wide))).") }
        return String(localized: "See you on \(next.formatted(.dateTime.day().month(.wide))).")
    }

    private var currentLine: String {
        let list = SuggestionBank.lines(for: store.now, calendar: store.calendar)
        return list[step % list.count]
    }

    // MARK: - Letting one go

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isTossing else { return }
                dragOffset = CGSize(
                    width: value.translation.width * 0.35,
                    height: max(0, value.translation.height)
                )
            }
            .onEnded { value in
                if value.translation.height > 90 {
                    if !store.settings.hasTossedByDrag {
                        store.updateSettings { $0.hasTossedByDrag = true }
                    }
                    toss()
                } else {
                    withAnimation(.spring(duration: 0.35)) { dragOffset = .zero }
                }
            }
    }

    private func toss() {
        withAnimation(.easeIn(duration: 0.24)) {
            dragOffset = CGSize(width: dragOffset.width, height: 460)
            isTossing = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            complete()
            dragOffset = .zero
            isTossing = false
        }
    }

    private func complete() {
        arm(undo: store.log(1))
        step = 0
    }

    /// Six seconds to take it back, then the toast goes on its own. It's the only way back, since
    /// the app keeps no list of what left.
    private func arm(undo entry: Entry?) {
        undoTask?.cancel()
        undoable = entry
        guard entry != nil else { return }
        undoTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled { undoable = nil }
        }
    }
}

/// “219 gone” — the total, always growing.
struct CountLine: View {
    let total: Int

    var body: some View {
        (Text("\(total)").fontWeight(.heavy).foregroundStyle(Theme.ink)
            + Text(" gone").fontWeight(.bold).foregroundStyle(Theme.muted))
            .font(Theme.text(.footnote))
            .monospacedDigit()
            .frame(maxWidth: .infinity)
    }
}
