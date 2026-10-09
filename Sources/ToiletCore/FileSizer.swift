import Foundation

public protocol FileSizing {
    func totalBytes(at url: URL) throws -> UInt64
}

/// Recursively sums regular-file sizes. Symbolic links are not followed.
public struct FileManagerSizer: FileSizing {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func totalBytes(at url: URL) throws -> UInt64 {
        let keys: Set<URLResourceKey> = [
            .isSymbolicLinkKey,
            .isDirectoryKey,
            .fileSizeKey,
            .isRegularFileKey,
        ]
        let values = try url.resourceValues(forKeys: keys)
        if values.isSymbolicLink == true {
            return UInt64(values.fileSize ?? 0)
        }
        if values.isDirectory != true {
            return UInt64(values.fileSize ?? 0)
        }

        var total: UInt64 = 0
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let rv = try? fileURL.resourceValues(forKeys: keys)
            if rv?.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if rv?.isDirectory == true {
                continue
            }
            if let size = rv?.fileSize {
                total += UInt64(size)
            }
        }
        return total
    }
}
