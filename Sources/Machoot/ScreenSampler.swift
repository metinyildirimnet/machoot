import AppKit
import ScreenCaptureKit

enum ScreenSampler {
    enum SampleError: Error { case noScreen, noPixel }

    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    @discardableResult
    static func requestPermission() -> Bool { CGRequestScreenCaptureAccess() }

    static func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Returns the on-screen color at `point` (AppKit global coordinates, bottom-left origin).
    static func color(at point: NSPoint) async throws -> NSColor {
        guard let primary = NSScreen.screens.first else { throw SampleError.noScreen }

        // ScreenCaptureKit uses global display coordinates with a top-left origin.
        let flipped = CGPoint(x: point.x, y: primary.frame.height - point.y)
        let origin = CGPoint(x: flipped.x.rounded(.down), y: flipped.y.rounded(.down))
        let rect = CGRect(origin: origin, size: CGSize(width: 1, height: 1))

        let image = try await SCScreenshotManager.captureImage(in: rect)
        guard image.width > 0, image.height > 0 else { throw SampleError.noPixel }

        // On Retina displays a 1×1 pt rect yields 2×2 px; pick the pixel under the hotspot.
        let px = min(Int((flipped.x - origin.x) * CGFloat(image.width)), image.width - 1)
        let py = min(Int((flipped.y - origin.y) * CGFloat(image.height)), image.height - 1)

        let rep = NSBitmapImageRep(cgImage: image)
        guard let color = rep.colorAt(x: px, y: py) else { throw SampleError.noPixel }
        return color.usingColorSpace(.sRGB) ?? color
    }
}
