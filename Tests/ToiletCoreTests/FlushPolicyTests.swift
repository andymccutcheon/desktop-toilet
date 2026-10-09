import XCTest
@testable import ToiletCore

final class FlushPolicyTests: XCTestCase {
    func testNoConfirmationUnderThresholds() {
        let policy = FlushPolicy.default
        XCTAssertNil(policy.confirmation(itemCount: 20, totalBytes: 1_000_000_000))
        XCTAssertNil(policy.confirmation(itemCount: 1, totalBytes: 4096))
    }

    func testConfirmsMoreThanTwentyItems() {
        let result = FlushPolicy.default.confirmation(itemCount: 21, totalBytes: 100)
        XCTAssertEqual(result?.reasons.count, 1)
        XCTAssertTrue(result?.reasons.first?.contains("21 items") == true)
    }

    func testConfirmsOverOneGigabyte() {
        let result = FlushPolicy.default.confirmation(itemCount: 1, totalBytes: 1_000_000_001)
        XCTAssertEqual(result?.reasons.count, 1)
        XCTAssertTrue(result?.reasons.first?.contains("over") == true)
    }

    func testBothReasonsCanFire() {
        let result = FlushPolicy.default.confirmation(itemCount: 50, totalBytes: 5_000_000_000)
        XCTAssertEqual(result?.reasons.count, 2)
    }

    func testCustomItemThreshold() {
        let policy = FlushPolicy(itemConfirmationThreshold: 3, byteConfirmationThreshold: 100)
        XCTAssertNil(policy.confirmation(itemCount: 3, totalBytes: 100))
        XCTAssertNotNil(policy.confirmation(itemCount: 4, totalBytes: 1))
        XCTAssertNotNil(policy.confirmation(itemCount: 1, totalBytes: 101))
    }

    func testByteFormat() {
        XCTAssertEqual(ByteFormat.string(12), "12 bytes")
        XCTAssertEqual(ByteFormat.string(1_000_000_000), "1.0 GB")
        XCTAssertEqual(ByteFormat.string(1_500_000_000), "1.5 GB")
    }
}
