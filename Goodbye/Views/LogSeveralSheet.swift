import SwiftUI

/// After a big clear-out you don't tap twenty times. Pick the number, confirm once.
struct LogSeveralSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    let pile: Int
    let hue: Hue
    var onLogged: (Entry) -> Void = { _ in }
    @State private var count: Int

    init(pile: Int, hue: Hue, onLogged: @escaping (Entry) -> Void = { _ in }) {
        self.pile = pile
        self.hue = hue
        self.onLogged = onLogged
        _count = State(initialValue: min(max(pile, 1), 5))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("How many went?")
                .font(Theme.text(.subheadline, .heavy))
                .padding(.top, 22)

            Text("\(count)")
                .font(Theme.display)
                .foregroundStyle(hue.deep)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .padding(.top, 12)

            HStack(spacing: 14) {
                stepButton("minus", "One fewer") { count = max(1, count - 1) }
                stepButton("plus", "One more") { count += 1 }
            }
            .padding(.top, 10)

            HStack(spacing: 8) {
                ForEach(quickPicks, id: \.self) { n in
                    Button {
                        withAnimation(.snappy) { count = n }
                    } label: {
                        Text(n == pile ? "All \(pile)" : "\(n)")
                            .font(Theme.text(.caption, .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(count == n ? hue.deep : Color.clear, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(count == n ? hue.deep : Theme.line, lineWidth: 2)
                            )
                            .foregroundStyle(count == n ? Theme.onDeep : Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 12)

            Button("Gone ×\(count)") {
                if let entry = store.log(count) { onLogged(entry) }
                dismiss()
            }
            .buttonStyle(PillButtonStyle(hue: hue))

            Text(note)
                .font(Theme.text(.footnote))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(Theme.card)
        // A second, taller detent so a large text setting has somewhere to go.
        .presentationDetents([.height(400), .large])
        .presentationDragIndicator(.visible)
    }

    private var quickPicks: [Int] {
        var picks = [5, 10, 20].filter { $0 < pile }
        picks.append(pile)
        return picks
    }

    private var note: String {
        let remaining = pile - count
        if remaining > 0 { return String(localized: "\(remaining) will still be waiting.") }
        if remaining == 0 { return String(localized: "That clears the queue.") }
        return String(localized: "\(-remaining) more than the queue — they count toward your total, not toward next week.")
    }

    // LocalizedStringKey, not String, so the literal accessibility labels at the call site
    // ("One fewer" / "One more") go through the normal localization lookup.
    private func stepButton(_ symbol: String, _ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 46, height: 46)
                .overlay(Circle().strokeBorder(Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
