#if os(macOS)
import AppKit
import SwiftUI

final class ToiletWindowController: NSWindowController, NSWindowDelegate {
    private let session: ToiletSession
    private let contentSize = NSSize(width: 236, height: 348)

    init(session: ToiletSession) {
        self.session = session
        let panel = ToiletPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        configure(panel)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResetPosition),
            name: .resetToiletPosition,
            object: nil
        )
    }

    @objc private func handleResetPosition() {
        resetPosition()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func resetPosition() {
        SettingsStore.shared.clearSavedFrame()
        if let panel = window {
            placeDefault(panel)
            SettingsStore.shared.saveFrame(panel.frame)
        }
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = window else { return }
        SettingsStore.shared.saveFrame(window.frame)
    }

    private func configure(_ panel: ToiletPanel) {
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.title = "Desktop Toilet"
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isMovableByWindowBackground = true
        panel.isExcludedFromWindowsMenu = true
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 8)
        panel.animationBehavior = .utilityWindow

        let root = ToiletView()
            .environmentObject(session)
            .frame(width: contentSize.width, height: contentSize.height)

        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: contentSize)
        hosting.autoresizingMask = [.width, .height]
        if let layer = hosting.layer {
            layer.backgroundColor = NSColor.clear.cgColor
        }
        panel.contentView = hosting
        panel.setContentSize(contentSize)

        panel.onDropURLs = { [weak session] urls in
            session?.drop(urls: urls)
        }
        panel.onDropTargeted = { [weak session] targeted in
            session?.isDropTargeted = targeted
        }

        restorePosition(panel)
        panel.orderFrontRegardless()
    }

    private func restorePosition(_ panel: NSWindow) {
        if let saved = SettingsStore.shared.savedFrame(), frameIsOnScreen(saved) {
            panel.setFrame(saved, display: false)
        } else {
            placeDefault(panel)
        }
    }

    private func placeDefault(_ panel: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.minY + 96
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
    }

    private func frameIsOnScreen(_ frame: NSRect) -> Bool {
        NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
    }
}
#endif
