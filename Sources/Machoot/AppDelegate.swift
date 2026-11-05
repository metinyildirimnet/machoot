import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum HotKeyID: UInt32 { case pick = 1, magnifier = 2 }

    private let prefs = Preferences.shared
    private let hud = HUDController()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var sampler: NSColorSampler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Machoot")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        prefs.onShortcutsChanged = { [weak self] in self?.registerHotKeys() }
        registerHotKeys()
    }

    private func registerHotKeys() {
        HotKeyManager.shared.set(id: HotKeyID.pick.rawValue, shortcut: prefs.pickShortcut) { [weak self] in
            self?.pickAtCursor()
        }
        HotKeyManager.shared.set(id: HotKeyID.magnifier.rawValue, shortcut: prefs.magnifierShortcut) { [weak self] in
            self?.pickWithMagnifier()
        }
    }

    // MARK: - Picking

    @objc func pickAtCursor() {
        guard ScreenSampler.hasPermission else {
            askForScreenPermission()
            return
        }
        let point = NSEvent.mouseLocation
        Task { @MainActor in
            do {
                let color = try await ScreenSampler.color(at: point)
                deliver(RGBColor(color), near: point)
            } catch {
                NSLog("Machoot: sampling failed: \(error)")
                NSSound.beep()
            }
        }
    }

    @objc func pickWithMagnifier() {
        let sampler = NSColorSampler()
        self.sampler = sampler
        sampler.show { [weak self] color in
            guard let self else { return }
            self.sampler = nil
            guard let color else { return } // user pressed Esc
            self.deliver(RGBColor(color), near: NSEvent.mouseLocation)
        }
    }

    private func deliver(_ color: RGBColor, near point: NSPoint) {
        let text = prefs.format.string(for: color)
        copy(text)
        prefs.addToHistory(color)
        if prefs.showHUD { hud.show(color: color, text: text, near: point) }
        if prefs.playSound { NSSound(named: "Tink")?.play() }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func askForScreenPermission() {
        // The system prompt only appears once; after that we must send the user to Settings.
        if ScreenSampler.requestPermission() { return }
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = """
            To read the color under the cursor, Machoot needs Screen Recording access. \
            Enable Machoot in System Settings → Privacy & Security → Screen & System Audio Recording, \
            then try again.

            Tip: the magnifier shortcut works without this permission.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { ScreenSampler.openPermissionSettings() }
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(item("Pick Color Under Cursor", shortcut: prefs.pickShortcut, action: #selector(pickAtCursor)))
        menu.addItem(item("Pick with Magnifier", shortcut: prefs.magnifierShortcut, action: #selector(pickWithMagnifier)))

        menu.addItem(.separator())
        if prefs.history.isEmpty {
            let empty = NSMenuItem(title: "No colors yet", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            menu.addItem(.sectionHeader(title: "Recent — click to copy"))
            for color in prefs.history {
                let mi = NSMenuItem(title: prefs.format.string(for: color), action: #selector(copyHistoryItem(_:)), keyEquivalent: "")
                mi.target = self
                mi.image = swatch(color)
                mi.representedObject = color.hex
                menu.addItem(mi)
            }
            let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
            clear.target = self
            menu.addItem(clear)
        }

        menu.addItem(.separator())
        let formatItem = NSMenuItem(title: "Copy Format", action: nil, keyEquivalent: "")
        let formatMenu = NSMenu()
        for format in ColorFormat.allCases {
            let mi = NSMenuItem(title: format.title, action: #selector(selectFormat(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = format.rawValue
            mi.state = format == prefs.format ? .on : .off
            formatMenu.addItem(mi)
        }
        formatItem.submenu = formatMenu
        menu.addItem(formatItem)

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let about = NSMenuItem(title: "About Machoot", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit Machoot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, shortcut: Shortcut?, action: Selector) -> NSMenuItem {
        let label = shortcut.map { "\(title)    \($0.displayString)" } ?? title
        let mi = NSMenuItem(title: label, action: action, keyEquivalent: "")
        mi.target = self
        return mi
    }

    private func swatch(_ color: RGBColor) -> NSImage {
        NSImage(size: NSSize(width: 14, height: 14), flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
            color.nsColor.setFill()
            path.fill()
            NSColor.separatorColor.setStroke()
            path.stroke()
            return true
        }
    }

    @objc private func copyHistoryItem(_ sender: NSMenuItem) {
        guard let hex = sender.representedObject as? String,
              let color = prefs.history.first(where: { $0.hex == hex }) else { return }
        copy(prefs.format.string(for: color))
    }

    @objc private func clearHistory() { prefs.clearHistory() }

    @objc private func selectFormat(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let f = ColorFormat(rawValue: raw) { prefs.format = f }
    }

    @objc private func showAbout() {
        let credits = NSMutableAttributedString(
            string: "Developed by Metin YILDIRIM (@cimendijital)\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.labelColor]
        )
        credits.append(NSAttributedString(
            string: "github.com/metinyildirimnet/machoot",
            attributes: [.font: NSFont.systemFont(ofSize: 11),
                         .link: URL(string: "https://github.com/metinyildirimnet/machoot")!]
        ))
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        credits.addAttribute(.paragraphStyle, value: centered, range: NSRange(location: 0, length: credits.length))

        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = "Machoot Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
