import XCTest
@testable import ToiletCore

final class LatheMeshTests: XCTestCase {
    func testVertexAndIndexCounts() {
        let profile = [
            ProfilePoint(radius: 1, y: 0),
            ProfilePoint(radius: 1, y: 1),
            ProfilePoint(radius: 0.5, y: 2),
        ]
        let segments = 8
        let mesh = LatheMesh.generate(profile: profile, segments: segments)

        XCTAssertEqual(mesh.vertices.count, profile.count * segments)
        XCTAssertEqual(mesh.indices.count, (profile.count - 1) * segments * 6)
        XCTAssertEqual(mesh.triangleCount, (profile.count - 1) * segments * 2)
    }

    func testNormalsAreUnitLength() {
        let mesh = LatheMesh.generate(profile: ToiletProfiles.bowl, segments: 12)
        for vertex in mesh.vertices {
            let length = (vertex.nx * vertex.nx + vertex.ny * vertex.ny + vertex.nz * vertex.nz).squareRoot()
            XCTAssertEqual(length, 1, accuracy: 0.02)
            XCTAssertTrue(vertex.px.isFinite && vertex.py.isFinite && vertex.pz.isFinite)
        }
        XCTAssertFalse(mesh.indices.contains { $0 >= UInt32(mesh.vertices.count) })
    }

    func testBowlExtentsMatchProfile() {
        let mesh = LatheMesh.generate(
            profile: ToiletProfiles.bowl,
            segments: ToiletProfiles.bowlSegments
        )
        let maxRadius = mesh.vertices.map { ($0.px * $0.px + $0.pz * $0.pz).squareRoot() }.max() ?? 0
        let minY = mesh.vertices.map(\.py).min() ?? 0
        let maxY = mesh.vertices.map(\.py).max() ?? 0

        XCTAssertEqual(maxRadius, ToiletProfiles.rimRadius, accuracy: 0.002)
        XCTAssertEqual(maxY, ToiletProfiles.rimHeight, accuracy: 0.002)
        XCTAssertEqual(minY, ToiletProfiles.bowl.map(\.y).min() ?? 0, accuracy: 0.002)
        XCTAssertGreaterThan(ToiletProfiles.footRadius, 0.1)
        XCTAssertGreaterThan(ToiletProfiles.rimRadius, ToiletProfiles.footRadius)
    }

    func testBowlStartsAtTheDrain() {
        let first = ToiletProfiles.bowl[0]
        XCTAssertLessThan(first.radius, 0.03)
        XCTAssertGreaterThan(first.y, 0.08)
        XCTAssertGreaterThan(ToiletProfiles.bowl.count, 10)
    }

    func testProfileNormalsPointLeftOfTravel() {
        let profile = [
            ProfilePoint(radius: 1, y: 0),
            ProfilePoint(radius: 1, y: 1),
        ]
        let normals = LatheMesh.profileNormals(profile)
        XCTAssertEqual(normals.count, 2)
        XCTAssertEqual(normals[0].0, -1, accuracy: 0.001)
        XCTAssertEqual(normals[0].1, 0, accuracy: 0.001)
    }
}

final class ToiletPresentationTests: XCTestCase {
    func testDisplaySizesArePositiveAndOrdered() {
        XCTAssertLessThan(ToiletDisplaySize.compact.width, ToiletDisplaySize.regular.width)
        XCTAssertLessThan(ToiletDisplaySize.regular.width, ToiletDisplaySize.large.width)
        XCTAssertLessThan(ToiletDisplaySize.compact.height, ToiletDisplaySize.regular.height)
        for size in ToiletDisplaySize.allCases {
            XCTAssertGreaterThan(size.width, 100)
            XCTAssertGreaterThan(size.height, 100)
        }
    }

    func testMotionConstantsAreSane() {
        XCTAssertGreaterThan(ToiletMotion.lidOpenRadians, 1)
        XCTAssertLessThan(ToiletMotion.lidOpenRadians, 3)
        XCTAssertGreaterThan(ToiletMotion.flushSwirlDuration, 0.5)
        XCTAssertGreaterThan(ToiletMotion.handlePressDuration, 0)
        XCTAssertGreaterThan(ToiletMotion.hoverDuration, 0)
    }

    func testHitClassification() {
        XCTAssertEqual(ToiletHit.classify(nodeName: "handle"), .handle)
        XCTAssertEqual(ToiletHit.classify(nodeName: "handleStem"), .handle)
        XCTAssertEqual(ToiletHit.classify(nodeName: "bowl"), .body)
        XCTAssertEqual(ToiletHit.classify(nodeName: "lid"), .body)
        XCTAssertEqual(ToiletHit.classify(nodeName: "shadow"), .none)
        XCTAssertEqual(ToiletHit.classify(nodeName: nil), .none)
        XCTAssertEqual(ToiletHit.classify(nodeName: ""), .none)
    }

    func testHandleFinishCases() {
        XCTAssertEqual(ToiletHandleFinish.allCases.count, 2)
        XCTAssertEqual(ToiletHandleFinish.gold.rawValue, "gold")
    }
}
