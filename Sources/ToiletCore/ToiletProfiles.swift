import Foundation

/// Original lathe profiles for the porcelain. Radii and heights are in scene
/// units (the assembled toilet is about 0.75 tall).
public enum ToiletProfiles {
    /// Inside-out bowl: drain → inner wall → rim → skirt → foot → trap.
    public static let bowl: [ProfilePoint] = [
        ProfilePoint(radius: 0.016, y: 0.108),
        ProfilePoint(radius: 0.036, y: 0.110),
        ProfilePoint(radius: 0.058, y: 0.122),
        ProfilePoint(radius: 0.086, y: 0.148),
        ProfilePoint(radius: 0.108, y: 0.188),
        ProfilePoint(radius: 0.124, y: 0.236),
        ProfilePoint(radius: 0.134, y: 0.286),
        ProfilePoint(radius: 0.140, y: 0.334),
        ProfilePoint(radius: 0.148, y: 0.368),
        ProfilePoint(radius: 0.164, y: 0.392),
        ProfilePoint(radius: 0.190, y: 0.404),
        ProfilePoint(radius: 0.216, y: 0.409),
        ProfilePoint(radius: 0.236, y: 0.402),
        ProfilePoint(radius: 0.238, y: 0.388),
        ProfilePoint(radius: 0.222, y: 0.372),
        ProfilePoint(radius: 0.200, y: 0.348),
        ProfilePoint(radius: 0.186, y: 0.308),
        ProfilePoint(radius: 0.178, y: 0.258),
        ProfilePoint(radius: 0.168, y: 0.202),
        ProfilePoint(radius: 0.148, y: 0.150),
        ProfilePoint(radius: 0.128, y: 0.102),
        ProfilePoint(radius: 0.130, y: 0.068),
        ProfilePoint(radius: 0.146, y: 0.040),
        ProfilePoint(radius: 0.156, y: 0.018),
        ProfilePoint(radius: 0.150, y: 0.006),
        ProfilePoint(radius: 0.112, y: 0.004),
        ProfilePoint(radius: 0.072, y: 0.012),
        ProfilePoint(radius: 0.044, y: 0.028),
        ProfilePoint(radius: 0.026, y: 0.050),
    ]

    /// Small torus-like disk used as a fallback ring (seat uses a primitive).
    public static let seatTube: [ProfilePoint] = {
        let ringRadius: Float = 0.168
        let pipeRadius: Float = 0.016
        let steps = 10
        return (0...steps).map { step in
            let angle = Float.pi * 2 * Float(step) / Float(steps)
            return ProfilePoint(
                radius: ringRadius + pipeRadius * cos(angle),
                y: 0.418 + pipeRadius * sin(angle) * 0.55
            )
        }
    }()

    public static let bowlSegments = 40
    public static let seatSegments = 28

    public static var rimHeight: Float {
        bowl.map(\.y).max() ?? 0.41
    }

    public static var rimRadius: Float {
        bowl.map(\.radius).max() ?? 0.24
    }

    public static var footRadius: Float {
        bowl.filter { $0.y < 0.03 }.map(\.radius).max() ?? 0.15
    }
}
