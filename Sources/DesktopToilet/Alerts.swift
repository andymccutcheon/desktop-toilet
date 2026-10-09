#if os(macOS)
import AppKit

enum Alerts {
    @discardableResult
    static func confirm(
        title: String,
        message: String,
        confirmTitle: String,
        style: NSAlert.Style = .warning
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
#endif
