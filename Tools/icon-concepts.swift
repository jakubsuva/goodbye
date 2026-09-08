// Draws candidate app icons big and at 29pt, which is the only size that decides anything.
// Usage: swift Tools/icon-concepts.swift /tmp/icons [columns]
//
// What the first two rounds taught, now treated as rules: an open palm reads as "stop", an arch
// reads as a bauble, a ring of eight with a gap reads as a loading spinner, a 2×2 grid reads as a
// launcher, and anything smaller than about a fifth of the canvas is gone by 29pt. So: at most two
// shapes, both large, and one of them is doing something.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CoreText

let space = CGColorSpace(name: CGColorSpace.sRGB)!
func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 0xFF) / 255,
        CGFloat((hex >> 8) & 0xFF) / 255,
        CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

// the app's eight day colours, bright and deep
let sun = (0xFFB733 as UInt32, 0xA85400 as UInt32)
let sky = (0x3DAFFF as UInt32, 0x0B5FA5 as UInt32)
let mint = (0x34D399 as UInt32, 0x0A6E4C as UInt32)
let coral = (0xFF7A5C as UInt32, 0xB8371A as UInt32)
let violet = (0xA78BFA as UInt32, 0x5B2FC0 as UInt32)
let teal = (0x22CFCF as UInt32, 0x076F72 as UInt32)
let pink = (0xFF7EB0 as UInt32, 0xA82B60 as UInt32)
let lime = (0xA3DB4A as UInt32, 0x52780C as UInt32)

let paper: UInt32 = 0xFFFFFF
let ink: UInt32 = 0x2E2A36
let ghostGrey: UInt32 = 0xBFBFCE

/// Every concept draws on a 100×100 grid; `s` scales it to the real pixel size.
typealias Draw = (CGContext, CGFloat) -> Void

func ground(_ ctx: CGContext, _ s: CGFloat, _ colour: UInt32 = paper) {
    ctx.setFillColor(rgb(colour))
    ctx.fill(CGRect(x: 0, y: 0, width: 100 * s, height: 100 * s))
}

/// y is measured from the top, like the SVG the rest of the app was drawn in.
func box(_ ctx: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat,
         _ s: CGFloat, fill: CGColor? = nil, stroke: CGColor? = nil, lineWidth: CGFloat = 0,
         rotate: CGFloat = 0) {
    ctx.saveGState()
    var rect = CGRect(x: x * s, y: (100 - y - h) * s, width: w * s, height: h * s)
    if rotate != 0 {
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: rotate * .pi / 180)
        ctx.translateBy(x: -rect.midX, y: -rect.midY)
    }
    if stroke != nil { rect = rect.insetBy(dx: lineWidth / 2 * s, dy: lineWidth / 2 * s) }
    let path = CGPath(roundedRect: rect, cornerWidth: r * s, cornerHeight: r * s, transform: nil)
    if let fill { ctx.setFillColor(fill); ctx.addPath(path); ctx.fillPath() }
    if let stroke {
        ctx.setStrokeColor(stroke); ctx.setLineWidth(lineWidth * s)
        ctx.addPath(path); ctx.strokePath()
    }
    ctx.restoreGState()
}

func disc(_ ctx: CGContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ s: CGFloat, _ colour: CGColor) {
    ctx.setFillColor(colour)
    ctx.fillEllipse(in: CGRect(x: (cx - r) * s, y: (100 - cy - r) * s, width: 2 * r * s, height: 2 * r * s))
}

func stroke(_ ctx: CGContext, _ points: [(CGFloat, CGFloat)], _ width: CGFloat, _ s: CGFloat, _ colour: CGColor) {
    ctx.setStrokeColor(colour); ctx.setLineWidth(width * s)
    ctx.setLineCap(.round); ctx.setLineJoin(.round)
    for (i, p) in points.enumerated() {
        let cg = CGPoint(x: p.0 * s, y: (100 - p.1) * s)
        if i == 0 { ctx.move(to: cg) } else { ctx.addLine(to: cg) }
    }
    ctx.strokePath()
}

// ============================================================ the ten

// 1 — an empty outline where it used to sit, and the thing itself off to one side
let leftItsPlace: Draw = { c, s in
    ground(c, s)
    box(c, 15, 15, 40, 40, 12, s, stroke: rgb(ghostGrey), lineWidth: 8.5)
    box(c, 42, 44, 43, 43, 14, s, fill: rgb(violet.0), rotate: 16)
}

// 2 — halfway off the edge: leaving, not gone
let onItsWayOut: Draw = { c, s in
    ground(c, s)
    box(c, 12, 8, 36, 36, 12, s, fill: rgb(coral.0, 0.26))
    box(c, 46, 48, 50, 50, 16, s, fill: rgb(coral.0), rotate: 14)
}

// 3 — a row with one place standing empty
let aPlaceEmpty: Draw = { c, s in
    ground(c, s)
    for (i, h) in [sun, sky, mint].enumerated() {
        box(c, 13 + CGFloat(i) * 22, 30, 17, 40, 8.5, s, fill: rgb(h.0))
    }
    box(c, 79, 30, 17, 40, 8.5, s, stroke: rgb(ghostGrey), lineWidth: 6)
}

// 4 — the app's own mark, promoted. The safe one.
let theTick: Draw = { c, s in
    ground(c, s)
    disc(c, 50, 50, 33, s, rgb(mint.0))
    stroke(c, [(34, 52), (45, 63), (68, 38)], 11, s, rgb(0x123D2C))
}

// 5 — one less, as arithmetic
let minus: Draw = { c, s in
    ground(c, s)
    disc(c, 50, 50, 34, s, rgb(coral.0))
    box(c, 31, 46, 38, 8, 4, s, fill: rgb(0x3A1206))
}

// 6 — before and after, side by side
let pairFaded: Draw = { c, s in
    ground(c, s)
    box(c, 12, 32, 36, 36, 12, s, fill: rgb(teal.0))
    box(c, 54, 32, 36, 36, 12, s, fill: rgb(teal.0, 0.22))
}

// 7 — through the slot and away
let throughSlot: Draw = { c, s in
    ground(c, s)
    box(c, 14, 36, 72, 8, 4, s, fill: rgb(ink))
    box(c, 34, 54, 34, 34, 11, s, fill: rgb(pink.0), rotate: 12)
}

// 8 — the gesture the app actually asks for: down and out
let downAndOut: Draw = { c, s in
    ground(c, s)
    box(c, 32, 14, 37, 37, 12, s, fill: rgb(sky.0))
    stroke(c, [(33, 62), (50, 79), (67, 62)], 11, s, rgb(sky.1))
}

// 9 — the door, left ajar, with the light getting out
let doorAjar: Draw = { c, s in
    ground(c, s)
    box(c, 22, 14, 42, 72, 8, s, stroke: rgb(ink), lineWidth: 8)
    box(c, 70, 26, 12, 48, 6, s, fill: rgb(sun.0))
}

// 10 — the name itself, with a piece of it gone
let theG: Draw = { c, s in
    ground(c, s)
    let font = CTFontCreateWithName("SFRounded-Heavy" as CFString, 82 * s, nil)
        // SF Rounded may not be reachable by name on every machine; Helvetica Bold is a fair stand-in
    let fallback = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 82 * s, nil)
    let used = CTFontCopyPostScriptName(font) as String == "SFRounded-Heavy" ? font : fallback
    let attributed = NSAttributedString(string: "G", attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): used,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(lime.1),
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    c.textPosition = CGPoint(x: (100 * s - bounds.width) / 2 - bounds.minX,
                             y: (100 * s - bounds.height) / 2 - bounds.minY)
    CTLineDraw(line, c)
    // the piece that left
    box(c, 52, 40, 34, 20, 4, s, fill: rgb(paper))
    box(c, 64, 60, 22, 20, 6, s, fill: rgb(lime.0), rotate: 18)
}

let concepts: [(String, Draw)] = [
    ("1 · Left its place", leftItsPlace),
    ("2 · On its way out", onItsWayOut),
    ("3 · A place empty", aPlaceEmpty),
    ("4 · The tick", theTick),
    ("5 · Minus", minus),
    ("6 · Pair, one faded", pairFaded),
    ("7 · Through the slot", throughSlot),
    ("8 · Down and out", downAndOut),
    ("9 · Door ajar", doorAjar),
    ("10 · The G", theG),
]

// ============================================================ output

func render(_ draw: Draw, size: Int) -> CGImage? {
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: 0, space: space,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.setAllowsAntialiasing(true)
    draw(ctx, CGFloat(size) / 100)
    return ctx.makeImage()
}

func write(_ image: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let columns = CommandLine.arguments.count > 2 ? (Int(CommandLine.arguments[2]) ?? 5) : 5
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let big = 220, small = 29, pad = 24, gapX = 20, gapY = 18, labelH = 40, smallGap = 26
let rows = Int(ceil(Double(concepts.count) / Double(columns)))
let cellH = big + smallGap + small + labelH
let sheetW = pad * 2 + columns * big + (columns - 1) * gapX
let sheetH = pad * 2 + rows * cellH + (rows - 1) * gapY
guard let sheet = CGContext(data: nil, width: sheetW, height: sheetH, bitsPerComponent: 8,
                            bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { exit(1) }
sheet.setFillColor(rgb(0xE6E6EA)); sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))

let labelFont = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 18, nil)
for (index, concept) in concepts.enumerated() {
    let col = index % columns, row = index / columns
    let x = pad + col * (big + gapX)
    let cellTop = sheetH - pad - row * (cellH + gapY)

    guard let bigImage = render(concept.1, size: 1024),
          let smallImage = render(concept.1, size: small * 4) else { continue }
    write(bigImage, to: outDir.appendingPathComponent("icon-\(index + 1).png"))

    // iOS masks icons itself, so preview the art inside the squircle it will actually wear
    func drawMasked(_ image: CGImage, _ rect: CGRect) {
        sheet.saveGState()
        sheet.addPath(CGPath(roundedRect: rect, cornerWidth: rect.width * 0.22,
                             cornerHeight: rect.width * 0.22, transform: nil))
        sheet.clip()
        sheet.draw(image, in: rect)
        sheet.restoreGState()
    }
    drawMasked(bigImage, CGRect(x: CGFloat(x), y: CGFloat(cellTop - big),
                                width: CGFloat(big), height: CGFloat(big)))
    drawMasked(smallImage, CGRect(x: CGFloat(x + (big - small) / 2),
                                  y: CGFloat(cellTop - big - smallGap - small),
                                  width: CGFloat(small), height: CGFloat(small)))

    let attributed = NSAttributedString(string: concept.0, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): labelFont,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(ink),
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    sheet.textPosition = CGPoint(x: CGFloat(x) + (CGFloat(big) - bounds.width) / 2,
                                 y: CGFloat(cellTop - cellH + 14))
    CTLineDraw(line, sheet)
}
if let out = sheet.makeImage() {
    write(out, to: outDir.appendingPathComponent("sheet.png"))
    print("wrote \(outDir.path)/sheet.png — \(concepts.count) concepts, big + 29pt")
}
