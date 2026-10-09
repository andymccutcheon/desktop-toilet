import Foundation

/// Path helpers that behave the same on Linux tests and macOS.
public enum PathNormalizer {
    /// Standardized absolute path without a trailing slash (except `/`).
    public static func standardizedPath(_ url: URL) -> String {
        var path = url.standardizedFileURL.path
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    /// macOS firmlinks user data under `/System/Volumes/Data`. Strip that prefix
    /// so `/System/Volumes/Data/Users/x` compares equal to `/Users/x`, and so we
    /// do not treat ordinary Desktop files as `/System` paths.
    public static func stripDataVolume(_ path: String) -> String {
        let prefix = "/System/Volumes/Data"
        if path == prefix {
            return "/"
        }
        if path.hasPrefix(prefix + "/") {
            let rest = String(path.dropFirst(prefix.count))
            return rest.isEmpty ? "/" : rest
        }
        return path
    }

    public static func canonicalPath(_ url: URL) -> String {
        stripDataVolume(standardizedPath(url))
    }

    public static func hasPrefix(_ path: String, prefix: String) -> Bool {
        if path == prefix { return true }
        if prefix == "/" { return path.hasPrefix("/") }
        return path.hasPrefix(prefix + "/")
    }
}
