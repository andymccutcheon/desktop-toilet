import XCTest
@testable import ToiletCore

final class BowlQueueTests: XCTestCase {
    func testEnqueuePreservesOrderAndUniqueness() {
        var queue = BowlQueue()
        let a = URL(fileURLWithPath: "/tmp/a.txt")
        let b = URL(fileURLWithPath: "/tmp/b.txt")
        let aAgain = URL(fileURLWithPath: "/tmp/a.txt")

        let first = queue.enqueue([a, b])
        XCTAssertEqual(first.map(\.displayName), ["a.txt", "b.txt"])
        XCTAssertEqual(queue.count, 2)

        let second = queue.enqueue([aAgain, URL(fileURLWithPath: "/tmp/c.txt")])
        XCTAssertEqual(second.map(\.displayName), ["c.txt"])
        XCTAssertEqual(queue.urls.map(\.lastPathComponent), ["a.txt", "b.txt", "c.txt"])
    }

    func testTrailingSlashDoesNotDuplicate() {
        var queue = BowlQueue()
        queue.enqueue([URL(fileURLWithPath: "/tmp/folder", isDirectory: true)])
        let added = queue.enqueue([URL(fileURLWithPath: "/tmp/folder/", isDirectory: true)])
        XCTAssertTrue(added.isEmpty)
        XCTAssertEqual(queue.count, 1)
    }

    func testRemoveAndClear() {
        var queue = BowlQueue()
        let a = URL(fileURLWithPath: "/tmp/a.txt")
        let b = URL(fileURLWithPath: "/tmp/b.txt")
        queue.enqueue([a, b])
        XCTAssertNotNil(queue.remove(url: a))
        XCTAssertEqual(queue.count, 1)
        XCTAssertTrue(queue.contains(b))
        queue.clear()
        XCTAssertTrue(queue.isEmpty)
    }
}
