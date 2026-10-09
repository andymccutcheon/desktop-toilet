import XCTest
@testable import ToiletCore

private struct StubSizer: FileSizing {
    var sizes: [String: UInt64]

    func totalBytes(at url: URL) throws -> UInt64 {
        sizes[PathNormalizer.canonicalPath(url)] ?? 0
    }
}

final class FlushPlannerTests: XCTestCase {
    func testSplitsAllowedAndRefusedAndAsksToConfirm() {
        let context = FlushContext(homePath: "/Users/alex", desktopPath: "/Users/alex/Desktop")
        let planner = FlushPlanner(
            guardrails: FlushGuardrails(context: context),
            policy: .default,
            sizer: StubSizer(sizes: [
                "/Users/alex/Desktop/big.mov": 2_000_000_000,
                "/Users/alex/Desktop/notes.txt": 120,
            ])
        )

        let plan = planner.plan(urls: [
            URL(fileURLWithPath: "/Users/alex/Desktop"),
            URL(fileURLWithPath: "/Users/alex/Desktop/big.mov"),
            URL(fileURLWithPath: "/Users/alex/Desktop/notes.txt"),
            URL(fileURLWithPath: "/Users/alex"),
        ])

        XCTAssertEqual(plan.allowed.map(\.lastPathComponent), ["big.mov", "notes.txt"])
        XCTAssertEqual(plan.refused.count, 2)
        XCTAssertEqual(plan.refused.map(\.message), [
            FlushGuardrails.tooBigMessage,
            FlushGuardrails.tooBigMessage,
        ])
        XCTAssertEqual(plan.totalBytes, 2_000_000_120)
        XCTAssertNotNil(plan.confirmation)
        XCTAssertTrue(plan.canFlush)
    }

    func testEmptyPlanCannotFlush() {
        let planner = FlushPlanner(
            guardrails: FlushGuardrails(
                context: FlushContext(homePath: "/Users/alex", desktopPath: "/Users/alex/Desktop")
            ),
            sizer: StubSizer(sizes: [:])
        )
        let plan = planner.plan(urls: [URL(fileURLWithPath: "/")])
        XCTAssertFalse(plan.canFlush)
        XCTAssertNil(plan.confirmation)
    }
}
