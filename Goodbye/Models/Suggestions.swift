import Foundation

/// Inspiration for the days when the hard part isn't letting go but choosing. Offered as one quiet
/// line — "Not sure? …" — with a refresh for another.
///
/// The mindset isn't clearing a room, it's clearing your **life**, so the bank isn't only objects:
/// a subscription, an app, a newsletter and an obligation all take up space, and some of them take
/// up more than a chipped mug ever did. Mostly physical still, because that's where a daily habit
/// actually happens — but the door is open.
///
/// Nothing is recorded: no rooms, no categories, no note of which line you acted on. The app can't
/// know what you actually let go of and shouldn't pretend to, so a suggestion is a nudge to start
/// looking and never a thing you tick off.
enum SuggestionBank {
    static let lines = [
        "the bottle opener — the other one",
        "the third pan",
        "the takeaway chopsticks in the drawer",
        "the pan whose handle wobbles",
        "a spice you can't remember buying",
        "the jar you kept for “something”",
        "the sample-size cream you're saving for a trip",
        "the sunscreen from two summers ago",
        "the third hairbrush",
        "the razor that stopped being sharp in spring",
        "the T-shirt you haven't worn in a year",
        "the jeans that will fit again “someday”",
        "the scarf someone meant well with",
        "the sock without its other half",
        "a cable with nothing to plug into",
        "the fourth USB-A charger",
        "earphones that only play on one side",
        "the box the headphones came in",
        "the phone box — the warranty is in your email",
        "the manual for the kettle you replaced",
        "a receipt for something you can't return anymore",
        "the takeaway menu from a place that closed",
        "the shoes that “will break in”",
        "the umbrella that doesn't quite open",
        "the key to a lock you no longer have",
        "the spare tote bag under the other spare tote bags",
        "the box from an appliance you've had three years",
        "the plant pot with the crack",
        "the paint tin from a wall that's since been repainted",
        "the charger for a phone you sold",
        "the pen that has to be shaken to write",
        "the notebook with three pages used",
        "the stack of conference lanyards",
        "a dead battery kept “to recycle later”",
        "a subscription you forgot you were paying for",
        "an app you haven't opened since spring",
        "a newsletter you never read",
        "a browser tab you've kept open for a month",
        "a group chat you've had muted since last year",
        "a folder on your desktop called “stuff”",
        "a photo of a screenshot of a receipt",
        "a login for a service that no longer exists",
        "a favour you keep meaning to ask for and never will",
        "a plan you agreed to and have been dreading since",
    ]

    /// Today's lines, rotated so the first one changes daily and the refresh walks on from there.
    /// Localized here, once, so every caller (the Today screen, the reminder notification) gets
    /// translated text without having to know these started life as English literals.
    static func lines(for day: Date, calendar: Calendar) -> [String] {
        let k = Hue.ordinal(of: day, calendar: calendar) % lines.count
        let rotated = Array(lines[k...] + lines[..<k])
        return rotated.map { NSLocalizedString($0, comment: "Suggestion line") }
    }
}
