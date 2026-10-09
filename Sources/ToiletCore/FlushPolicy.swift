import Foundation

public struct ConfirmationRequest: Equatable {
    public var reasons: [String]

    public init(reasons: [String]) {
        self.reasons = reasons
    }

    public var message: String {
        reasons.joined(separator: "\n")
    }
}

public struct FlushPolicy: Equatable {
    public var itemConfirmationThreshold: Int
    public var byteConfirmationThreshold: UInt64

    public static let `default` = FlushPolicy(
        itemConfirmationThreshold: 20,
        byteConfirmationThreshold: 1_000_000_000
    )

    public init(
        itemConfirmationThreshold: Int = 20,
        byteConfirmationThreshold: UInt64 = 1_000_000_000
    ) {
        self.itemConfirmationThreshold = itemConfirmationThreshold
        self.byteConfirmationThreshold = byteConfirmationThreshold
    }

    public func confirmation(itemCount: Int, totalBytes: UInt64) -> ConfirmationRequest? {
        var reasons: [String] = []
        if itemCount > itemConfirmationThreshold {
            reasons.append(
                "That's \(itemCount) items — more than \(itemConfirmationThreshold)."
            )
        }
        if totalBytes > byteConfirmationThreshold {
            reasons.append(
                "That's \(ByteFormat.string(totalBytes)) — over \(ByteFormat.string(byteConfirmationThreshold))."
            )
        }
        if reasons.isEmpty {
            return nil
        }
        return ConfirmationRequest(reasons: reasons)
    }
}
