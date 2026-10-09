#if os(macOS)
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var session: ToiletSession
    let onSettings: () -> Void

    init(session: ToiletSession = .shared, onSettings: @escaping () -> Void) {
        _session = ObservedObject(wrappedValue: session)
        self.onSettings = onSettings
    }

    var body: some View {
        Button("Flush Bowl") {
            session.requestFlush()
        }
        Button("Undo Last Flush") {
            session.undoLastFlush()
        }
        .disabled(!session.canUndo)
        Button("Empty Bowl") {
            session.emptyBowl()
        }
        .disabled(session.queue.isEmpty)
        Divider()
        Button("Settings…", action: onSettings)
        Divider()
        Button("Quit Desktop Toilet") {
            NSApp.terminate(nil)
        }
    }
}

@main
struct DesktopToiletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Desktop Toilet", systemImage: "drop.fill") {
            MenuBarContent {
                appDelegate.showSettings(nil)
            }
        }
    }
}
#endif
