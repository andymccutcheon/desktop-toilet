#if os(macOS)
import AppKit
import Combine
import Foundation
import ToiletCore

struct LastFlush {
    var pairs: [(original: URL, trash: URL)]
    var permanent: Bool
}

final class ToiletSession: ObservableObject {
    static let shared = ToiletSession()

    @Published var queue = BowlQueue()
    @Published var isHovering = false
    @Published var isDropTargeted = false
    @Published var isFlushing = false
    @Published var speechBubble: String?
    @Published var lastFlush: LastFlush?

    var askConfirmation: ((String, Bool, @escaping (Bool) -> Void) -> Void)?
    var playPlop: (() -> Void)?
    var playFlush: (() -> Void)?

    private var speechGeneration = 0
    private let settings = SettingsStore.shared

    var canUndo: Bool {
        guard let lastFlush, !lastFlush.permanent, !lastFlush.pairs.isEmpty else {
            return false
        }
        return true
    }

    var lidOpen: Bool {
        isHovering || isDropTargeted || !queue.isEmpty || isFlushing
    }

    func drop(urls: [URL]) {
        guard !isFlushing else { return }
        var allowed: [URL] = []
        var sawRefusal = false
        let planner = makePlanner()
        for url in urls {
            switch planner.guardrails.verdict(for: url) {
            case .allowed:
                allowed.append(url)
            case .refused:
                sawRefusal = true
            }
        }
        if sawRefusal {
            speak(FlushGuardrails.tooBigMessage)
        }
        var next = queue
        let added = next.enqueue(allowed)
        queue = next
        if !added.isEmpty {
            playPlop?()
        }
    }

    func rescue(_ item: QueuedItem) {
        var next = queue
        _ = next.remove(id: item.id)
        queue = next
    }

    func emptyBowl() {
        guard !isFlushing else { return }
        queue.clear()
        speak("Bowl emptied. Files stay where they were.")
    }

    func requestFlush() {
        guard !isFlushing else { return }
        if queue.isEmpty {
            speak("Nothing in the bowl.")
            return
        }

        let planner = makePlanner()
        let plan = planner.plan(urls: queue.urls)

        if !plan.refused.isEmpty {
            var next = queue
            next.remove(urls: plan.refused.map(\.url))
            queue = next
            speak(FlushGuardrails.tooBigMessage)
            if plan.allowed.isEmpty {
                return
            }
        }

        let permanent = settings.permanentDelete
        if let confirmation = plan.confirmation {
            var message = confirmation.message
            if permanent {
                message += "\n\nPermanent delete is on. This cannot be undone."
            } else {
                message += "\n\nThey'll go to Trash, so you can still fish them out."
            }
            askConfirmation?(message, permanent) { [weak self] ok in
                if ok {
                    self?.commitFlush(urls: plan.allowed)
                }
            }
            return
        }

        if permanent {
            askConfirmation?(
                "Permanent delete is on. These items will be erased immediately — not sent to Trash.",
                true
            ) { [weak self] ok in
                if ok {
                    self?.commitFlush(urls: plan.allowed)
                }
            }
            return
        }

        commitFlush(urls: plan.allowed)
    }

    func undoLastFlush() {
        guard let last = lastFlush else {
            speak("Nothing to unsink.")
            return
        }
        if last.permanent {
            speak("That flush was permanent. I can't unsink it.")
            return
        }
        let restored = TrashFlusher.restore(last.pairs)
        if restored == 0 {
            speak("Couldn't find them. Maybe Trash was emptied?")
        } else if restored < last.pairs.count {
            speak("Fished out \(restored). A few had already drifted away.")
        } else {
            speak("Fished everything back out.")
        }
        lastFlush = nil
    }

    private func commitFlush(urls: [URL]) {
        isFlushing = true
        playFlush?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.performDeletion(urls: urls)
        }
    }

    private func performDeletion(urls: [URL]) {
        if settings.permanentDelete {
            do {
                try TrashFlusher.permanentlyDelete(urls)
                lastFlush = LastFlush(pairs: [], permanent: true)
                var next = queue
                next.remove(urls: urls)
                queue = next
                speak("Gone. No take-backs.")
            } catch {
                speak("The pipes clogged: \(error.localizedDescription)")
            }
            isFlushing = false
            return
        }

        TrashFlusher.recycle(urls) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let pairs):
                self.lastFlush = LastFlush(pairs: pairs, permanent: false)
                var next = self.queue
                next.remove(urls: pairs.map { $0.original })
                self.queue = next
                if pairs.isEmpty {
                    self.speak("Nothing moved. Check permissions?")
                }
            case .failure(let error):
                self.speak("Clog: \(error.localizedDescription)")
            }
            self.isFlushing = false
        }
    }

    private func makePlanner() -> FlushPlanner {
        var context = FlushContext.default()
        context.extraExactPaths.append(PathNormalizer.canonicalPath(Bundle.main.bundleURL))
        return FlushPlanner(
            guardrails: FlushGuardrails(context: context),
            policy: FlushPolicy(
                itemConfirmationThreshold: settings.confirmAfterItems,
                byteConfirmationThreshold: settings.byteConfirmationThreshold
            ),
            sizer: FileManagerSizer()
        )
    }

    private func speak(_ text: String) {
        speechGeneration += 1
        let token = speechGeneration
        speechBubble = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.speechGeneration == token else { return }
            self.speechBubble = nil
        }
    }
}
#endif
