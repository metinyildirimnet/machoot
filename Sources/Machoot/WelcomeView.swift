import AppKit
import ServiceManagement
import SwiftUI

/// Shown on first launch so people know the app lives in the menu bar.
struct WelcomeView: View {
    @ObservedObject var prefs = Preferences.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)

            VStack(spacing: 6) {
                Text("Machoot is running").font(.title2.bold())
                (Text("Look for the ") + Text(Image(systemName: "eyedropper")) + Text(" icon in your menu bar (top right)."))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                row(prefs.pickShortcut?.displayString ?? "—", "Copy the color under the cursor")
                row(prefs.magnifierShortcut?.displayString ?? "—", "Pick with the magnifier")
                row("Menu", "Recent colors, formats and settings")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            Toggle("Start Machoot automatically at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            Text("If you quit Machoot, reopen it from Spotlight (⌘ Space → “Machoot”) or the Applications folder.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if !ScreenSampler.hasPermission {
                    Button("Grant Screen Access…") {
                        if !ScreenSampler.requestPermission() { ScreenSampler.openPermissionSettings() }
                    }
                }
                Spacer()
                Button("Get Started", action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private func row(_ key: String, _ label: String) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .frame(width: 64, alignment: .leading)
            Text(label)
        }
    }
}
