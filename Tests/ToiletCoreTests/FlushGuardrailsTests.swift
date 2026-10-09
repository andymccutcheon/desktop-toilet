import XCTest
@testable import ToiletCore

final class FlushGuardrailsTests: XCTestCase {
    private var guardrails: FlushGuardrails!

    override func setUp() {
        super.setUp()
        guardrails = FlushGuardrails(
            context: FlushContext(
                homePath: "/Users/alex",
                desktopPath: "/Users/alex/Desktop",
                extraExactPaths: ["/Applications/Desktop Toilet.app"]
            )
        )
    }

    func testRootIsRefused() {
        assertRefused("/")
    }

    func testSystemIsRefused() {
        assertRefused("/System")
        assertRefused("/System/Library")
        assertRefused("/System/Applications")
    }

    func testApplicationsFolderIsRefusedButIndividualAppIsNot() {
        assertRefused("/Applications")
        XCTAssertEqual(
            guardrails.verdict(for: URL(fileURLWithPath: "/Applications/Slack.app")),
            .allowed
        )
    }

    func testHomeFolderIsRefusedButContentsAreNot() {
        assertRefused("/Users/alex")
        XCTAssertEqual(
            guardrails.verdict(for: URL(fileURLWithPath: "/Users/alex/Documents/notes.txt")),
            .allowed
        )
    }

    func testDesktopFolderIsRefusedButFilesOnDesktopAreNot() {
        assertRefused("/Users/alex/Desktop")
        XCTAssertEqual(
            guardrails.verdict(for: URL(fileURLWithPath: "/Users/alex/Desktop/invoice.pdf")),
            .allowed
        )
    }

    func testUsersAndVolumesAreRefused() {
        assertRefused("/Users")
        assertRefused("/Volumes")
    }

    func testUnixBinsAreRefused() {
        assertRefused("/usr")
        assertRefused("/usr/bin/swift")
        assertRefused("/bin")
        assertRefused("/sbin")
    }

    func testFirmlinkedDesktopFileIsAllowed() {
        let url = URL(fileURLWithPath: "/System/Volumes/Data/Users/alex/Desktop/photo.png")
        XCTAssertEqual(guardrails.verdict(for: url), .allowed)
    }

    func testFirmlinkedHomeFolderIsRefused() {
        assertRefused("/System/Volumes/Data/Users/alex")
    }

    func testDataVolumeRootIsRefused() {
        assertRefused("/System/Volumes/Data")
    }

    func testAppBundleCanBeProtected() {
        assertRefused("/Applications/Desktop Toilet.app")
    }

    func testFunnyMessageIsStable() {
        let verdict = guardrails.verdict(for: URL(fileURLWithPath: "/"))
        guard case .refused(let message, let detail) = verdict else {
            return XCTFail("expected refusal")
        }
        XCTAssertEqual(message, FlushGuardrails.tooBigMessage)
        XCTAssertTrue(detail.lowercased().contains("disk"))
    }

    private func assertRefused(_ path: String, file: StaticString = #filePath, line: UInt = #line) {
        let verdict = guardrails.verdict(for: URL(fileURLWithPath: path))
        guard case .refused(let message, _) = verdict else {
            XCTFail("expected \(path) to be refused, got \(verdict)", file: file, line: line)
            return
        }
        XCTAssertEqual(message, FlushGuardrails.tooBigMessage, file: file, line: line)
    }
}
