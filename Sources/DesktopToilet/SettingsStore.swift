#if os(macOS)
import AppKit
import Combine
import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Keys {
        static let permanentDelete = "permanentDelete"
        static let confirmAfterItems = "confirmAfterItems"
        static let soundsEnabled = "soundsEnabled"
        static let windowFrame = "toiletFrame"
    }

    @Published var permanentDelete: Bool {
        didSet { UserDefaults.standard.set(permanentDelete, forKey: Keys.permanentDelete) }
    }

    @Published var confirmAfterItems: Int {
        didSet { UserDefaults.standard.set(confirmAfterItems, forKey: Keys.confirmAfterItems) }
    }

    @Published var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: Keys.soundsEnabled) }
    }

    let byteConfirmationThreshold: UInt64 = 1_000_000_000

    init() {
        let defaults = UserDefaults.standard
        permanentDelete = defaults.bool(forKey: Keys.permanentDelete)
        if defaults.object(forKey: Keys.confirmAfterItems) == nil {
            confirmAfterItems = 20
        } else {
            confirmAfterItems = max(1, defaults.integer(forKey: Keys.confirmAfterItems))
        }
        if defaults.object(forKey: Keys.soundsEnabled) == nil {
            soundsEnabled = true
        } else {
            soundsEnabled = defaults.bool(forKey: Keys.soundsEnabled)
        }
    }

    func saveFrame(_ frame: NSRect) {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: Keys.windowFrame)
    }

    func savedFrame() -> NSRect? {
        guard let raw = UserDefaults.standard.string(forKey: Keys.windowFrame) else {
            return nil
        }
        let rect = NSRectFromString(raw)
        if rect.width < 80 || rect.height < 80 {
            return nil
        }
        return rect
    }

    func clearSavedFrame() {
        UserDefaults.standard.removeObject(forKey: Keys.windowFrame)
    }
}
#endif
