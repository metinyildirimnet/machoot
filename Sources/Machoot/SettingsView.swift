import AppKit
import Carbon.HIToolbox
import Combine
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs = Preferences.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var hasScreenPermission = ScreenSampler.hasPermission

    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("Shortcuts") {
                LabeledContent("Pick color under cursor") {
                    ShortcutRecorder(shortcut: $prefs.pickShortcut)
                }
                LabeledContent("Pick with magnifier") {
                    ShortcutRecorder(shortcut: $prefs.magnifierShortcut)
                }
            }

            Section("Output") {
                Picker("Copy format", selection: $prefs.format) {
                    ForEach(ColorFormat.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Show preview next to cursor", isOn: $prefs.showHUD)
                Toggle("Play sound", isOn: $prefs.playSound)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }

                LabeledContent("Screen Recording") {
                    if hasScreenPermission {
                        Label("Granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button("Grant Access…") {
                            if !ScreenSampler.requestPermission() { ScreenSampler.openPermissionSettings() }
                        }
                    }
                }
                Text("Needed only for instant picking under the cursor. The magnifier mode works without it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
        .onReceive(timer) { _ in hasScreenPermission = ScreenSampler.hasPermission }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Machoot: launch at login failed: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

/// Click to record a new global shortcut. Esc cancels, the × button clears it.
struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut?
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { isRecording ? stop() : start() }) {
                Text(isRecording ? "Type shortcut…" : (shortcut?.displayString ?? "Record Shortcut"))
                    .font(.system(.body, design: shortcut == nil || isRecording ? .default : .monospaced))
                    .frame(minWidth: 130)
            }
            if shortcut != nil && !isRecording {
                Button(action: { shortcut = nil }) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear shortcut")
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        isRecording = true
        HotKeyManager.shared.suspend()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if Int(event.keyCode) == kVK_Escape && mods.isEmpty {
                stop()
            } else if let new = Shortcut(event: event) {
                shortcut = new
                stop()
            } else {
                NSSound.beep()
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if isRecording {
            isRecording = false
            HotKeyManager.shared.resume()
        }
    }
}
