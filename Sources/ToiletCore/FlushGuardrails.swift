import Foundation

public struct FlushContext: Equatable {
    public var homePath: String
    public var desktopPath: String
    public var extraExactPaths: [String]

    public init(homePath: String, desktopPath: String, extraExactPaths: [String] = []) {
        self.homePath = PathNormalizer.stripDataVolume(homePath)
        self.desktopPath = PathNormalizer.stripDataVolume(desktopPath)
        self.extraExactPaths = extraExactPaths.map(PathNormalizer.stripDataVolume)
    }

    public static func `default`(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        desktop: URL? = nil
    ) -> FlushContext {
        let homePath = PathNormalizer.canonicalPath(home)
        let desktopURL = desktop ?? home.appendingPathComponent("Desktop", isDirectory: true)
        return FlushContext(
            homePath: homePath,
            desktopPath: PathNormalizer.canonicalPath(desktopURL),
            extraExactPaths: []
        )
    }

    /// Folders that are too important or too large as a single drop.
    public var exactProtected: [String] {
        [
            "/",
            "/Applications",
            "/Library",
            "/Users",
            "/Volumes",
            "/opt",
            "/private",
            "/System",
            "/System/Volumes",
            homePath,
            desktopPath,
        ] + extraExactPaths
    }

    /// Prefix-protected locations. `/System` is handled separately so the
    /// `/System/Volumes/Data` firmlink is not treated as the OS itself.
    public var prefixProtected: [String] {
        ["/usr", "/bin", "/sbin", "/System/Library"]
    }
}

public enum ItemVerdict: Equatable {
    case allowed
    case refused(message: String, detail: String)
}

public struct FlushGuardrails {
    public static let tooBigMessage = "that's too big to flush"

    public var context: FlushContext

    public init(context: FlushContext = .default()) {
        self.context = context
    }

    public func verdict(for url: URL) -> ItemVerdict {
        let candidates = candidatePaths(for: url)
        for path in candidates {
            if let detail = refusalDetail(forPath: path) {
                return .refused(message: Self.tooBigMessage, detail: detail)
            }
        }
        return .allowed
    }

    public func candidatePaths(for url: URL) -> [String] {
        let raw = PathNormalizer.canonicalPath(url)
        let resolved = PathNormalizer.canonicalPath(url.resolvingSymlinksInPath())
        if raw == resolved { return [raw] }
        return [raw, resolved]
    }

    public func refusalDetail(forPath path: String) -> String? {
        if context.extraExactPaths.contains(path) {
            return "I don't flush myself. That's how you get plumbing jokes."
        }
        if path == "/" {
            return "The whole disk? I have an appetite, not a death wish."
        }
        if path == context.homePath {
            return "I don't swallow entire homes."
        }
        if path == context.desktopPath {
            return "The Desktop itself stays put. Drop files onto me, not the whole stage."
        }
        if path == "/Applications" {
            return "The whole Applications folder? That's a banquet."
        }
        if path == "/Library" {
            return "System Library is a locked stall."
        }
        if path == "/Users" {
            return "Every home at once? Absolutely not."
        }
        if path == "/Volumes" || path == "/opt" || path == "/private" {
            return "That's infrastructure, not a snack."
        }
        if path == "/System" || path == "/System/Volumes" {
            return "macOS would never forgive me."
        }
        if isSystemPath(path) {
            return "macOS would never forgive me."
        }
        for prefix in context.prefixProtected {
            if PathNormalizer.hasPrefix(path, prefix: prefix) {
                return "That pipe leads to the operating system."
            }
        }
        if context.exactProtected.contains(path) {
            return "That's too important to swirl away."
        }
        return nil
    }

    /// `/System/...` except the data-volume firmlink, which `stripDataVolume` already removed.
    /// After canonicalization, leftover `/System` paths are the sealed system volume.
    private func isSystemPath(_ path: String) -> Bool {
        if path == "/System" { return true }
        if PathNormalizer.hasPrefix(path, prefix: "/System") {
            return !PathNormalizer.hasPrefix(path, prefix: "/System/Volumes")
        }
        return false
    }
}
