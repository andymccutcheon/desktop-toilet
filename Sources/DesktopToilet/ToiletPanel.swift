#if os(macOS)
import AppKit

// NSWindow does not expose NSDraggingDestination methods to Swift as overridable,
// so the panel declares the conformance itself (AppKit still routes drags here
// because the window registers for .fileURL).
final class ToiletPanel: NSPanel, NSDraggingDestination {
    var onDropURLs: (([URL]) -> Void)?
    var onDropTargeted: ((Bool) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        registerForDraggedTypes([.fileURL])
    }

    override func mouseDown(with event: NSEvent) {
        makeKey()
        super.mouseDown(with: event)
    }

    @objc func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(sender) else { return [] }
        onDropTargeted?(true)
        return .copy
    }

    @objc func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        hasFileURLs(sender) ? .copy : []
    }

    @objc func draggingExited(_ sender: NSDraggingInfo?) {
        onDropTargeted?(false)
    }

    @objc func draggingEnded(_ sender: NSDraggingInfo) {
        onDropTargeted?(false)
    }

    @objc func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hasFileURLs(sender)
    }

    @objc func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDropTargeted?(false)
        let urls = readFileURLs(from: sender)
        guard !urls.isEmpty else { return false }
        onDropURLs?(urls)
        return true
    }

    private func hasFileURLs(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }

    private func readFileURLs(from sender: NSDraggingInfo) -> [URL] {
        let objects = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
        guard let objects = objects else { return [] }
        return objects.compactMap { object -> URL? in
            if let url = object as? URL {
                return url
            }
            if let nsurl = object as? NSURL {
                return nsurl as URL
            }
            return nil
        }
    }
}
#endif
