#if os(macOS)
import AppKit
import SwiftUI
import ToiletCore

struct ToiletView: View {
    @EnvironmentObject private var session: ToiletSession
    @State private var handlePulled = false
    @State private var swirl = 0.0
    @State private var splash: CGFloat = 0
    @State private var windowDragOrigin: NSPoint?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if let bubble = session.speechBubble {
                    SpeechBubble(text: bubble)
                        .padding(.bottom, 6)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Color.clear.frame(height: 44)
                }

                ZStack(alignment: .top) {
                    porcelain
                        .gesture(moveWindowGesture)
                    handle
                    if !session.queue.isEmpty && !session.isFlushing {
                        badge
                    }
                }
                .onHover { hovering in
                    session.isHovering = hovering
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onChange(of: session.isFlushing) { flushing in
            if flushing {
                withAnimation(.linear(duration: 1.15)) {
                    swirl += 720
                }
            }
        }
        .onChange(of: session.queue.count) { _ in
            splash = 1
            withAnimation(.easeOut(duration: 0.45)) {
                splash = 0
            }
        }
    }

    private var porcelain: some View {
        VStack(spacing: 0) {
            tank
            bowlStack
            base
        }
    }

    private var tank: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ToiletPalette.shadow)
                .offset(y: 4)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ToiletPalette.porcelain, ToiletPalette.shadow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ToiletPalette.outline, lineWidth: 1.5)

            VStack(spacing: 6) {
                face
                Text("DT")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(ToiletPalette.outline.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().stroke(ToiletPalette.outline.opacity(0.45), lineWidth: 1)
                    )
            }
        }
        .frame(width: 132, height: 78)
        .zIndex(2)
    }

    private var face: some View {
        HStack(spacing: 16) {
            Eye(flushing: session.isFlushing, lookingUp: session.lidOpen)
            Eye(flushing: session.isFlushing, lookingUp: session.lidOpen)
        }
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(session.isFlushing ? ToiletPalette.outline : ToiletPalette.blush)
                .frame(width: session.isFlushing ? 16 : 12, height: 3)
                .offset(y: 12)
        }
    }

    private var handle: some View {
        Button(action: pullHandle) {
            ZStack {
                Capsule()
                    .fill(ToiletPalette.goldShadow)
                    .offset(y: 2)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [ToiletPalette.goldHighlight, ToiletPalette.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule()
                    .stroke(ToiletPalette.goldEdge, lineWidth: 1)
            }
            .frame(width: 16, height: 42)
            .offset(y: handlePulled ? 10 : 0)
        }
        .buttonStyle(.plain)
        .help("Flush")
        .offset(x: -78, y: 8)
        .zIndex(3)
    }

    private var bowlStack: some View {
        ZStack {
            lid
                .offset(y: -18)
                .zIndex(3)

            BowlShape()
                .fill(ToiletPalette.shadow)
                .offset(y: 5)
                .frame(width: 168, height: 150)

            BowlShape()
                .fill(
                    LinearGradient(
                        colors: [ToiletPalette.porcelain, Color.white, ToiletPalette.shadow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 168, height: 150)

            BowlShape()
                .stroke(ToiletPalette.outline, lineWidth: 1.6)
                .frame(width: 168, height: 150)

            water
                .frame(width: 118, height: 72)
                .offset(y: 18)
                .clipShape(Ellipse())

            if splash > 0.05 {
                splashRings
                    .offset(y: 10)
            }

            if !session.queue.isEmpty && !session.isFlushing {
                rescueChips
                    .offset(y: 22)
            }
        }
        .frame(width: 180, height: 160)
        .offset(y: -8)
    }

    private var lid: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white, ToiletPalette.porcelain],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ToiletPalette.outline, lineWidth: 1.4)
            )
            .frame(width: 148, height: 22)
            .rotationEffect(.degrees(session.lidOpen ? -58 : 0), anchor: UnitPoint(x: 0.5, y: 1))
            .shadow(color: .black.opacity(session.lidOpen ? 0.12 : 0), radius: 6, y: 4)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: session.lidOpen)
    }

    private var water: some View {
        ZStack {
            Ellipse()
                .fill(
                    AngularGradient(
                        colors: [
                            ToiletPalette.water,
                            ToiletPalette.waterDeep,
                            Color.white.opacity(0.7),
                            ToiletPalette.water,
                            ToiletPalette.waterDeep,
                            ToiletPalette.water,
                        ],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(swirl + (session.isDropTargeted ? 18 : 0)))
                .scaleEffect(session.isFlushing ? 0.15 : 1)
                .opacity(session.isFlushing ? 0.2 : 1)
                .animation(.easeIn(duration: 1.05), value: session.isFlushing)

            Ellipse()
                .stroke(Color.white.opacity(0.45), lineWidth: 2)
                .scaleEffect(x: 0.72, y: 0.35)
                .offset(y: -8)
                .opacity(session.isFlushing ? 0 : 0.8)
        }
    }

    private var splashRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(ToiletPalette.waterDeep.opacity(0.35 * splash), lineWidth: 2)
                    .frame(width: 28 + CGFloat(index) * 18, height: 16 + CGFloat(index) * 8)
            }
        }
        .scaleEffect(1.1 - splash * 0.3)
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
            .offset(x: 74, y: 96)
            .transition(.scale)
    }

    private var base: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 6)
                .fill(ToiletPalette.shadow)
                .frame(width: 36, height: 16)
            Trapezoid()
                .fill(ToiletPalette.porcelain)
                .overlay(Trapezoid().stroke(ToiletPalette.outline, lineWidth: 1))
                .frame(width: 92, height: 18)
        }
        .offset(y: -14)
    }

    private var moveWindowGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                guard let window = NSApp.windows.first(where: { $0 is ToiletPanel }) else {
                    return
                }
                if windowDragOrigin == nil {
                    windowDragOrigin = window.frame.origin
                }
                guard let start = windowDragOrigin else { return }
                window.setFrameOrigin(
                    NSPoint(
                        x: start.x + value.translation.width,
                        y: start.y - value.translation.height
                    )
                )
            }
            .onEnded { _ in
                if let window = NSApp.windows.first(where: { $0 is ToiletPanel }) {
                    SettingsStore.shared.saveFrame(window.frame)
                }
                windowDragOrigin = nil
            }
    }

    private func pullHandle() {
        withAnimation(.easeIn(duration: 0.08)) {
            handlePulled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.42)) {
                handlePulled = false
            }
            session.requestFlush()
        }
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

private struct Eye: View {
    var flushing: Bool
    var lookingUp: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: 14, height: flushing ? 4 : 16)
            if !flushing {
                Circle()
                    .fill(Color(red: 0.15, green: 0.18, blue: 0.22))
                    .frame(width: 6, height: 6)
                    .offset(y: lookingUp ? -3 : 1)
            }
        }
        .frame(width: 14, height: 16)
        .animation(.easeInOut(duration: 0.2), value: flushing)
        .animation(.easeInOut(duration: 0.2), value: lookingUp)
    }
}

private struct BowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rimY = rect.minY + 10
        path.move(to: CGPoint(x: rect.minX + 6, y: rimY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 6, y: rimY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX + 4, y: rect.height * 0.52),
            control2: CGPoint(x: rect.midX + rect.width * 0.30, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 6, y: rimY),
            control1: CGPoint(x: rect.midX - rect.width * 0.30, y: rect.maxY),
            control2: CGPoint(x: rect.minX - 4, y: rect.height * 0.52)
        )
        path.closeSubpath()
        return path
    }
}

private struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum ToiletPalette {
    static let porcelain = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let shadow = Color(red: 0.80, green: 0.86, blue: 0.90)
    static let outline = Color(red: 0.58, green: 0.66, blue: 0.72)
    static let water = Color(red: 0.45, green: 0.80, blue: 0.91)
    static let waterDeep = Color(red: 0.16, green: 0.52, blue: 0.70)
    static let gold = Color(red: 0.82, green: 0.64, blue: 0.22)
    static let goldHighlight = Color(red: 0.96, green: 0.86, blue: 0.48)
    static let goldShadow = Color(red: 0.62, green: 0.46, blue: 0.12)
    static let goldEdge = Color(red: 0.50, green: 0.38, blue: 0.08)
    static let blush = Color(red: 0.98, green: 0.62, blue: 0.68)
}
#endif
