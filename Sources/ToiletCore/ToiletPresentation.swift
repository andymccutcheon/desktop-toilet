import Foundation

/// Desktop window size for the 3D toilet. The scene itself is framed the same
/// way at every size; only the panel grows.
public enum ToiletDisplaySize: String, CaseIterable, Equatable, Sendable {
    case compact
    case regular
    case large

    public var width: Double {
        switch self {
        case .compact: return 240
        case .regular: return 280
        case .large: return 340
        }
    }

    public var height: Double {
        switch self {
        case .compact: return 330
        case .regular: return 380
        case .large: return 460
        }
    }
}

public enum ToiletHandleFinish: String, CaseIterable, Equatable, Sendable {
    case gold
    case chrome
}

/// Motion constants shared by the SceneKit controller. Kept here so timings
/// stay testable without AppKit.
public enum ToiletMotion {
    public static let lidOpenRadians: Float = 1.95
    public static let lidDuration: Double = 0.38
    public static let handlePressRadians: Float = 0.62
    public static let handlePressDuration: Double = 0.10
    public static let handleReleaseDuration: Double = 0.42
    public static let flushSwirlDuration: Double = 1.15
    public static let flushSwirlTurns: Float = 2
    public static let iconOrbitDuration: Double = 0.95
    public static let hoverLift: Float = 0.008
    public static let hoverYaw: Float = 0.04
    public static let hoverDuration: Double = 0.28
    public static let waterRestoreDuration: Double = 0.35
    public static let flushRenderBudget: Double = 1.35
}

public enum ToiletPart: String, Equatable, Sendable {
    case bowl
    case seat
    case lid
    case tank
    case handle
    case base
    case water
    case shadow
}

/// Classifies a named SceneKit hit. Unknown names are treated as the porcelain
/// body so a click still drags the window instead of falling through.
public enum ToiletHit: Equatable, Sendable {
    case handle
    case body
    case none

    public static func classify(nodeName: String?) -> ToiletHit {
        guard let raw = nodeName, !raw.isEmpty else { return .none }
        if raw == ToiletPart.handle.rawValue || raw.hasPrefix("handle") {
            return .handle
        }
        if raw == ToiletPart.shadow.rawValue {
            return .none
        }
        return .body
    }
}
