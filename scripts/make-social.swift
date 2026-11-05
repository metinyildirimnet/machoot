#!/usr/bin/env swift
// Renders docs/social/x-card.png (1600×900) for sharing on X / social media.
// Usage: swift scripts/make-social.swift
import AppKit

let W: CGFloat = 1600, H: CGFloat = 900

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular, mono: Bool = false) -> NSFont {
    mono ? .monospacedSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight)
}

@discardableResult
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ f: NSFont, _ c: NSColor, kern: CGFloat = 0) -> CGFloat {
    let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: c, .kern: kern]
    (s as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
    return (s as NSString).size(withAttributes: attrs).width
}

func width(_ s: String, _ f: NSFont) -> CGFloat { (s as NSString).size(withAttributes: [.font: f]).width }

func rounded(_ r: NSRect, _ radius: CGFloat, _ fill: NSColor, shadow: CGFloat = 0, shadowAlpha: CGFloat = 0.45) {
    NSGraphicsContext.saveGraphicsState()
    if shadow > 0 {
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(shadowAlpha)
        sh.shadowBlurRadius = shadow
        sh.shadowOffset = NSSize(width: 0, height: -shadow / 3)
        sh.set()
    }
    fill.setFill()
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
    NSGraphicsContext.restoreGraphicsState()
}

func glow(center: NSPoint, radius: CGFloat, color: NSColor) {
    let ctx = NSGraphicsContext.current!.cgContext
    let c = color.usingColorSpace(.sRGB)!
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let g = CGGradient(colorsSpace: space, colors: [c.cgColor, c.withAlphaComponent(0).cgColor] as CFArray,
                       locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

func drawCursor(at p: NSPoint, scale s: CGFloat) {
    let pts: [(CGFloat, CGFloat)] = [(0, 0), (0, 21), (5, 16), (8.5, 24), (12, 22.5), (8.5, 15), (15, 15)]
    let path = NSBezierPath()
    path.move(to: p)
    for q in pts.dropFirst() { path.line(to: NSPoint(x: p.x + q.0 * s, y: p.y + q.1 * s)) }
    path.close()
    path.lineJoinStyle = .round
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.4)
    sh.shadowBlurRadius = 6
    sh.set()
    NSColor.white.setStroke()
    path.lineWidth = 3 * s
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
    NSColor.black.setFill()
    path.fill()
}

func draw() {
    // Background
    NSGradient(colors: [rgb(0x221A3D), rgb(0x120F1F)])!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: 90)
    glow(center: NSPoint(x: 1300, y: 120), radius: 620, color: rgb(0xFF4F8B, 0.28))
    glow(center: NSPoint(x: 120, y: 900), radius: 560, color: rgb(0xFFB23F, 0.18))
    glow(center: NSPoint(x: 700, y: 300), radius: 500, color: rgb(0x7354FF, 0.22))

    // ---- Left column
    let x: CGFloat = 110
    if let icon = NSImage(contentsOfFile: "docs/icon.png") {
        icon.draw(in: NSRect(x: x - 22, y: 118, width: 176, height: 176), from: .zero, operation: .sourceOver,
                  fraction: 1, respectFlipped: true, hints: nil)
    }
    text("Machoot", x, 300, font(104, .heavy), .white, kern: -2)

    let tag = font(46, .bold)
    var cx = x
    cx += text("Hover. Press ", cx, 440, tag, .white)
    cx += text("⌃⌥C", cx, 440, font(46, .bold, mono: true), rgb(0xFF7AA8))
    text(".", cx, 440, tag, .white)
    text("Get the color code.", x, 500, tag, .white)

    text("Free & open-source color picker", x, 586, font(28, .medium), rgb(0xFFFFFF, 0.65))
    text("for the macOS menu bar.", x, 624, font(28, .medium), rgb(0xFFFFFF, 0.65))

    // Feature chips
    var chipX = x
    for chip in ["HEX · RGB · HSL", "History", "Custom shortcuts"] {
        let f = font(21, .semibold)
        let w = width(chip, f) + 36
        rounded(NSRect(x: chipX, y: 694, width: w, height: 44), 22, rgb(0xFFFFFF, 0.1))
        text(chip, chipX + 18, 704, f, rgb(0xFFFFFF, 0.9))
        chipX += w + 12
    }

    // Repo link
    text("github.com/metinyildirimnet/machoot", x, 784, font(24, .semibold, mono: true), rgb(0xFFB86B))

    // ---- Right: browser mockup
    let win = NSRect(x: 880, y: 130, width: 600, height: 560)
    rounded(win, 20, .white, shadow: 50, shadowAlpha: 0.55)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: win, xRadius: 20, yRadius: 20).addClip()
    rgb(0xF1F1F4).setFill()
    NSRect(x: win.minX, y: win.minY, width: win.width, height: 56).fill()
    for (i, c) in [0xFF5F57, 0xFEBC2E, 0x28C840].enumerated() {
        rgb(UInt32(c)).setFill()
        NSBezierPath(ovalIn: NSRect(x: win.minX + 22 + CGFloat(i) * 28, y: win.minY + 20, width: 16, height: 16)).fill()
    }
    rounded(NSRect(x: win.minX + 150, y: win.minY + 12, width: 380, height: 32), 9, .white)
    text("example.com/palettes", win.minX + 260, win.minY + 18, font(16), .gray)

    // palette stripes
    let colors: [UInt32] = [0xFF6B6B, 0xFFB347, 0xFFD93D, 0x4ECDC4, 0x5B5FEF]
    let top = win.minY + 56
    let sw = win.width / CGFloat(colors.count)
    for (i, c) in colors.enumerated() {
        rgb(c).setFill()
        NSRect(x: win.minX + CGFloat(i) * sw, y: top, width: sw + 1, height: win.maxY - top).fill()
    }
    NSGraphicsContext.restoreGraphicsState()

    // cursor + preview HUD (same layout as the app, scaled up)
    let cursor = NSPoint(x: win.minX + sw * 2 + sw / 2 - 10, y: 360)
    let hud = NSRect(x: cursor.x + 30, y: cursor.y + 34, width: 300, height: 76)
    rounded(hud, 18, NSColor(white: 0.98, alpha: 0.98), shadow: 30)
    let sr = NSRect(x: hud.minX + 16, y: hud.minY + 15, width: 46, height: 46)
    rounded(sr, 10, rgb(0xFFD93D))
    NSColor.black.withAlphaComponent(0.15).setStroke()
    NSBezierPath(roundedRect: sr.insetBy(dx: 0.5, dy: 0.5), xRadius: 10, yRadius: 10).stroke()
    text("#FFD93D", hud.minX + 78, hud.minY + 10, font(26, .bold, mono: true), rgb(0x1D1D1F))
    text("Copied to clipboard", hud.minX + 79, hud.minY + 44, font(17), .gray)
    drawCursor(at: cursor, scale: 2)

    // key-press overlay
    let keys = ["⌃", "⌥", "C"]
    let kSize: CGFloat = 84, kGap: CGFloat = 14
    let pillW = CGFloat(keys.count) * kSize + CGFloat(keys.count - 1) * kGap + 40
    let pill = NSRect(x: win.midX - pillW / 2, y: win.maxY - 70, width: pillW, height: kSize + 40)
    rounded(pill, 26, rgb(0x15121F, 0.92), shadow: 30)
    for (i, k) in keys.enumerated() {
        let kr = NSRect(x: pill.minX + 20 + CGFloat(i) * (kSize + kGap), y: pill.minY + 20, width: kSize, height: kSize)
        rounded(kr, 16, rgb(0xFFFFFF, 0.14))
        let f = font(40, .semibold)
        text(k, kr.midX - width(k, f) / 2, kr.minY + 17, f, .white)
    }
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let cg = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
cg.translateBy(x: 0, y: H)
cg.scaleBy(x: 1, y: -1)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
draw()
NSGraphicsContext.restoreGraphicsState()

try! FileManager.default.createDirectory(atPath: "docs/social", withIntermediateDirectories: true)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/social/x-card.png"))
print("✅ docs/social/x-card.png")
