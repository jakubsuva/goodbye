// Renders the Goodbye app icon — a tile that has left its place — as 1024×1024 PNGs.
// Usage: swift Tools/make-icon.swift Goodbye/Assets.xcassets/AppIcon.appiconset
//
// The icon used to be nine tiles with one empty, meaning "nine rooms, one gone". The rooms are
// gone from the app, so that meaning went with them. This is concept A from the second round of
// sketches: an empty outline where something used to sit, and the thing itself off to one side.
//
// A flat white ground read as washed-out next to another app's icon on the same Home Screen —
// the in-app palette is a wash *gradient* in every one of the day's eight hues, and the icon was
// the one place still using none of that. The ground is now that same gradient (Sun into Coral,
// real asset values, not invented ones); the tile stays HueViolet, which sits near-complementary
// against a warm orange ground for the strongest contrast the existing palette can give it.
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

func render(groundTop: RGB, groundBottom: RGB, tile: RGB, tileOutline: RGB, outline: RGB,
            to url: URL, size: Int = 1024) throws {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw NSError(domain: "icon", code: 1) }

    func cg(_ c: RGB, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: space, components: [c.r, c.g, c.b, a])! }
    // Drawn on a 100-unit grid with y measured from the top.
    let s = CGFloat(size) / 100
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * s, y: (100 - y - h) * s, width: w * s, height: h * s)
    }

    guard let gradient = CGGradient(
        colorsSpace: space, colors: [cg(groundTop), cg(groundBottom)] as CFArray, locations: [0, 1]
    ) else { throw NSError(domain: "icon", code: 4) }
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(size)),
                            options: [])

    // The place it left. A solid line reads as a hole in the gradient; a soft white halves that
    // to a seam instead, which is what the *shape* is meant to be, not the ground showing through.
    let empty = rect(15, 15, 40, 40)
    ctx.setStrokeColor(cg(outline, 0.9))
    ctx.setLineWidth(8.5 * s)
    ctx.addPath(CGPath(roundedRect: empty.insetBy(dx: 4.25 * s, dy: 4.25 * s),
                       cornerWidth: 10 * s, cornerHeight: 10 * s, transform: nil))
    ctx.strokePath()

    // The thing itself, tipped as it goes. A deep-tone edge gives it a boundary against the
    // gradient the flat fill alone didn't have — the first pass lost its silhouette wherever the
    // ground happened to run close to the same value.
    let moved = rect(42, 44, 43, 43)
    ctx.saveGState()
    ctx.translateBy(x: moved.midX, y: moved.midY)
    ctx.rotate(by: 16 * .pi / 180)
    ctx.translateBy(x: -moved.midX, y: -moved.midY)
    let tilePath = CGPath(roundedRect: moved, cornerWidth: 14 * s, cornerHeight: 14 * s, transform: nil)
    ctx.setFillColor(cg(tile))
    ctx.addPath(tilePath)
    ctx.fillPath()
    ctx.setStrokeColor(cg(tileOutline))
    ctx.setLineWidth(3 * s)
    ctx.addPath(tilePath)
    ctx.strokePath()
    ctx.restoreGState()

    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw NSError(domain: "icon", code: 2) }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "icon", code: 3) }
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
// HueSun / HueCoral / HueViolet / HueVioletDeep, straight from Assets.xcassets — the icon uses the
// app's own palette rather than a colour invented just for it.
try render(groundTop: RGB(0xFFB733), groundBottom: RGB(0xFF7A5C), tile: RGB(0xA78BFA),
           tileOutline: RGB(0x5B2FC0), outline: RGB(0xFFFFFF),
           to: outDir.appendingPathComponent("icon-light.png"))
try render(groundTop: RGB(0xA85400), groundBottom: RGB(0x7A2E14), tile: RGB(0xBFA6FF),
           tileOutline: RGB(0x2A1B57), outline: RGB(0xF3ECFF),
           to: outDir.appendingPathComponent("icon-dark.png"))
print("Icons written to \(outDir.path)")
