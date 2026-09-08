import SwiftUI

/// The colour of the day. Eight of them, rotating one per day.
///
/// This used to be a `Zone` — a room of the flat that also grouped the suggestions and got written
/// onto every entry. The rooms are gone: they made the app ask which room a thing came from, which
/// is cataloguing, and they were wrong as often as right for anyone whose home isn't laid out like
/// the list. What survived is the part people actually liked — that every day looks slightly
/// different — so this is now only a colour, with no claim about your home.
enum Hue: String, CaseIterable, Identifiable {
    case sun, sky, mint, coral, violet, teal, pink, lime

    var id: String { rawValue }

    /// Fills shapes and tints cards.
    var bright: Color {
        switch self {
        case .sun: return Color("HueSun")
        case .sky: return Color("HueSky")
        case .mint: return Color("HueMint")
        case .coral: return Color("HueCoral")
        case .violet: return Color("HueViolet")
        case .teal: return Color("HueTeal")
        case .pink: return Color("HuePink")
        case .lime: return Color("HueLime")
        }
    }

    /// Carries anything with text in or on it — the primary pill, a link, a number.
    /// One hue, two tones, so nothing has to choose between cheerful and legible.
    var deep: Color {
        switch self {
        case .sun: return Color("HueSunDeep")
        case .sky: return Color("HueSkyDeep")
        case .mint: return Color("HueMintDeep")
        case .coral: return Color("HueCoralDeep")
        case .violet: return Color("HueVioletDeep")
        case .teal: return Color("HueTealDeep")
        case .pink: return Color("HuePinkDeep")
        case .lime: return Color("HueLimeDeep")
        }
    }

    /// Tomorrow's colour — the foot of today's gradient, so each day leans into the next.
    var next: Hue {
        let all = Hue.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }

    static func forDay(_ day: Date, calendar: Calendar) -> Hue {
        // Debug builds can pin the day's colour, because otherwise the only way to see any hue but
        // today's is to wait for tomorrow:
        //   SIMCTL_CHILD_GOODBYE_HUE=coral xcrun simctl launch <udid> com.jakubsuva.goodbye
        #if DEBUG
        if let pinned = ProcessInfo.processInfo.environment["GOODBYE_HUE"],
           let hue = Hue(rawValue: pinned) {
            return hue
        }
        #endif
        let all = Hue.allCases
        return all[ordinal(of: day, calendar: calendar) % all.count]
    }

    static func ordinal(of day: Date, calendar: Calendar) -> Int {
        calendar.ordinality(of: .day, in: .era, for: day) ?? 0
    }
}
