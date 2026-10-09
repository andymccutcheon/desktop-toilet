import Foundation

/// A point in the (radius, height) plane used to spin a surface around Y.
public struct ProfilePoint: Equatable, Sendable {
    public var radius: Float
    public var y: Float

    public init(radius: Float, y: Float) {
        self.radius = radius
        self.y = y
    }
}

public struct MeshVertex: Equatable, Sendable {
    public var px: Float
    public var py: Float
    public var pz: Float
    public var nx: Float
    public var ny: Float
    public var nz: Float
    public var u: Float
    public var v: Float

    public init(
        px: Float,
        py: Float,
        pz: Float,
        nx: Float,
        ny: Float,
        nz: Float,
        u: Float,
        v: Float
    ) {
        self.px = px
        self.py = py
        self.pz = pz
        self.nx = nx
        self.ny = ny
        self.nz = nz
        self.u = u
        self.v = v
    }
}

public struct MeshData: Equatable, Sendable {
    public var vertices: [MeshVertex]
    public var indices: [UInt32]

    public init(vertices: [MeshVertex], indices: [UInt32]) {
        self.vertices = vertices
        self.indices = indices
    }

    public var triangleCount: Int { indices.count / 3 }
}

/// Builds a surface of revolution from a 2D profile.
///
/// The profile is treated as a polyline in the (radius, y) plane and spun
/// around the Y axis. Surface normals follow the profile's left-hand side
/// (radius decreasing when traveling +Y), which is what a bowl wants: start
/// at the drain, climb the inner wall, roll over the rim, and come down the
/// outside.
public enum LatheMesh {
    public static func generate(profile: [ProfilePoint], segments: Int) -> MeshData {
        let rings = profile.count
        let slices = max(3, segments)
        precondition(rings >= 2, "A lathe profile needs at least two points")

        let normals2D = profileNormals(profile)
        var vertices: [MeshVertex] = []
        vertices.reserveCapacity(rings * slices)

        for (i, point) in profile.enumerated() {
            let radius = max(0, point.radius)
            let v = rings == 1 ? 0 : Float(i) / Float(rings - 1)
            let nR = normals2D[i].0
            let nY = normals2D[i].1
            for j in 0..<slices {
                let u = Float(j) / Float(slices)
                let theta = u * (2 * Float.pi)
                let c = cos(theta)
                let s = sin(theta)
                let n = normalize(nR * c, nY, nR * s)
                vertices.append(
                    MeshVertex(
                        px: radius * c,
                        py: point.y,
                        pz: radius * s,
                        nx: n.0,
                        ny: n.1,
                        nz: n.2,
                        u: u,
                        v: v
                    )
                )
            }
        }

        var indices: [UInt32] = []
        indices.reserveCapacity((rings - 1) * slices * 6)
        for i in 0..<(rings - 1) {
            for j in 0..<slices {
                let jNext = (j + 1) % slices
                let v00 = UInt32(i * slices + j)
                let v01 = UInt32(i * slices + jNext)
                let v10 = UInt32((i + 1) * slices + j)
                let v11 = UInt32((i + 1) * slices + jNext)
                indices.append(contentsOf: [v00, v10, v01, v01, v10, v11])
            }
        }

        return MeshData(vertices: vertices, indices: indices)
    }

    /// Per-vertex 2D normals in (radius, y), using the left normal of each segment.
    public static func profileNormals(_ profile: [ProfilePoint]) -> [(Float, Float)] {
        guard !profile.isEmpty else { return [] }
        return profile.indices.map { index in
            let previous = profile[max(0, index - 1)]
            let next = profile[min(profile.count - 1, index + 1)]
            let dR = next.radius - previous.radius
            let dY = next.y - previous.y
            return normalize(-dY, dR)
        }
    }

    public static func normalize(_ x: Float, _ y: Float) -> (Float, Float) {
        let length = (x * x + y * y).squareRoot()
        guard length > 1e-8 else { return (1, 0) }
        return (x / length, y / length)
    }

    public static func normalize(_ x: Float, _ y: Float, _ z: Float) -> (Float, Float, Float) {
        let length = (x * x + y * y + z * z).squareRoot()
        guard length > 1e-8 else { return (0, 1, 0) }
        return (x / length, y / length, z / length)
    }
}
