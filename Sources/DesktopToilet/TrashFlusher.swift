#if os(macOS)
import AppKit
import Foundation

enum TrashFlusher {
    static func recycle(
        _ urls: [URL],
        completion: @escaping (Result<[(original: URL, trash: URL)], Error>) -> Void
    ) {
        NSWorkspace.shared.recycle(urls) { mapping, error in
            DispatchQueue.main.async {
                if let error = error, mapping.isEmpty {
                    completion(.failure(error))
                    return
                }
                let pairs = urls.compactMap { original -> (original: URL, trash: URL)? in
                    if let trash = mapping[original] {
                        return (original, trash)
                    }
                    return nil
                }
                completion(.success(pairs))
            }
        }
    }

    static func permanentlyDelete(_ urls: [URL]) throws {
        for url in urls {
            try FileManager.default.removeItem(at: url)
        }
    }

    static func restore(_ pairs: [(original: URL, trash: URL)]) -> Int {
        var restored = 0
        for pair in pairs.reversed() {
            let destination = pair.original
            let parent = destination.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parent.path) {
                try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                continue
            }
            do {
                try FileManager.default.moveItem(at: pair.trash, to: destination)
                restored += 1
            } catch {
                continue
            }
        }
        return restored
    }
}
#endif
