import AppKit

/// A color stored as sRGB components in 0...1.
struct RGBColor: Codable, Equatable {
    let r: Double
    let g: Double
    let b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = min(max(r, 0), 1)
        self.g = min(max(g, 0), 1)
        self.b = min(max(b, 0), 1)
    }

    init(_ color: NSColor) {
        let c = color.usingColorSpace(.sRGB) ?? color
        self.init(r: Double(c.redComponent), g: Double(c.greenComponent), b: Double(c.blueComponent))
    }

    var r8: Int { Int((r * 255).rounded()) }
    var g8: Int { Int((g * 255).rounded()) }
    var b8: Int { Int((b * 255).rounded()) }

    var nsColor: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }

    var hex: String { String(format: "#%02X%02X%02X", r8, g8, b8) }

    /// Hue in degrees, saturation and lightness in percent.
    var hsl: (h: Int, s: Int, l: Int) {
        let maxV = max(r, g, b), minV = min(r, g, b)
        let l = (maxV + minV) / 2
        let d = maxV - minV
        guard d > 0 else { return (0, 0, Int((l * 100).rounded())) }
        let s = d / (1 - abs(2 * l - 1))
        var h: Double
        switch maxV {
        case r: h = ((g - b) / d).truncatingRemainder(dividingBy: 6)
        case g: h = (b - r) / d + 2
        default: h = (r - g) / d + 4
        }
        h *= 60
        if h < 0 { h += 360 }
        return (Int(h.rounded()) % 360, Int((s * 100).rounded()), Int((l * 100).rounded()))
    }
}

enum ColorFormat: String, CaseIterable, Identifiable {
    case hex, hexNoHash, rgb, hsl, swiftUI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hex: return "HEX  (#1A2B3C)"
        case .hexNoHash: return "HEX without #  (1A2B3C)"
        case .rgb: return "RGB  (rgb(26, 43, 60))"
        case .hsl: return "HSL  (hsl(210, 40%, 17%))"
        case .swiftUI: return "SwiftUI  (Color(red:green:blue:))"
        }
    }

    func string(for c: RGBColor) -> String {
        switch self {
        case .hex: return c.hex
        case .hexNoHash: return String(c.hex.dropFirst())
        case .rgb: return "rgb(\(c.r8), \(c.g8), \(c.b8))"
        case .hsl:
            let v = c.hsl
            return "hsl(\(v.h), \(v.s)%, \(v.l)%)"
        case .swiftUI:
            return String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", c.r, c.g, c.b)
        }
    }
}
