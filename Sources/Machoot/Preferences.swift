import AppKit
import Carbon.HIToolbox
import Combine

final class Preferences: ObservableObject {
    static let shared = Preferences()

    static let defaultPickShortcut = Shortcut(keyCode: kVK_ANSI_C, modifiers: controlKey | optionKey)
    static let defaultMagnifierShortcut = Shortcut(keyCode: kVK_ANSI_X, modifiers: controlKey | optionKey)
    static let historyLimit = 12

    private let defaults = UserDefaults.standard

    /// Called whenever either shortcut changes.
    var onShortcutsChanged: (() -> Void)?

    @Published var pickShortcut: Shortcut? {
        didSet { store(pickShortcut, key: Keys.pick); onShortcutsChanged?() }
    }

    @Published var magnifierShortcut: Shortcut? {
        didSet { store(magnifierShortcut, key: Keys.magnifier); onShortcutsChanged?() }
    }

    @Published var format: ColorFormat {
        didSet { defaults.set(format.rawValue, forKey: Keys.format) }
    }

    @Published var showHUD: Bool {
        didSet { defaults.set(showHUD, forKey: Keys.hud) }
    }

    @Published var playSound: Bool {
        didSet { defaults.set(playSound, forKey: Keys.sound) }
    }

    @Published private(set) var history: [RGBColor] {
        didSet { defaults.set(try? JSONEncoder().encode(history), forKey: Keys.history) }
    }

    private enum Keys {
        static let pick = "pickShortcut"
        static let magnifier = "magnifierShortcut"
        static let format = "format"
        static let hud = "showHUD"
        static let sound = "playSound"
        static let history = "history"
    }

    private init() {
        pickShortcut = Preferences.loadShortcut(Keys.pick, default: Preferences.defaultPickShortcut)
        magnifierShortcut = Preferences.loadShortcut(Keys.magnifier, default: Preferences.defaultMagnifierShortcut)
        format = ColorFormat(rawValue: defaults.string(forKey: Keys.format) ?? "") ?? .hex
        showHUD = defaults.object(forKey: Keys.hud) as? Bool ?? true
        playSound = defaults.object(forKey: Keys.sound) as? Bool ?? false
        history = (defaults.data(forKey: Keys.history)).flatMap { try? JSONDecoder().decode([RGBColor].self, from: $0) } ?? []
    }

    func addToHistory(_ color: RGBColor) {
        var h = history.filter { $0.hex != color.hex }
        h.insert(color, at: 0)
        history = Array(h.prefix(Preferences.historyLimit))
    }

    func clearHistory() { history = [] }

    // A missing key means "use the default"; an empty Data value means "cleared by the user".
    private static func loadShortcut(_ key: String, default value: Shortcut) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return value }
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }

    private func store(_ shortcut: Shortcut?, key: String) {
        let data = shortcut.flatMap { try? JSONEncoder().encode($0) } ?? Data()
        defaults.set(data, forKey: key)
    }
}
