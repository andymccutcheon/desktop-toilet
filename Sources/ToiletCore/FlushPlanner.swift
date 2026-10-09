import Foundation

public struct RefusedItem: Equatable {
    public var url: URL
    public var message: String
    public var detail: String

    public init(url: URL, message: String, detail: String) {
        self.url = url
        self.message = message
        self.detail = detail
    }
}

public struct FlushPlan: Equatable {
    public var allowed: [URL]
    public var refused: [RefusedItem]
    public var totalBytes: UInt64
    public var confirmation: ConfirmationRequest?

    public init(
        allowed: [URL],
        refused: [RefusedItem],
        totalBytes: UInt64,
        confirmation: ConfirmationRequest?
    ) {
        self.allowed = allowed
        self.refused = refused
        self.totalBytes = totalBytes
        self.confirmation = confirmation
    }

    public var canFlush: Bool { !allowed.isEmpty }
}

public struct FlushPlanner {
    public var guardrails: FlushGuardrails
    public var policy: FlushPolicy
    public var sizer: FileSizing

    public init(
        guardrails: FlushGuardrails = FlushGuardrails(),
        policy: FlushPolicy = .default,
        sizer: FileSizing = FileManagerSizer()
    ) {
        self.guardrails = guardrails
        self.policy = policy
        self.sizer = sizer
    }

    public func plan(urls: [URL]) -> FlushPlan {
        var allowed: [URL] = []
        var refused: [RefusedItem] = []
        var totalBytes: UInt64 = 0
        var seen = Set<String>()

        for url in urls {
            let id = PathNormalizer.canonicalPath(url)
            if seen.contains(id) {
                continue
            }
            seen.insert(id)

            switch guardrails.verdict(for: url) {
            case .allowed:
                allowed.append(url)
                totalBytes += (try? sizer.totalBytes(at: url)) ?? 0
            case .refused(let message, let detail):
                refused.append(RefusedItem(url: url, message: message, detail: detail))
            }
        }

        let confirmation = policy.confirmation(itemCount: allowed.count, totalBytes: totalBytes)
        return FlushPlan(
            allowed: allowed,
            refused: refused,
            totalBytes: totalBytes,
            confirmation: confirmation
        )
    }
}
