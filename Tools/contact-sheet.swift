// Composes simulator screenshots into one labelled contact sheet, for looking at every state of a
// screen side by side instead of one launch at a time.
//
// Usage: swift Tools/contact-sheet.swift <out.png> <cols> <label=file.png> [label=file.png ...]
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CoreText

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 3, let cols = Int(args[1]) else {
    print("usage: contact-sheet.swift <out.png> <cols> <label=file.png> ...")
    exit(2)
}
let outURL = URL(fileURLWithPath: args[0])
let items: [(label: String, url: URL)] = args.dropFirst(2).compactMap {
    guard let eq = $0.firstIndex(of: "=") else { return nil }
    return (String($0[$0.startIndex..<eq]), URL(fileURLWithPath: String($0[$0.index(after: eq)...])))
}

let tileW: CGFloat = 380
let labelH: CGFloat = 46
let gap: CGFloat = 18
let pad: CGFloat = 20

// Every shot is the same device, so one aspect ratio governs the grid.
guard let first = items.first,
      let probe = CGImageSourceCreateWithURL(first.url as CFURL, nil),
      let probeImage = CGImageSourceCreateImageAtIndex(probe, 0, nil)
else { print("cannot read \(items.first?.url.path ?? "-")"); exit(1) }
let aspect = CGFloat(probeImage.height) / CGFloat(probeImage.width)
let tileH = (tileW * aspect).rounded()

let rows = Int(ceil(Double(items.count) / Double(cols)))
let width = Int(pad * 2 + CGFloat(cols) * tileW + CGFloat(cols - 1) * gap)
let height = Int(pad * 2 + CGFloat(rows) * (tileH + labelH) + CGFloat(rows - 1) * gap)

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                          bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { print("cannot make context"); exit(1) }

ctx.setFillColor(CGColor(colorSpace: space, components: [0.90, 0.90, 0.92, 1])!)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

let font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 21, nil)
let inkColor = CGColor(colorSpace: space, components: [0.13, 0.12, 0.16, 1])!

for (index, item) in items.enumerated() {
    let col = index % cols, row = index / cols
    let x = pad + CGFloat(col) * (tileW + gap)
    // CoreGraphics y grows upward; lay the grid out from the top.
    let topY = CGFloat(height) - pad - CGFloat(row) * (tileH + labelH + gap)
    let imageY = topY - labelH - tileH

    if let src = CGImageSourceCreateWithURL(item.url as CFURL, nil),
       let image = CGImageSourceCreateImageAtIndex(src, 0, nil) {
        ctx.draw(image, in: CGRect(x: x, y: imageY, width: tileW, height: tileH))
    } else {
        print("skipped unreadable \(item.url.lastPathComponent)")
    }

    // .font / .foregroundColor live in AppKit; this script only has CoreText, so use its keys.
    let attributed = NSAttributedString(string: item.label, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): inkColor,
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: x + (tileW - bounds.width) / 2, y: topY - labelH + 16)
    CTLineDraw(line, ctx)
}

guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)
else { print("cannot encode"); exit(1) }
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { print("cannot write"); exit(1) }
print("wrote \(outURL.path) — \(items.count) tiles, \(width)×\(height)")
