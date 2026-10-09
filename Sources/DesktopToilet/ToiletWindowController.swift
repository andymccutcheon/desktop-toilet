#if os(macOS)
import AppKit
import Combine
import SwiftUI

final class ToiletWindowController: NSWindowController, NSWindowDelegate {
    private let session: ToiletSession
    private var cancellables = Set<AnyCancellable>()

    init(session: ToiletSession) {
        self.session = session
        let size = SettingsStore.shared.contentSize
        let panel = ToiletPanel(
            contentRect: NSRect(origin: .zero, size: size),
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
        SettingsStore.shared.$toiletScale
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyCurrentSize(animate: true)
            }
            .store(in: &cancellables)
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

        let size = SettingsStore.shared.contentSize
        let root = ToiletView()
            .environmentObject(session)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        hosting.wantsLayer = true
        if let layer = hosting.layer {
            layer.isOpaque = false
            layer.backgroundColor = NSColor.clear.cgColor
        }
        panel.contentView = hosting
        panel.setContentSize(size)

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
        let size = SettingsStore.shared.contentSize
        if let saved = SettingsStore.shared.savedFrame(), frameIsOnScreen(saved) {
            var frame = saved
            if abs(frame.width - size.width) > 8 || abs(frame.height - size.height) > 8 {
                let bottomCenter = NSPoint(x: frame.midX, y: frame.minY)
                frame.size = size
                frame.origin.x = bottomCenter.x - size.width / 2
                frame.origin.y = bottomCenter.y
            }
            panel.setFrame(frame, display: false)
        } else {
            placeDefault(panel)
        }
    }

    private func applyCurrentSize(animate: Bool) {
        guard let panel = window else { return }
        let size = SettingsStore.shared.contentSize
        var frame = panel.frame
        let bottomCenterX = frame.midX
        let bottomY = frame.minY
        frame.size = size
        frame.origin.x = bottomCenterX - size.width / 2
        frame.origin.y = bottomY
        panel.setFrame(frame, display: true, animate: animate)
        SettingsStore.shared.saveFrame(panel.frame)
    }

    private func placeDefault(_ panel: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = SettingsStore.shared.contentSize
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
