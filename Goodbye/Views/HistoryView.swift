import SwiftUI

/// The first year as a mosaic of due days — green done, amber still owed, white still ahead — so
/// the shape is there from day one and each thing that goes fills a square that was waiting for it.
///
/// That's the whole screen. There used to be a list of what left underneath, and it's gone with
/// the tracking: the app doesn't know what you let go of, so it has nothing to list. What's left is
/// the rhythm — which is the only thing this screen was ever really about.
struct HistoryView: View {
    @Environment(Store.self) private var store

    private let columns = Array(repeating: GridItem(.fixed(DayCell.size), spacing: 4), count: 18)

    var body: some View {
        let ledger = store.ledger
        let year = ledger.firstYear(settings: store.settings, today: store.now, calendar: store.calendar)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(heading)
                    .font(Theme.sentence(.largeTitle))
                    .foregroundStyle(Theme.ink)

                Text(statsLine(ledger))
                    .font(Theme.text(.caption, .bold))
                    .foregroundStyle(Theme.muted)
                    .monospacedDigit()
                    .padding(.top, 4)

                // One element for VoiceOver: a hundred unlabelled squares is noise, the summary
                // is the information.
                LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                    ForEach(year) { day in
                        DayCell(state: day.state)
                    }
                }
                .padding(.top, 20)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(gridSummary(year))

                legend.padding(.top, 16)

                // The residue of the decision: no streak, no debt, better every month.
                Text("Started \(store.settings.startDate.formatted(.dateTime.day().month(.wide).year()))")
                    .font(Theme.text(.caption, .semibold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dailyWash(store.todayHue)
        .navigationTitle("History")
    }

    /// "2026", or "2026–27" once the first year straddles two.
    private var heading: String {
        let cal = store.calendar
        let start = cal.component(.year, from: store.settings.startDate)
        let end = cal.date(byAdding: .day, value: 364, to: store.settings.startDate)
            .map { cal.component(.year, from: $0) } ?? start
        return start == end ? String(start) : "\(start)–\(String(end).suffix(2))"
    }

    private func statsLine(_ ledger: Ledger) -> String {
        let things = String(localized: "\(ledger.total) gone")
        if ledger.pile == 0 { return String(localized: "\(things) · caught up") }
        return String(localized: "\(things) · \(ledger.pile) in the queue")
    }

    private func gridSummary(_ year: [DueDay]) -> String {
        let done = year.filter { $0.state == .done }.count
        let owed = year.filter { $0.state == .owed }.count
        let ahead = year.filter { $0.state == .future }.count
        return String(localized: "Your first year: \(done) days done, \(owed) owed, \(ahead) still ahead.")
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(.done, "done")
            legendItem(.owed, "owed")
            legendItem(.future, "ahead")
        }
        .font(Theme.text(.caption2, .bold))
        .foregroundStyle(Theme.muted)
    }

    private func legendItem(_ state: DueDay.State, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            DayCell(state: state).accessibilityHidden(true)
            Text(label)
        }
    }
}
