import AppKit
import SwiftUI

/// A small, click-through floating panel shown next to the cursor after a pick.
final class HUDController {
    private let panel: NSPanel
    private var hideWork: DispatchWorkItem?

    init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    func show(color: RGBColor, text: String, near point: NSPoint) {
        hideWork?.cancel()

        let host = NSHostingView(rootView: HUDView(color: color, text: text))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host

        // Place below-right of the cursor so it never covers the sampled pixel.
        var origin = NSPoint(x: point.x + 16, y: point.y - 16 - size.height)
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) {
            let vf = screen.visibleFrame
            if origin.x + size.width > vf.maxX { origin.x = point.x - 16 - size.width }
            if origin.y < vf.minY { origin.y = point.y + 16 }
            origin.x = max(vf.minX, min(origin.x, vf.maxX - size.width))
            origin.y = max(vf.minY, min(origin.y, vf.maxY - size.height))
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let work = DispatchWorkItem { [weak self] in
            guard let panel = self?.panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                panel.animator().alphaValue = 0
            }, completionHandler: { panel.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
    }
}

private struct HUDView: View {
    let color: RGBColor
    let text: String

    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: color.nsColor))
                .frame(width: 24, height: 24)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.25), lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Text("Copied to clipboard")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .fixedSize()
    }
}
