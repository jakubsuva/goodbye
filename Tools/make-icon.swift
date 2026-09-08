// Renders the Goodbye app icon — a tile that has left its place — as 1024×1024 PNGs.
// Usage: swift Tools/make-icon.swift Goodbye/Assets.xcassets/AppIcon.appiconset
//
// The icon used to be nine tiles with one empty, meaning "nine rooms, one gone". The rooms are
// gone from the app, so that meaning went with them. This is concept A from the second round of
// sketches: an empty outline where something used to sit, and the thing itself off to one side.
//
// Both a light and a dark variant are generated even though the app's own dark mode is parked —
// the Home Screen picks the icon variant from the *system* appearance, not from the app.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct RGB {
    let r: CGFloat, g: CGFloat, b: CGFloat
    init(_ hex: UInt32) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
    }
}

func render(ground: RGB, tile: RGB, outline: RGB, to url: URL, size: Int = 1024) throws {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw NSError(domain: "icon", code: 1) }

    func cg(_ c: RGB) -> CGColor { CGColor(colorSpace: space, components: [c.r, c.g, c.b, 1])! }
    // Drawn on a 100-unit grid with y measured from the top.
    let s = CGFloat(size) / 100
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * s, y: (100 - y - h) * s, width: w * s, height: h * s)
    }

    ctx.setFillColor(cg(ground))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // The place it left. Heavier and darker than the first sketch: at 29pt a 6-unit line in
    // #DCDCE4 vanished and the icon collapsed into "a purple square".
    let empty = rect(15, 15, 40, 40)
    ctx.setStrokeColor(cg(outline))
    ctx.setLineWidth(8.5 * s)
    ctx.addPath(CGPath(roundedRect: empty.insetBy(dx: 4.25 * s, dy: 4.25 * s),
                       cornerWidth: 10 * s, cornerHeight: 10 * s, transform: nil))
    ctx.strokePath()

    // The thing itself, tipped as it goes.
    let moved = rect(42, 44, 43, 43)
    ctx.saveGState()
    ctx.translateBy(x: moved.midX, y: moved.midY)
    ctx.rotate(by: 16 * .pi / 180)
    ctx.translateBy(x: -moved.midX, y: -moved.midY)
    ctx.setFillColor(cg(tile))
    ctx.addPath(CGPath(roundedRect: moved, cornerWidth: 14 * s, cornerHeight: 14 * s, transform: nil))
    ctx.fillPath()
    ctx.restoreGState()

    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw NSError(domain: "icon", code: 2) }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "icon", code: 3) }
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try render(ground: RGB(0xFFFFFF), tile: RGB(0xA78BFA), outline: RGB(0xBFBFCE),
           to: outDir.appendingPathComponent("icon-light.png"))
try render(ground: RGB(0x241F2C), tile: RGB(0xBFA6FF), outline: RGB(0x5C5568),
           to: outDir.appendingPathComponent("icon-dark.png"))
print("Icons written to \(outDir.path)")
