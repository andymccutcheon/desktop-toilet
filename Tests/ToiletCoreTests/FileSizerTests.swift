import XCTest
@testable import ToiletCore

final class FileSizerTests: XCTestCase {
    func testSumsRegularFilesAndSkipsSymlinks() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("toilet-sizer-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let nested = root.appendingPathComponent("nested", isDirectory: true)
        try fm.createDirectory(at: nested, withIntermediateDirectories: true)

        let payloadA = Data(repeating: 7, count: 4096)
        let payloadB = Data(repeating: 3, count: 1024)
        try payloadA.write(to: root.appendingPathComponent("a.bin"))
        try payloadB.write(to: nested.appendingPathComponent("b.bin"))

        let outside = fm.temporaryDirectory.appendingPathComponent("toilet-outside-\(UUID().uuidString).bin")
        try Data(repeating: 9, count: 200_000).write(to: outside)
        defer { try? fm.removeItem(at: outside) }

        let link = root.appendingPathComponent("outside.link")
        try fm.createSymbolicLink(at: link, withDestinationURL: outside)

        let size = try FileManagerSizer().totalBytes(at: root)
        XCTAssertGreaterThanOrEqual(size, 5120)
        XCTAssertLessThan(size, 5120 + 64_000, "symlink target should not be followed")
    }

    func testRegularFileSize() throws {
        let fm = FileManager.default
        let file = fm.temporaryDirectory.appendingPathComponent("toilet-file-\(UUID().uuidString).bin")
        let data = Data(repeating: 1, count: 2048)
        try data.write(to: file)
        defer { try? fm.removeItem(at: file) }

        let size = try FileManagerSizer().totalBytes(at: file)
        XCTAssertEqual(size, 2048)
    }
}
