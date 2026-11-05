#!/usr/bin/env swift
// Generates Resources/AppIcon.icns.  Usage: swift scripts/make-icon.swift
import AppKit

let outDir = URL(fileURLWithPath: "build/AppIcon.iconset")
try? FileManager.default.removeItem(at: outDir)
try! FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px) / 1024
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: s, y: s)

    // macOS icon grid: 824×824 body centered in 1024, ~185 corner radius.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let drop = NSShadow()
    drop.shadowColor = NSColor.black.withAlphaComponent(0.3)
    drop.shadowBlurRadius = 24
    drop.shadowOffset = NSSize(width: 0, height: -10)
    drop.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGradient(colors: [
        NSColor(srgbRed: 1.00, green: 0.70, blue: 0.25, alpha: 1),
        NSColor(srgbRed: 1.00, green: 0.31, blue: 0.55, alpha: 1),
        NSColor(srgbRed: 0.45, green: 0.33, blue: 1.00, alpha: 1),
    ])!.draw(in: body, angle: 60)
    // soft top highlight
    NSGradient(colorsAndLocations:
        (NSColor.white.withAlphaComponent(0), 0.0),
        (NSColor.white.withAlphaComponent(0), 0.4),
        (NSColor.white.withAlphaComponent(0.2), 1.0))!
        .draw(in: body, angle: 90)

    // eyedropper glyph
    let config = NSImage.SymbolConfiguration(pointSize: 440, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "eyedropper.full", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let size = symbol.size
        let rect = NSRect(x: 512 - size.width / 2 + 20, y: 512 - size.height / 2 + 20,
                          width: size.width, height: size.height)
        let glyphShadow = NSShadow()
        glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        glyphShadow.shadowBlurRadius = 18
        glyphShadow.shadowOffset = NSSize(width: 0, height: -8)
        glyphShadow.set()
        symbol.draw(in: rect)
    }

    // the "picked" color drop under the tip
    let dot = NSRect(x: 214, y: 196, width: 120, height: 120)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: dot).fill()
    NSColor(srgbRed: 0.18, green: 0.85, blue: 0.75, alpha: 1).setFill()
    NSBezierPath(ovalIn: dot.insetBy(dx: 16, dy: 16)).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! render(base * scale).write(to: outDir.appendingPathComponent(name))
    }
}
try! render(1024).write(to: URL(fileURLWithPath: "docs/icon.png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", outDir.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "✅ Resources/AppIcon.icns" : "iconutil failed")
