#if os(macOS)
import AppKit
import SwiftUI
import ToiletCore

struct ToiletView: View {
    @EnvironmentObject private var session: ToiletSession
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        ZStack {
            ToiletSceneView(session: session, handleFinish: settings.handleFinish)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { hovering in
                    session.isHovering = hovering
                }

            VStack(spacing: 0) {
                if let bubble = session.speechBubble {
                    SpeechBubble(text: bubble)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Color.clear.frame(height: 44)
                }
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            if !session.queue.isEmpty && !session.isFlushing {
                rescueChips
                    .padding(.bottom, 12)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !session.queue.isEmpty && !session.isFlushing {
                badge
                    .padding(.top, 52)
                    .padding(.trailing, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: session.speechBubble)
        .animation(.easeInOut(duration: 0.15), value: session.queue.count)
    }

    private var rescueChips: some View {
        VStack(spacing: 4) {
            ForEach(Array(session.queue.items.prefix(3))) { item in
                RescueChip(item: item, onRescue: { session.rescue(item) })
            }
            if session.queue.count > 3 {
                Text("+\(session.queue.count - 3) more")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(ToiletPalette.waterDeep)
            }
        }
    }

    private var badge: some View {
        Text("\(session.queue.count)")
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(minWidth: 22, minHeight: 22)
            .padding(.horizontal, session.queue.count > 9 ? 5 : 0)
            .background(Circle().fill(Color(red: 0.91, green: 0.28, blue: 0.32)))
            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
            .transition(.scale)
    }
}

private struct RescueChip: View {
    let item: QueuedItem
    let onRescue: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(item.displayName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .frame(maxWidth: 92, alignment: .leading)
            Button(action: onRescue) {
                Text("×")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ToiletPalette.outline)
            }
            .buttonStyle(.plain)
            .help("Rescue from the bowl")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Color.white.opacity(0.92))
        )
        .overlay(
            Capsule().stroke(ToiletPalette.outline.opacity(0.4), lineWidth: 1)
        )
        .onDrag {
            onRescue()
            return NSItemProvider(contentsOf: item.url) ?? NSItemProvider()
        }
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: 210)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.14), radius: 7, y: 2)
            )
    }
}

private enum ToiletPalette {
    static let outline = Color(red: 0.58, green: 0.66, blue: 0.72)
    static let waterDeep = Color(red: 0.16, green: 0.52, blue: 0.70)
}
#endif
