import Foundation

/// One quiet sentence on the day a round number goes by.
///
/// There used to be a second line here that translated the total into objects — "roughly a shelf",
/// "about a car boot". It divided testers more than anything else on the screen (a shelf of what?
/// what's a car boot?) and the count is a footnote now anyway, so it's gone. Milestones stay:
/// they land once, they're rare, and they read as a remark rather than a score.
enum Tally {
    static let milestones = [10, 50, 100, 250, 500, 1000]

    /// The milestone this entry carried the total past — but only when the total actually landed
    /// near it. A bulk log can jump straight over one, so this is a range test rather than an
    /// equality; and going 0 → 34 technically crosses ten, where "Ten. It's a habit now." printed
    /// over a big 34 reads as a stale label. An overshoot gets nothing.
    static func milestoneCrossed(before: Int, after: Int) -> Int? {
        guard let crossed = milestones.last(where: { before < $0 && $0 <= after }) else { return nil }
        return after - crossed <= max(3, crossed / 10) ? crossed : nil
    }

    static func sentence(for milestone: Int) -> String {
        switch milestone {
        case 10: return "Ten. It's a habit now."
        case 50: return "Fifty. That's a shelf you never have to dust."
        case 100: return "A hundred. The flat is lighter than the one you started in."
        case 250: return "Two hundred and fifty. A cupboard, cleared."
        case 500: return "Five hundred things you don't miss."
        case 1000: return "A thousand things, and not one you miss."
        default: return "\(milestone)."
        }
    }
}
