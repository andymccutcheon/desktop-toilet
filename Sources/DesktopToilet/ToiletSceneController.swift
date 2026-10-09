#if os(macOS)
import AppKit
import QuartzCore
import SceneKit
import SwiftUI
import ToiletCore

final class ToiletSCNView: SCNView {
    var onHandlePress: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    override var isOpaque: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeAlways,
            .inVisibleRect,
        ]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
        toolTip = nil
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        toolTip = ToiletHit.classify(nodeName: hitName(at: point)) == .handle ? "Flush" : nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        let point = convert(event.locationInWindow, from: nil)
        if ToiletHit.classify(nodeName: hitName(at: point)) == .handle {
            onHandlePress?()
            return
        }
        window?.performWindowDrag(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if let window = window {
            SettingsStore.shared.saveFrame(window.frame)
        }
        super.mouseUp(with: event)
    }

    private func hitName(at point: NSPoint) -> String? {
        let options: [SCNHitTestOption: Any] = [
            .categoryBitMask: NSNumber(value: ToiletSceneController.pickBit),
            .searchMode: NSNumber(value: SCNHitTestSearchMode.closest.rawValue),
            .ignoreHiddenNodes: NSNumber(value: true),
        ]
        let hits = hitTest(point, options: options)
        var node = hits.first?.node
        while let current = node {
            if let name = current.name, !name.isEmpty {
                return name
            }
            node = current.parent
        }
        return nil
    }
}

final class ToiletSceneController {
    static let pickBit = 1 << 1
    private static let ignoreBit = 1 << 3

    private weak var scnView: ToiletSCNView?

    private let porcelain = SCNNode()
    private let lidHinge = SCNNode()
    private let handlePivot = SCNNode()
    private let waterNode = SCNNode()
    private let vortexNode = SCNNode()

    private var didInitialSync = false
    private var lastLidOpen = false
    private var lastFlushing = false
    private var lastQueueCount = 0
    private var lastHovering = false
    private var lastDropTargeted = false
    private var lastFinish = ToiletHandleFinish.gold

    private var idleWork: DispatchWorkItem?
    private var renderUntil: TimeInterval = 0

    var onHandleFlush: (() -> Void)?

    func install(in view: ToiletSCNView) {
        scnView = view
        view.scene = buildScene()
        view.autoresizingMask = [.width, .height]
        view.backgroundColor = .clear
        view.wantsLayer = true
        if let layer = view.layer {
            layer.isOpaque = false
            layer.backgroundColor = NSColor.clear.cgColor
        }
        view.antialiasingMode = .multisampling2X
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.rendersContinuously = false
        view.isPlaying = false
        view.preferredFramesPerSecond = 30
        view.isJitteringEnabled = false

        view.onHandlePress = { [weak self] in
            self?.pullHandle()
        }
    }

    func sync(from session: ToiletSession, finish: ToiletHandleFinish) {
        let animated = didInitialSync
        didInitialSync = true

        if finish != lastFinish {
            applyHandleFinish(finish)
            lastFinish = finish
        }

        if session.lidOpen != lastLidOpen {
            setLid(open: session.lidOpen, animated: animated)
            lastLidOpen = session.lidOpen
        }

        if session.isHovering != lastHovering {
            setHovering(session.isHovering, animated: animated)
            lastHovering = session.isHovering
        }

        if session.isDropTargeted != lastDropTargeted {
            if !session.isFlushing {
                nudgeWater(targeted: session.isDropTargeted, animated: animated)
            }
            lastDropTargeted = session.isDropTargeted
        }

        if session.queue.count > lastQueueCount, !session.isFlushing {
            playRipple()
        }

        if session.isFlushing, !lastFlushing {
            playFlush(urls: session.queue.urls)
        } else if !session.isFlushing, lastFlushing {
            restoreWater()
        }

        lastFlushing = session.isFlushing
        lastQueueCount = session.queue.count
    }

    private func pullHandle() {
        animateHandle(pressed: true, duration: ToiletMotion.handlePressDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.onHandleFlush?()
            self?.animateHandle(pressed: false, duration: ToiletMotion.handleReleaseDuration)
        }
    }

    private func setLid(open: Bool, animated: Bool) {
        let angle = CGFloat(open ? -ToiletMotion.lidOpenRadians : 0)
        let duration = animated ? ToiletMotion.lidDuration : 0
        if animated {
            keepRendering(for: duration + 0.05)
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        lidHinge.eulerAngles.x = angle
        SCNTransaction.commit()
    }

    private func setHovering(_ hovering: Bool, animated: Bool) {
        let duration = animated ? ToiletMotion.hoverDuration : 0
        if animated {
            keepRendering(for: duration + 0.04)
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        porcelain.position.y = CGFloat(hovering ? ToiletMotion.hoverLift : 0)
        porcelain.eulerAngles.y = -0.40 + CGFloat(hovering ? ToiletMotion.hoverYaw : 0)
        SCNTransaction.commit()
    }

    private func animateHandle(pressed: Bool, duration: Double) {
        keepRendering(for: duration + 0.08)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(
            name: pressed ? .easeIn : .easeOut
        )
        handlePivot.eulerAngles.x = CGFloat(pressed ? ToiletMotion.handlePressRadians : 0.12)
        SCNTransaction.commit()
    }

    private func nudgeWater(targeted: Bool, animated: Bool) {
        let duration = animated ? 0.22 : 0
        if animated {
            keepRendering(for: 0.28)
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        waterNode.eulerAngles.y += targeted ? 0.32 : -0.32
        SCNTransaction.commit()
    }

    private func playRipple() {
        keepRendering(for: 0.5)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.12
        waterNode.scale = SCNVector3(1.07, 1, 1.07)
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.28
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            self.waterNode.scale = SCNVector3(1, 1, 1)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }

    private func playFlush(urls: [URL]) {
        vortexNode.childNodes.forEach { $0.removeFromParentNode() }
        vortexNode.eulerAngles.y = 0
        waterNode.eulerAngles.y = 0
        waterNode.scale = SCNVector3(1, 1, 1)
        waterNode.opacity = 1

        let shown = Array(urls.prefix(8))
        for (index, url) in shown.enumerated() {
            let node = makeIconNode(url: url)
            let turns = CGFloat(index) / CGFloat(max(shown.count, 1)) * (2 * CGFloat.pi)
            node.position = SCNVector3(cos(turns) * 0.075, 0.03, sin(turns) * 0.075)
            vortexNode.addChildNode(node)
        }

        keepRendering(for: ToiletMotion.flushRenderBudget)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = ToiletMotion.flushSwirlDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeIn)
        let spin = CGFloat(ToiletMotion.flushSwirlTurns) * 2 * CGFloat.pi
        vortexNode.eulerAngles.y = spin
        waterNode.eulerAngles.y = spin
        waterNode.scale = SCNVector3(0.14, 0.14, 0.14)
        waterNode.opacity = 0.18
        for child in vortexNode.childNodes {
            child.position = SCNVector3(0, -0.07, 0)
            child.scale = SCNVector3(0.04, 0.04, 0.04)
            child.opacity = 0
        }
        SCNTransaction.commit()
    }

    private func restoreWater() {
        vortexNode.childNodes.forEach { $0.removeFromParentNode() }
        keepRendering(for: ToiletMotion.waterRestoreDuration + 0.05)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = ToiletMotion.waterRestoreDuration
        waterNode.scale = SCNVector3(1, 1, 1)
        waterNode.opacity = 1
        waterNode.eulerAngles.y = 0
        vortexNode.eulerAngles.y = 0
        SCNTransaction.commit()
    }

    private func makeIconNode(url: URL) -> SCNNode {
        let plane = SCNPlane(width: 0.042, height: 0.042)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        plane.firstMaterial = ToiletMaterials.icon(icon)
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }

    private func applyHandleFinish(_ finish: ToiletHandleFinish) {
        let material = ToiletMaterials.metal(finish: finish)
        applyMaterial(material, to: handlePivot)
    }

    private func applyMaterial(_ material: SCNMaterial, to node: SCNNode) {
        if node.geometry != nil {
            node.geometry?.firstMaterial = material
        }
        for child in node.childNodes {
            applyMaterial(material, to: child)
        }
    }

    private func keepRendering(for duration: TimeInterval) {
        let until = Date().timeIntervalSinceReferenceDate + duration
        renderUntil = max(renderUntil, until)
        scnView?.isPlaying = true
        scnView?.rendersContinuously = true
        scnView?.preferredFramesPerSecond = 30
        scheduleIdleCheck()
    }

    private func scheduleIdleCheck() {
        idleWork?.cancel()
        let remaining = max(0.04, renderUntil - Date().timeIntervalSinceReferenceDate)
        let work = DispatchWorkItem { [weak self] in
            self?.goIdleIfDue()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: work)
    }

    private func goIdleIfDue() {
        let remaining = renderUntil - Date().timeIntervalSinceReferenceDate
        if remaining > 0.02 {
            scheduleIdleCheck()
            return
        }
        scnView?.rendersContinuously = false
        scnView?.isPlaying = false
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        scene.lightingEnvironment.contents = ToiletTextures.studioEnvironment()
        scene.lightingEnvironment.intensity = 0.58

        porcelain.eulerAngles.y = -0.40
        scene.rootNode.addChildNode(porcelain)
        scene.rootNode.addChildNode(makeShadow())
        scene.rootNode.addChildNode(makeCamera())
        for light in makeLights() {
            scene.rootNode.addChildNode(light)
        }

        porcelain.addChildNode(makeBowl())
        porcelain.addChildNode(makeSeat())
        porcelain.addChildNode(makeLid())
        porcelain.addChildNode(makeTank())
        porcelain.addChildNode(makeBase())
        return scene
    }

    private func makeBowl() -> SCNNode {
        let mesh = LatheMesh.generate(
            profile: ToiletProfiles.bowl,
            segments: ToiletProfiles.bowlSegments
        )
        let node = SCNNode(geometry: SceneMesh.geometry(from: mesh))
        node.name = ToiletPart.bowl.rawValue
        node.scale = SCNVector3(1.02, 1.0, 1.20)
        markPickable(node, name: ToiletPart.bowl.rawValue)

        let water = SCNCylinder(radius: 0.126, height: 0.005)
        water.firstMaterial = ToiletMaterials.water()
        waterNode.geometry = water
        waterNode.name = ToiletPart.water.rawValue
        waterNode.position = SCNVector3(0, 0.258, 0)
        markPickable(waterNode, name: ToiletPart.bowl.rawValue)
        node.addChildNode(waterNode)

        vortexNode.name = "vortex"
        vortexNode.position = SCNVector3(0, 0.268, 0)
        node.addChildNode(vortexNode)
        return node
    }

    private func makeSeat() -> SCNNode {
        let torus = SCNTorus(ringRadius: 0.168, pipeRadius: 0.015)
        torus.firstMaterial = ToiletMaterials.porcelain()
        let node = SCNNode(geometry: torus)
        node.name = ToiletPart.seat.rawValue
        node.position = SCNVector3(0, 0.418, 0.014)
        node.scale = SCNVector3(1.04, 0.40, 1.22)
        markPickable(node, name: ToiletPart.seat.rawValue)
        return node
    }

    private func makeLid() -> SCNNode {
        lidHinge.name = "lidHinge"
        lidHinge.position = SCNVector3(0, 0.432, -0.155)

        let slab = SCNBox(width: 0.352, height: 0.016, length: 0.395, chamferRadius: 0.01)
        slab.firstMaterial = ToiletMaterials.porcelain()
        let lid = SCNNode(geometry: slab)
        lid.name = ToiletPart.lid.rawValue
        lid.position = SCNVector3(0, 0.004, 0.168)
        lidHinge.addChildNode(lid)
        markPickable(lidHinge, name: ToiletPart.lid.rawValue)
        return lidHinge
    }

    private func makeTank() -> SCNNode {
        let group = SCNNode()
        group.name = ToiletPart.tank.rawValue

        let body = SCNBox(width: 0.355, height: 0.295, length: 0.152, chamferRadius: 0.028)
        body.firstMaterial = ToiletMaterials.porcelain()
        let tank = SCNNode(geometry: body)
        tank.position = SCNVector3(0, 0.555, -0.238)
        group.addChildNode(tank)

        let cap = SCNBox(width: 0.362, height: 0.018, length: 0.160, chamferRadius: 0.007)
        cap.firstMaterial = ToiletMaterials.porcelain()
        let lid = SCNNode(geometry: cap)
        lid.position = SCNVector3(0, 0.708, -0.238)
        group.addChildNode(lid)

        let horn = SCNBox(width: 0.132, height: 0.078, length: 0.095, chamferRadius: 0.018)
        horn.firstMaterial = ToiletMaterials.porcelain()
        let coupling = SCNNode(geometry: horn)
        coupling.position = SCNVector3(0, 0.430, -0.175)
        group.addChildNode(coupling)

        let decal = SCNPlane(width: 0.10, height: 0.044)
        decal.firstMaterial = ToiletMaterials.decal()
        let decalNode = SCNNode(geometry: decal)
        decalNode.position = SCNVector3(0, 0.575, -0.160)
        group.addChildNode(decalNode)

        handlePivot.name = ToiletPart.handle.rawValue
        handlePivot.position = SCNVector3(-0.180, 0.568, -0.220)
        handlePivot.eulerAngles.x = 0.12

        let metal = ToiletMaterials.metal(finish: .gold)

        let plate = SCNCylinder(radius: 0.016, height: 0.007)
        plate.firstMaterial = metal
        let plateNode = SCNNode(geometry: plate)
        plateNode.name = "handlePlate"
        plateNode.eulerAngles.z = CGFloat.pi / 2
        plateNode.position = SCNVector3(-0.004, 0, 0)
        handlePivot.addChildNode(plateNode)

        let stem = SCNCylinder(radius: 0.008, height: 0.026)
        stem.firstMaterial = metal
        let stemNode = SCNNode(geometry: stem)
        stemNode.name = "handleStem"
        stemNode.eulerAngles.z = CGFloat.pi / 2
        stemNode.position = SCNVector3(-0.016, 0, 0)
        handlePivot.addChildNode(stemNode)

        let lever = SCNCapsule(capRadius: 0.0085, height: 0.076)
        lever.firstMaterial = metal
        let leverNode = SCNNode(geometry: lever)
        leverNode.name = "handleLever"
        leverNode.eulerAngles.x = CGFloat.pi / 2
        leverNode.position = SCNVector3(-0.028, 0.0, 0.016)
        handlePivot.addChildNode(leverNode)

        group.addChildNode(handlePivot)
        markPickable(group, name: ToiletPart.tank.rawValue)
        markPickable(handlePivot, name: ToiletPart.handle.rawValue)
        return group
    }

    private func makeBase() -> SCNNode {
        let foot = SCNCylinder(radius: 0.142, height: 0.012)
        foot.firstMaterial = ToiletMaterials.porcelain()
        let node = SCNNode(geometry: foot)
        node.name = ToiletPart.base.rawValue
        node.position = SCNVector3(0, 0.008, 0.012)
        node.scale = SCNVector3(1.05, 1, 1.18)
        markPickable(node, name: ToiletPart.base.rawValue)
        return node
    }

    private func makeShadow() -> SCNNode {
        let plane = SCNPlane(width: 0.74, height: 0.80)
        plane.firstMaterial = ToiletMaterials.contactShadow()
        let node = SCNNode(geometry: plane)
        node.name = ToiletPart.shadow.rawValue
        node.eulerAngles.x = -CGFloat.pi / 2
        node.position = SCNVector3(0.01, 0.001, 0.03)
        node.categoryBitMask = Self.ignoreBit
        node.castsShadow = false
        return node
    }

    private func makeCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 26
        camera.zNear = 0.05
        camera.zFar = 8
        camera.wantsExposureAdaptation = false
        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0.20, 0.56, 1.14)
        node.look(at: SCNVector3(0.0, 0.30, -0.05))
        return node
    }

    private func makeLights() -> [SCNNode] {
        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = NSColor(calibratedWhite: 0.46, alpha: 1)
        ambientLight.intensity = 320
        ambient.light = ambientLight

        let key = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.94, alpha: 1)
        keyLight.intensity = 880
        keyLight.castsShadow = false
        key.light = keyLight
        key.eulerAngles = SCNVector3(-0.85, 0.55, 0)

        let fill = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = NSColor(calibratedRed: 0.80, green: 0.87, blue: 0.96, alpha: 1)
        fillLight.intensity = 300
        fillLight.castsShadow = false
        fill.light = fillLight
        fill.eulerAngles = SCNVector3(-0.25, -0.95, 0)

        let rim = SCNNode()
        let rimLight = SCNLight()
        rimLight.type = .directional
        rimLight.color = NSColor(calibratedWhite: 0.93, alpha: 1)
        rimLight.intensity = 380
        rimLight.castsShadow = false
        rim.light = rimLight
        rim.eulerAngles = SCNVector3(-0.15, 2.9, 0)

        return [ambient, key, fill, rim]
    }

    private func markPickable(_ node: SCNNode, name: String) {
        node.name = node.name ?? name
        node.categoryBitMask = Self.pickBit
        node.enumerateChildNodes { child, _ in
            if child.name == nil {
                child.name = name
            }
            if child.categoryBitMask == 1 {
                child.categoryBitMask = Self.pickBit
            }
        }
    }
}

struct ToiletSceneView: NSViewRepresentable {
    @ObservedObject var session: ToiletSession
    var handleFinish: ToiletHandleFinish

    func makeCoordinator() -> ToiletSceneController {
        ToiletSceneController()
    }

    func makeNSView(context: Context) -> ToiletSCNView {
        let view = ToiletSCNView()
        context.coordinator.install(in: view)
        context.coordinator.onHandleFlush = { [weak session] in
            session?.requestFlush()
        }
        view.onHoverChange = { [weak session] hovering in
            session?.isHovering = hovering
        }
        return view
    }

    func updateNSView(_ nsView: ToiletSCNView, context: Context) {
        context.coordinator.sync(from: session, finish: handleFinish)
    }
}
#endif
