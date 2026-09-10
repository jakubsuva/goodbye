import SwiftUI

/// The palette and type of the app. Two passes got us here: a dusty beige that read gloomy, then a
/// warm cream that flattered warm objects and quietly muddied the cool ones. So the base is neutral
/// and the colour arrives as a wash of whichever room is up today.
enum Theme {
    /// The screen's ground before the day's wash: white, or a soft plum-charcoal in the dark.
    static let base = Color("Base")
    /// Behind grouped lists, a shade off the cards.
    static let bg = Color("Bg")
    static let card = Color("Card")
    static let ink = Color("Ink")
    static let muted = Color("Muted")
    static let line = Color("Line")
    static let lineStrong = Color("LineStrong")
    static let ghost = Color("Ghost")
    /// The label colour that pairs with a `deep` fill. White in the light, near-black in the dark —
    /// because `deep` flips to a pale tint there, and white-on-pale would be unreadable.
    static let onDeep = Color("OnDeep")
    /// The label colour that pairs with a `bright` fill. Always dark: bright tones are light-ish in
    /// both themes, so one dark ink reads on all eight of them either way round.
    static let onBright = Color("OnBright")
    /// History: green for done, amber for still owed. Amber rather than red on purpose —
    /// it's something to put right, not an alarm.
    static let dayDone = Color("DayDone")
    static let dayOwed = Color("DayOwed")

    // MARK: - Type
    //
    // Everything goes through a `Font.TextStyle`, never a fixed point size, so the reader's own
    // text-size setting actually moves it. Fixed sizes are why two testers with larger text
    // couldn't use the app at all: the small links at the foot of the screen never grew.

    /// SF Rounded, sized by the reader. Ships with iOS, so nothing gets downloaded.
    static func text(_ style: Font.TextStyle, _ weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// The sentences the app says.
    static func sentence(_ style: Font.TextStyle = .title) -> Font {
        .system(style, design: .rounded, weight: .heavy)
    }

    /// The one display numeral, in the bulk sheet. Fixed on purpose — it is already enormous — but
    /// pair it with `.minimumScaleFactor` so a very large text setting shrinks it instead of
    /// clipping it.
    static let display = Font.system(size: 80, weight: .heavy, design: .rounded)

    // MARK: - Dark mode, parked
    //
    /// Dark mode is switched off for now. Nothing is deleted: every colour in the asset catalogue
    /// still carries its dark variant, and `DailyWash` still has its dark branch — they simply
    /// never get asked for while this is `.light`.
    ///
    /// **To bring it back, set this to `nil`** and the app follows the system again. The reason it
    /// went: the eight day colours were tuned on white, and the warm ones (coral especially) came
    /// out maroon over the dark ground — the palette needs its own dark pass, not a switch.
    static let forcedColorScheme: ColorScheme? = .light

    /// Region can disagree with language — a phone set to English with region Czechia
    /// (`en_US@rg=czzzzz`) is a real, common combination — and under some regions `Date.FormatStyle`
    /// silently drops a requested `.wide` month for a numeric one ("9. 9." instead of "September 9"),
    /// the same failure mode a hard-coded English pin used to guard against. Deriving the locale
    /// from the app's own resolved language (not the device region) keeps every date's field choices
    /// reliable in whichever language the string catalog picked, without forcing English on readers
    /// who chose something else.
    static var dateLocale: Locale {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        // The copy is written in British English ("colour", "recolours"); bare "en" resolves to
        // US conventions (month-day order, a comma before the day), so pin that one case to match
        // the voice everywhere else. Every other language uses its own resolved code as-is.
        return Locale(identifier: language == "en" ? "en_GB" : language)
    }
}

/// Paints the ground: today's colour at the top drifting into tomorrow's at the foot.
///
/// It started as a flat 5% tint, which was so restrained you could barely tell — and since only one
/// colour shows per day, the whole app read as one hue. Two colours per screen and a much stronger
/// mix fix both: every day looks different *and* every screen has some depth in it.
struct DailyWash: ViewModifier {
    let hue: Hue
    @Environment(\.colorScheme) private var scheme

    private var isDark: Bool { scheme == .dark }

    /// Light: today's colour drifts into tomorrow's. Dark: today's colour drifts into *nothing* —
    /// two mid tones layered over a dark ground turn muddy (lime into sun came out olive), and a
    /// single hue fading to the base keeps the depth without the sludge.
    private var gradient: LinearGradient {
        LinearGradient(
            colors: isDark
                ? [hue.bright.opacity(0.17), hue.bright.opacity(0.02)]
                : [hue.bright.opacity(0.16), hue.next.bright.opacity(0.09)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func body(content: Content) -> some View {
        content.background {
            Theme.base.overlay(gradient).ignoresSafeArea()
        }
    }
}

extension View {
    func dailyWash(_ hue: Hue) -> some View {
        modifier(DailyWash(hue: hue))
    }

    /// Hides the navigation bar's material so the washed ground runs edge to edge. iOS only.
    @ViewBuilder
    func washedBar() -> some View {
        #if os(iOS)
        self.toolbarBackground(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
