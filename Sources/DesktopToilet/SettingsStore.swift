#if os(macOS)
import AppKit
import Combine
import Foundation
import ToiletCore

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Keys {
        static let permanentDelete = "permanentDelete"
        static let confirmAfterItems = "confirmAfterItems"
        static let soundsEnabled = "soundsEnabled"
        static let windowFrame = "toiletFrame"
        static let toiletScale = "toiletScale"
        static let handleFinish = "handleFinish"
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

    @Published var toiletScale: ToiletDisplaySize {
        didSet { UserDefaults.standard.set(toiletScale.rawValue, forKey: Keys.toiletScale) }
    }

    @Published var handleFinish: ToiletHandleFinish {
        didSet { UserDefaults.standard.set(handleFinish.rawValue, forKey: Keys.handleFinish) }
    }

    var contentSize: NSSize {
        NSSize(width: toiletScale.width, height: toiletScale.height)
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
        if let raw = defaults.string(forKey: Keys.toiletScale),
           let scale = ToiletDisplaySize(rawValue: raw) {
            toiletScale = scale
        } else {
            toiletScale = .regular
        }
        if let raw = defaults.string(forKey: Keys.handleFinish),
           let finish = ToiletHandleFinish(rawValue: raw) {
            handleFinish = finish
        } else {
            handleFinish = .gold
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
