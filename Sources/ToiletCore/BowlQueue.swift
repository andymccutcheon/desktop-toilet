import Foundation

public struct QueuedItem: Equatable, Hashable, Identifiable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public var id: String {
        PathNormalizer.canonicalPath(url)
    }

    public var displayName: String {
        let name = url.lastPathComponent
        return name.isEmpty ? url.path : name
    }
}

/// Insertion-ordered unique file queue ("what's in the bowl").
public struct BowlQueue: Equatable {
    public private(set) var items: [QueuedItem]

    public init(items: [QueuedItem] = []) {
        self.items = items
    }

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }
    public var urls: [URL] { items.map { $0.url } }

    /// Adds new unique URLs. Returns only the items that were actually inserted.
    @discardableResult
    public mutating func enqueue(_ urls: [URL]) -> [QueuedItem] {
        var seen = Set(items.map { $0.id })
        var added: [QueuedItem] = []
        for url in urls {
            let item = QueuedItem(url: url)
            if seen.contains(item.id) {
                continue
            }
            seen.insert(item.id)
            items.append(item)
            added.append(item)
        }
        return added
    }

    @discardableResult
    public mutating func remove(id: String) -> QueuedItem? {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return items.remove(at: index)
    }

    @discardableResult
    public mutating func remove(url: URL) -> QueuedItem? {
        remove(id: PathNormalizer.canonicalPath(url))
    }

    public mutating func remove(urls: [URL]) {
        let ids = Set(urls.map { PathNormalizer.canonicalPath($0) })
        items.removeAll { ids.contains($0.id) }
    }

    public mutating func clear() {
        items.removeAll()
    }

    public func contains(_ url: URL) -> Bool {
        let id = PathNormalizer.canonicalPath(url)
        return items.contains { $0.id == id }
    }
}
