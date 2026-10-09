#if os(macOS)
import AppKit
import SwiftUI
import ToiletCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var toiletController: ToiletWindowController?
    private var settingsWindow: NSWindow?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let session = ToiletSession.shared
        session.askConfirmation = { message, permanent, done in
            let ok = Alerts.confirm(
                title: permanent ? "Really send these to the abyss?" : "That's a lot to flush",
                message: message,
                confirmTitle: permanent ? "Delete Forever" : "Flush to Trash",
                style: permanent ? .critical : .warning
            )
            done(ok)
        }
        session.playPlop = {
            if SettingsStore.shared.soundsEnabled {
                SoundPlayer.play(named: "plop")
            }
        }
        session.playFlush = {
            if SettingsStore.shared.soundsEnabled {
                SoundPlayer.play(named: "flush")
            }
        }

        installMainMenu()

        toiletController = ToiletWindowController(session: session)
        toiletController?.showWindow(nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event) ?? event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc func showSettings(_ sender: Any?) {
        if settingsWindow == nil {
            let hosting = NSHostingController(
                rootView: SettingsView(store: SettingsStore.shared, session: ToiletSession.shared)
            )
            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 560),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Desktop Toilet"
            window.contentViewController = hosting
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func flushBowl(_ sender: Any?) {
        ToiletSession.shared.requestFlush()
    }

    @objc func undoLastFlush(_ sender: Any?) {
        ToiletSession.shared.undoLastFlush()
    }

    @objc func emptyBowl(_ sender: Any?) {
        ToiletSession.shared.emptyBowl()
    }

    @objc func resetPosition(_ sender: Any?) {
        toiletController?.resetPosition()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let session = ToiletSession.shared
        if menuItem.action == #selector(undoLastFlush(_:)) {
            return session.canUndo
        }
        if menuItem.action == #selector(flushBowl(_:)) {
            return !session.queue.isEmpty && !session.isFlushing
        }
        if menuItem.action == #selector(emptyBowl(_:)) {
            return !session.queue.isEmpty
        }
        return true
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        guard toiletController?.window?.isKeyWindow == true else {
            return event
        }
        let command = event.modifierFlags.contains(.command)
        let chars = event.charactersIgnoringModifiers ?? ""
        if command && chars == "f" {
            ToiletSession.shared.requestFlush()
            return nil
        }
        if command && chars == "z" {
            ToiletSession.shared.undoLastFlush()
            return nil
        }
        if event.keyCode == 36 || event.keyCode == 49 {
            ToiletSession.shared.requestFlush()
            return nil
        }
        return event
    }

    /// Hidden main menu so ⌘F / ⌘Z work while the toilet is focused.
    private func installMainMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Flush Bowl", action: #selector(flushBowl(_:)), keyEquivalent: "f")
        appMenu.addItem(withTitle: "Undo Last Flush", action: #selector(undoLastFlush(_:)), keyEquivalent: "z")
        appMenu.addItem(withTitle: "Empty Bowl", action: #selector(emptyBowl(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Desktop Toilet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = menu
    }
}
#endif
