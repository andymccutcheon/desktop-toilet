import XCTest
@testable import ToiletCore

final class PathNormalizerTests: XCTestCase {
    func testStripsTrailingSlash() {
        let url = URL(fileURLWithPath: "/Users/alex/Desktop/", isDirectory: true)
        XCTAssertEqual(PathNormalizer.standardizedPath(url), "/Users/alex/Desktop")
    }

    func testRootStaysRoot() {
        XCTAssertEqual(PathNormalizer.standardizedPath(URL(fileURLWithPath: "/")), "/")
    }

    func testStripDataVolumeMapsHome() {
        XCTAssertEqual(
            PathNormalizer.stripDataVolume("/System/Volumes/Data/Users/alex"),
            "/Users/alex"
        )
    }

    func testStripDataVolumeRootIsSlash() {
        XCTAssertEqual(PathNormalizer.stripDataVolume("/System/Volumes/Data"), "/")
    }

    func testStripDataVolumeLeavesSystemLibrary() {
        XCTAssertEqual(
            PathNormalizer.stripDataVolume("/System/Library/Kernels"),
            "/System/Library/Kernels"
        )
    }

    func testHasPrefixExactAndChild() {
        XCTAssertTrue(PathNormalizer.hasPrefix("/usr/bin", prefix: "/usr"))
        XCTAssertTrue(PathNormalizer.hasPrefix("/usr", prefix: "/usr"))
        XCTAssertFalse(PathNormalizer.hasPrefix("/usr-local", prefix: "/usr"))
        XCTAssertFalse(PathNormalizer.hasPrefix("/Applications", prefix: "/usr"))
    }
}
