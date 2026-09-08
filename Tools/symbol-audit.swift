// Renders every SF Symbol the app uses into one labelled sheet, and reports any name that doesn't
// resolve. Two things go wrong with symbol choices and neither shows up in a build:
// a name can silently not exist, and a symbol can carry a UI convention that inverts the meaning
// (a gift means "here's a present for you", a lightbulb means "here's a tip").
//
// Usage: swift Tools/symbol-audit.swift <out.png> <name> [name ...]
import AppKit
import CoreText
import UniformTypeIdentifiers

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
    print("usage: symbol-audit.swift <out.png> <symbol-name> ...")
    exit(2)
}
let outURL = URL(fileURLWithPath: args[0])
let names = Array(args.dropFirst()).sorted()

let cell: CGFloat = 150
let labelH: CGFloat = 34
let cols = 6
let rows = Int(ceil(Double(names.count) / Double(cols)))
let width = Int(CGFloat(cols) * cell)
let height = Int(CGFloat(rows) * (cell + labelH))

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                          bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { print("no context"); exit(1) }
ctx.setFillColor(CGColor(colorSpace: space, components: [1, 1, 1, 1])!)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

let font = CTFontCreateWithName("Menlo" as CFString, 13, nil)
let ink = CGColor(colorSpace: space, components: [0.13, 0.12, 0.16, 1])!
let missingColor = CGColor(colorSpace: space, components: [0.85, 0.1, 0.1, 1])!
var missing: [String] = []

for (index, name) in names.enumerated() {
    let col = index % cols, row = index / cols
    let x = CGFloat(col) * cell
    let top = CGFloat(height) - CGFloat(row) * (cell + labelH)

    var resolved = false
    if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil),
       let sized = image.withSymbolConfiguration(.init(pointSize: 62, weight: .medium)),
       let cg = sized.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        resolved = true
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let scale = min(80 / max(w, h), 1)
        let dw = w * scale, dh = h * scale
        ctx.draw(cg, in: CGRect(x: x + (cell - dw) / 2,
                                y: top - cell / 2 - dh / 2,
                                width: dw, height: dh))
    } else {
        missing.append(name)
    }

    let attributed = NSAttributedString(string: name, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): resolved ? ink : missingColor,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: x + max(4, (cell - bounds.width) / 2), y: top - cell - 16)
    CTLineDraw(line, ctx)
}

guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)
else { print("no image"); exit(1) }
CGImageDestinationAddImage(dest, out, nil)
_ = CGImageDestinationFinalize(dest)

print("wrote \(outURL.path) — \(names.count) symbols")
if missing.isEmpty {
    print("all names resolve")
} else {
    print("DOES NOT RESOLVE (\(missing.count)): \(missing.joined(separator: ", "))")
}
