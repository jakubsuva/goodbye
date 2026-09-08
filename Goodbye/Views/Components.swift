import SwiftUI

/// The one primary button: a pill in the day's *bright* tone with dark ink on it.
///
/// It used to be the deep tone — a dark bottle-green on a mint day — which made the loudest element
/// on the screen the least colourful thing in the palette. Bright fill, dark label: vivid in both
/// themes, and the eight days finally look like eight days.
/// Height is a minimum, not a fixed frame — at large text settings the label has to be allowed to
/// make the button taller instead of being clipped by it.
struct PillButtonStyle: ButtonStyle {
    let hue: Hue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.text(.callout, .heavy))
            .foregroundStyle(Theme.onBright)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .frame(minHeight: 54)
            .background(hue.bright, in: Capsule())
            .shadow(color: hue.bright.opacity(0.45), radius: 10, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The thing you're letting go of — deliberately *a* thing, not a particular one.
///
/// It used to draw whatever the suggestion said, which meant a gift icon while you were actually
/// throwing out a cable. The app never knows what left, so the card doesn't claim to: one neutral
/// item, in the colour of the day. With a queue behind it, it becomes a stack.
struct ItemCard: View {
    let hue: Hue
    var pile: Int = 1
    var size: CGFloat = 170

    var body: some View {
        ZStack {
            if pile > 2 { blank.offset(x: 18, y: -18).opacity(0.45) }
            if pile > 1 { blank.offset(x: 9, y: -9).opacity(0.7) }
            card.overlay {
                Image(systemName: "shippingbox")
                    .font(.system(size: size * 0.36, weight: .regular))
                    .foregroundStyle(hue.deep)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
    }

    private var radius: CGFloat { size * 0.22 }

    private var card: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(hue.bright.opacity(0.26))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(hue.bright.opacity(0.7), lineWidth: 3)
            )
            .frame(width: size, height: size)
            .shadow(color: hue.bright.opacity(0.35), radius: 14, x: 0, y: 10)
    }

    private var blank: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 2.5)
            )
            .frame(width: size, height: size)
    }
}

/// Date on the left, rhythm on the right. Quiet.
struct MetaRow: View {
    let date: Date
    let rhythm: Rhythm

    var body: some View {
        HStack {
            Text(date, format: .dateTime.weekday(.wide).day().month(.wide)
                .locale(Theme.dateLocale))
            Spacer()
            Text(rhythm.shortTitle)
        }
        .font(Theme.text(.caption, .bold))
        .foregroundStyle(Theme.muted)
    }
}

/// One square of the History mosaic: green done, amber still owed, white still ahead.
///
/// Amber is a state you can clear, not a verdict — the amber squares *are* the queue, so paying it
/// down turns them green and the past heals. Nothing here keeps a record of having been late.
struct DayCell: View {
    let state: DueDay.State
    static let size: CGFloat = 14

    var body: some View {
        ZStack {
            switch state {
            case .done:
                shape.fill(Theme.dayDone)
            case .owed:
                shape.fill(Theme.dayOwed)
            case .today:
                shape.strokeBorder(Theme.ink, lineWidth: 2.5)
            case .future:
                shape.fill(Theme.card)
                    .overlay(shape.strokeBorder(Theme.line, lineWidth: 1.5))
            }
        }
        .frame(width: Self.size, height: Self.size)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
    }
}

/// Six seconds to take it back. A satisfying toss needs a safe undo, or people toss carefully —
/// and a careful gesture isn't a pleasant one. It's also the *only* way back now that the app keeps
/// no list of what went, so it can't be brief.
struct UndoToast: View {
    let count: Int
    let hue: Hue
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(count == 1 ? "Gone." : "\(count) gone.")
                .foregroundStyle(Theme.onDeep)
            Button("Undo", action: undo)
                .foregroundStyle(Theme.onDeep)
                .underline()
        }
        .font(Theme.text(.footnote, .heavy))
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(hue.deep, in: Capsule())
        .shadow(color: hue.deep.opacity(0.3), radius: 10, x: 0, y: 6)
    }
}

/// The reward for having nothing left to do — the hero of the caught-up screen.
///
/// Two earlier attempts failed by being clever: an open drawer and then an open box, both of which
/// read as a lampshade at this size and neither of which said *done*. So: the plainest possible
/// mark of done, made generous. The lift comes from scale, colour and the sentence under it.
struct CaughtUpMark: View {
    let hue: Hue
    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle().fill(hue.bright)
            Image(systemName: "checkmark")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.onBright)
        }
        .frame(width: 152, height: 152)
        .scaleEffect(appeared ? 1 : 0.86)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.5, bounce: 0.35), value: appeared)
        .onAppear { appeared = true }
        .accessibilityLabel("All clear")
    }
}

/// Press and hold to commit. Wordless on purpose: no oath, nothing to feel guilty about later —
/// just a gesture that costs a moment and therefore registers as a choice.
struct HoldButton: View {
    let title: String
    let hue: Hue
    /// Shown under the pill at rest. Left nil in onboarding: small grey print directly beneath a
    /// commitment button is the shape of subscription fine print, whatever it actually says.
    var restingHint: String? = nil
    let action: () -> Void

    @State private var pressing = false
    @State private var hint = false

    private let duration = 1.2

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                // The track has to look like something you may press. At 20% it read as disabled —
                // and it's the first button anyone ever meets, sitting next to a fully vivid Gone
                // pill on the next screen. Stronger tint plus a border: still clearly a track that
                // fills, no longer greyed out.
                Capsule().fill(hue.bright.opacity(0.3))
                Capsule().strokeBorder(hue.bright, lineWidth: 2.5)
                GeometryReader { geo in
                    Capsule()
                        .fill(hue.bright)
                        .frame(width: pressing ? geo.size.width : 0)
                        .animation(.linear(duration: pressing ? duration : 0.2), value: pressing)
                }
                Text(title)
                    .font(Theme.text(.callout, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
            }
            .frame(minHeight: 54)
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(Capsule())
            .contentShape(Capsule())
            .onLongPressGesture(minimumDuration: duration) {
                action()
            } onPressingChanged: { isPressing in
                pressing = isPressing
                // A short tap shouldn't do nothing — it should teach the gesture.
                if !isPressing { hint = true }
            }
            // VoiceOver can't hold, so it gets a plain activation.
            .accessibilityElement()
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Press and hold to begin")
            .accessibilityAction { action() }

            Text(hint && !pressing ? "Hold it for a second." : (restingHint ?? " "))
                .font(Theme.text(.caption2, .bold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
        }
    }
}
