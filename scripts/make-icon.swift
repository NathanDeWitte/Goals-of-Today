// Renders packaging/AppIcon.icns — white squircle card with the widget's
// purple checkbox + progress bar. Run via `make icon`.
import AppKit

let canvas: CGFloat = 1024

func renderIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: canvas, height: canvas))
    img.lockFocus()

    // macOS icon grid: content squircle inset 100pt, radius ~185
    let card = NSRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: card, xRadius: 185, yRadius: 185)

    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -12), blur: 36,
        color: NSColor.black.withAlphaComponent(0.3).cgColor)
    NSColor.white.setFill()
    squircle.fill()
    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    NSColor(srgbRed: 0xe9 / 255, green: 0xec / 255, blue: 0xf0 / 255, alpha: 1).setStroke()
    squircle.lineWidth = 8
    squircle.stroke()

    let purple = NSColor(srgbRed: 0x55 / 255, green: 0x00 / 255, blue: 0xff / 255, alpha: 1)

    // Purple checkbox, centered slightly above the middle
    let boxSize: CGFloat = 380
    let box = NSRect(x: (canvas - boxSize) / 2, y: 350, width: boxSize, height: boxSize)
    purple.setFill()
    NSBezierPath(roundedRect: box, xRadius: 96, yRadius: 96).fill()

    // White checkmark
    let check = NSBezierPath()
    check.lineWidth = 56
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.move(to: NSPoint(x: box.minX + boxSize * 0.27, y: box.minY + boxSize * 0.50))
    check.line(to: NSPoint(x: box.minX + boxSize * 0.43, y: box.minY + boxSize * 0.32))
    check.line(to: NSPoint(x: box.minX + boxSize * 0.74, y: box.minY + boxSize * 0.66))
    NSColor.white.setStroke()
    check.stroke()

    // Progress bar below, ~2/3 filled
    let track = NSRect(x: 282, y: 232, width: 460, height: 36)
    NSColor(srgbRed: 0xe9 / 255, green: 0xec / 255, blue: 0xf0 / 255, alpha: 1).setFill()
    NSBezierPath(roundedRect: track, xRadius: 18, yRadius: 18).fill()
    purple.setFill()
    NSBezierPath(
        roundedRect: NSRect(x: track.minX, y: track.minY, width: track.width * 0.66, height: track.height),
        xRadius: 18, yRadius: 18
    ).fill()

    img.unlockFocus()
    return img
}

let img = renderIcon()
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not render icon")
}
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png")
try! png.write(to: out)
print("wrote \(out.path)")
