#if os(macOS)
import AppKit
import SwiftUI
import ToiletCore

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var session: ToiletSession
    @State private var launchAtLogin = false
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Desktop Toilet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("A porcelain drop target for files you want out of sight. Default flush goes to Trash.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GroupBox("Safety") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Permanent delete (skip Trash)", isOn: permanentBinding)
                    Text("Off by default. When on, a flush erases items immediately and Undo cannot restore them.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Stepper(value: $store.confirmAfterItems, in: 1...999) {
                        Text("Ask before flushing more than \(store.confirmAfterItems) items")
                    }
                    Text("Anything over \(ByteFormat.string(store.byteConfirmationThreshold)) also asks first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(6)
            }

            GroupBox("Desktop") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Play plop and flush sounds", isOn: $store.soundsEnabled)
                    Toggle("Launch at login", isOn: loginBinding)
                    if let loginError {
                        Text(loginError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button("Reset toilet position") {
                        session.speechBubble = nil
                        NotificationCenter.default.post(name: .resetToiletPosition, object: nil)
                    }
                    Text("Drag the toilet to move it. Its spot is remembered. It has no Dock icon — use this menu extra to quit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(6)
            }

            GroupBox("In the bowl") {
                VStack(alignment: .leading, spacing: 6) {
                    if session.queue.isEmpty {
                        Text("Empty. Drop files from Finder onto the toilet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(session.queue.items) { item in
                            HStack {
                                Text(item.displayName)
                                    .lineLimit(1)
                                Spacer()
                                Button("Rescue") {
                                    session.rescue(item)
                                }
                            }
                        }
                    }
                }
                .padding(6)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear { refreshLogin() }
    }

    private var permanentBinding: Binding<Bool> {
        Binding(
            get: { store.permanentDelete },
            set: { newValue in
                if newValue && !store.permanentDelete {
                    let ok = Alerts.confirm(
                        title: "Turn on permanent delete?",
                        message: "Flushed items will be deleted immediately, not sent to Trash. Undo last flush will not work. This is off by default for a reason.",
                        confirmTitle: "Enable permanent delete",
                        style: .critical
                    )
                    store.permanentDelete = ok
                } else {
                    store.permanentDelete = newValue
                }
            }
        )
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { newValue in
                do {
                    try LoginItem.setEnabled(newValue)
                    loginError = nil
                } catch {
                    loginError = "Could not change login item. Put Desktop Toilet.app in /Applications and try again. (\(error.localizedDescription))"
                }
                refreshLogin()
            }
        )
    }

    private func refreshLogin() {
        launchAtLogin = LoginItem.isEnabled
    }
}

extension Notification.Name {
    static let resetToiletPosition = Notification.Name("DesktopToilet.resetPosition")
}
#endif
