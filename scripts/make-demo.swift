#!/usr/bin/env swift
// Renders docs/demo.gif — an illustrative animation of Machoot's flow.
// Usage: swift scripts/make-demo.swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

let W: CGFloat = 800, H: CGFloat = 500

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let tiles: [UInt32] = [0xFF6B6B, 0xFFB347, 0xFFD93D, 0x4ECDC4, 0x5B5FEF]
let tileW: CGFloat = 104, tileH: CGFloat = 150, tileGap: CGFloat = 14, tileX0: CGFloat = 104, tileY: CGFloat = 190
func tileRect(_ i: Int) -> NSRect {
    NSRect(x: tileX0 + CGFloat(i) * (tileW + tileGap), y: tileY, width: tileW, height: tileH)
}
let menuIcon = NSPoint(x: W - 92, y: 13)

struct Frame {
    var cursor: NSPoint
    var keycap = false
    var hud: UInt32? = nil
    var history: [UInt32] = []
    var menuOpen = false
    var delay: Double = 1.0 / 15
}

// MARK: - Drawing helpers

func text(_ s: String, at p: NSPoint, size: CGFloat, weight: NSFont.Weight = .regular,
          color: NSColor = .black, mono: Bool = false) {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    (s as NSString).draw(at: p, withAttributes: [.font: font, .foregroundColor: color])
}

func textWidth(_ s: String, size: CGFloat, weight: NSFont.Weight = .regular, mono: Bool = false) -> CGFloat {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    return (s as NSString).size(withAttributes: [.font: font]).width
}

func rounded(_ r: NSRect, _ radius: CGFloat, fill: NSColor, shadow: CGFloat = 0) {
    NSGraphicsContext.saveGraphicsState()
    if shadow > 0 {
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.35)
        sh.shadowBlurRadius = shadow
        sh.shadowOffset = NSSize(width: 0, height: -shadow / 3) // flipped context
        sh.set()
    }
    fill.setFill()
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
    NSGraphicsContext.restoreGraphicsState()
}

func symbol(_ name: String, in r: NSRect, color: NSColor) {
    let cfg = NSImage.SymbolConfiguration(pointSize: r.height, weight: .medium).applying(.init(paletteColors: [color]))
    NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(cfg)?
        .draw(in: r, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}

func swatch(_ hex: UInt32, _ r: NSRect, radius: CGFloat) {
    rounded(r, radius, fill: rgb(hex))
    NSColor.black.withAlphaComponent(0.15).setStroke()
    NSBezierPath(roundedRect: r.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius).stroke()
}

func hexString(_ h: UInt32) -> String { String(format: "#%06X", h) }

// MARK: - Scene

func drawScene(_ f: Frame) {
    // desktop
    NSGradient(colors: [rgb(0x2B2545), rgb(0x1A1828)])!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: 90)

    // menu bar
    NSColor.white.withAlphaComponent(0.1).setFill()
    NSRect(x: 0, y: 0, width: W, height: 26).fill()
    text("Browser", at: NSPoint(x: 16, y: 5), size: 13, weight: .bold, color: .white)
    for (i, item) in ["File", "Edit", "View", "Window"].enumerated() {
        text(item, at: NSPoint(x: 90 + CGFloat(i) * 52, y: 5), size: 13, color: .white)
    }
    if f.menuOpen {
        rounded(NSRect(x: menuIcon.x - 13, y: 2, width: 26, height: 22), 5, fill: NSColor.white.withAlphaComponent(0.25))
    }
    symbol("eyedropper", in: NSRect(x: menuIcon.x - 8, y: 5, width: 16, height: 16), color: .white)
    text("Wed 9:41", at: NSPoint(x: W - 70, y: 5), size: 13, color: .white)

    // browser window
    let win = NSRect(x: 60, y: 50, width: 680, height: 420)
    rounded(win, 12, fill: .white, shadow: 24)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: win, xRadius: 12, yRadius: 12).addClip()
    rgb(0xF1F1F4).setFill()
    NSRect(x: win.minX, y: win.minY, width: win.width, height: 40).fill()
    for (i, c) in [0xFF5F57, 0xFEBC2E, 0x28C840].enumerated() {
        rgb(UInt32(c)).setFill()
        NSBezierPath(ovalIn: NSRect(x: win.minX + 16 + CGFloat(i) * 20, y: win.minY + 14, width: 12, height: 12)).fill()
    }
    rounded(NSRect(x: win.midX - 140, y: win.minY + 8, width: 280, height: 24), 7, fill: .white)
    text("example.com/palettes/sunset", at: NSPoint(x: win.midX - 92, y: win.minY + 12), size: 12, color: .gray)
    NSGraphicsContext.restoreGraphicsState()

    text("Sunset Palette", at: NSPoint(x: tileX0, y: 112), size: 26, weight: .bold, color: rgb(0x1D1D1F))
    text("Five warm-to-cool colors for your next project", at: NSPoint(x: tileX0, y: 148), size: 13, color: .gray)
    for (i, c) in tiles.enumerated() { rounded(tileRect(i), 12, fill: rgb(c)) }
    for (i, w) in [520, 440, 480].enumerated() {
        rounded(NSRect(x: tileX0, y: 372 + CGFloat(i) * 20, width: CGFloat(w), height: 9), 4.5, fill: rgb(0xE8E8ED))
    }

    // floating preview (same layout as the app's HUD)
    if let c = f.hud {
        let hex = hexString(c)
        let w = 46 + max(textWidth(hex, size: 13, weight: .semibold, mono: true), textWidth("Copied to clipboard", size: 10)) + 10
        let r = NSRect(x: f.cursor.x + 16, y: f.cursor.y + 16, width: w, height: 40)
        rounded(r, 10, fill: NSColor(white: 0.97, alpha: 0.97), shadow: 14)
        swatch(c, NSRect(x: r.minX + 10, y: r.minY + 8, width: 24, height: 24), radius: 5)
        text(hex, at: NSPoint(x: r.minX + 43, y: r.minY + 5), size: 13, weight: .semibold, color: rgb(0x1D1D1F), mono: true)
        text("Copied to clipboard", at: NSPoint(x: r.minX + 43, y: r.minY + 22), size: 10, color: .gray)
    }

    if f.menuOpen { drawMenu(f.history) }

    // key-press overlay
    if f.keycap {
        let keys = ["⌃", "⌥", "C"]
        let total = CGFloat(keys.count) * 52 + CGFloat(keys.count - 1) * 10 + 32
        let pill = NSRect(x: (W - total) / 2, y: H - 92, width: total, height: 72)
        rounded(pill, 16, fill: NSColor.black.withAlphaComponent(0.78), shadow: 16)
        for (i, k) in keys.enumerated() {
            let kr = NSRect(x: pill.minX + 16 + CGFloat(i) * 62, y: pill.minY + 10, width: 52, height: 52)
            rounded(kr, 10, fill: NSColor.white.withAlphaComponent(0.16))
            let kw = textWidth(k, size: 24, weight: .semibold)
            text(k, at: NSPoint(x: kr.midX - kw / 2, y: kr.minY + 10), size: 24, weight: .semibold, color: .white)
        }
    }

    drawCursor(at: f.cursor)
}

func drawMenu(_ history: [UInt32]) {
    let r = NSRect(x: menuIcon.x - 250, y: 30, width: 290, height: 64 + 22 + CGFloat(history.count) * 24 + 70)
    rounded(r, 10, fill: NSColor(white: 0.96, alpha: 0.98), shadow: 18)
    var y = r.minY + 8
    func row(_ title: String, _ key: String = "", color: NSColor = rgb(0x1D1D1F)) {
        text(title, at: NSPoint(x: r.minX + 14, y: y + 2), size: 13, color: color)
        if !key.isEmpty {
            text(key, at: NSPoint(x: r.maxX - 14 - textWidth(key, size: 13), y: y + 2), size: 13, color: .gray)
        }
        y += 24
    }
    func separator() {
        NSColor.black.withAlphaComponent(0.1).setFill()
        NSRect(x: r.minX + 12, y: y + 4, width: r.width - 24, height: 1).fill()
        y += 9
    }
    row("Pick Color Under Cursor", "⌃⌥C")
    row("Pick with Magnifier", "⌃⌥X")
    separator()
    text("Recent — click to copy", at: NSPoint(x: r.minX + 14, y: y + 3), size: 11, weight: .semibold, color: .gray)
    y += 22
    for c in history {
        swatch(c, NSRect(x: r.minX + 14, y: y + 4, width: 14, height: 14), radius: 3)
        text(hexString(c), at: NSPoint(x: r.minX + 36, y: y + 2), size: 13, color: rgb(0x1D1D1F))
        y += 24
    }
    separator()
    row("Copy Format", "▸")
    row("Settings…", "⌘,")
}

func drawCursor(at p: NSPoint) {
    let pts: [(CGFloat, CGFloat)] = [(0, 0), (0, 21), (5, 16), (8.5, 24), (12, 22.5), (8.5, 15), (15, 15)]
    let path = NSBezierPath()
    path.move(to: NSPoint(x: p.x + pts[0].0, y: p.y + pts[0].1))
    for q in pts.dropFirst() { path.line(to: NSPoint(x: p.x + q.0, y: p.y + q.1)) }
    path.close()
    path.lineJoinStyle = .round
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.35)
    sh.shadowBlurRadius = 3
    sh.set()
    NSColor.white.setStroke()
    path.lineWidth = 3
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
    NSColor.black.setFill()
    path.fill()
}

// MARK: - Timeline

var frames: [Frame] = []
var cursor = NSPoint(x: 420, y: 440)
var history: [UInt32] = []

func ease(_ t: CGFloat) -> CGFloat { t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2 }

func move(to target: NSPoint, steps: Int = 14) {
    let start = cursor
    for i in 1...steps {
        let t = ease(CGFloat(i) / CGFloat(steps))
        cursor = NSPoint(x: start.x + (target.x - start.x) * t, y: start.y + (target.y - start.y) * t)
        frames.append(Frame(cursor: cursor, history: history))
    }
}

frames.append(Frame(cursor: cursor, delay: 0.8))
for i in [0, 3, 4] {
    let r = tileRect(i)
    move(to: NSPoint(x: r.midX - 10, y: r.midY - 20))
    frames.append(Frame(cursor: cursor, history: history, delay: 0.25))
    frames.append(Frame(cursor: cursor, keycap: true, history: history, delay: 0.2))
    history.insert(tiles[i], at: 0)
    frames.append(Frame(cursor: cursor, keycap: true, hud: tiles[i], history: history, delay: 0.5))
    frames.append(Frame(cursor: cursor, hud: tiles[i], history: history, delay: 0.9))
}
move(to: NSPoint(x: menuIcon.x - 2, y: menuIcon.y - 4), steps: 16)
frames.append(Frame(cursor: cursor, history: history, delay: 0.25))
frames.append(Frame(cursor: cursor, history: history, menuOpen: true, delay: 2.8))

// MARK: - Encode

let out = URL(fileURLWithPath: "docs/demo.gif")
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)

for f in frames {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let base = NSGraphicsContext(bitmapImageRep: rep)!
    let cg = base.cgContext
    cg.translateBy(x: 0, y: H)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    drawScene(f)
    NSGraphicsContext.restoreGraphicsState()
    CGImageDestinationAddImage(dest, rep.cgImage!, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: f.delay, kCGImagePropertyGIFUnclampedDelayTime: f.delay],
    ] as CFDictionary)
}
CGImageDestinationFinalize(dest)
print("✅ docs/demo.gif (\(frames.count) frames)")
