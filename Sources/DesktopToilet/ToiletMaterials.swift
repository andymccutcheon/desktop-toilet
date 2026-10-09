#if os(macOS)
import AppKit
import SceneKit
import ToiletCore

enum ToiletMaterials {
    static func porcelain() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = NSColor(calibratedRed: 0.96, green: 0.972, blue: 0.985, alpha: 1)
        material.metalness.contents = NSNumber(value: 0.05)
        material.roughness.contents = NSNumber(value: 0.17)
        material.specular.contents = NSColor.white
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true
        return material
    }

    static func metal(finish: ToiletHandleFinish) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.metalness.contents = NSNumber(value: 1.0)
        material.specular.contents = NSColor.white
        switch finish {
        case .gold:
            material.diffuse.contents = NSColor(calibratedRed: 0.86, green: 0.70, blue: 0.28, alpha: 1)
            material.roughness.contents = NSNumber(value: 0.22)
        case .chrome:
            material.diffuse.contents = NSColor(calibratedRed: 0.80, green: 0.83, blue: 0.86, alpha: 1)
            material.roughness.contents = NSNumber(value: 0.10)
        }
        return material
    }

    static func water() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = ToiletTextures.water()
        material.metalness.contents = NSNumber(value: 0.02)
        material.roughness.contents = NSNumber(value: 0.08)
        material.transparent.contents = NSColor(calibratedWhite: 1, alpha: 0.38)
        material.transparency = 0.38
        material.blendMode = .alpha
        material.isDoubleSided = true
        material.writesToDepthBuffer = false
        return material
    }

    static func contactShadow() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        let image = ToiletTextures.contactShadow()
        material.diffuse.contents = image
        material.transparent.contents = image
        material.blendMode = .alpha
        material.writesToDepthBuffer = false
        return material
    }

    static func decal() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        let image = ToiletTextures.monogram()
        material.diffuse.contents = image
        material.transparent.contents = image
        material.blendMode = .alpha
        material.writesToDepthBuffer = false
        material.isDoubleSided = false
        return material
    }

    static func icon(_ image: NSImage) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = image
        material.isDoubleSided = true
        material.writesToDepthBuffer = false
        return material
    }
}

enum ToiletTextures {
    static func water() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        return NSImage(size: size, flipped: false) { rect in
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            let oval = NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            let gradient = NSGradient(colors: [
                NSColor(calibratedRed: 0.12, green: 0.40, blue: 0.55, alpha: 0.95),
                NSColor(calibratedRed: 0.32, green: 0.70, blue: 0.84, alpha: 0.80),
                NSColor(calibratedRed: 0.62, green: 0.86, blue: 0.93, alpha: 0.55),
            ])
            gradient?.draw(in: oval, angle: 92)

            NSColor.white.withAlphaComponent(0.28).setStroke()
            for step in 0..<5 {
                let inset = CGFloat(18 + step * 16)
                let ring = NSBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset * 0.72))
                ring.lineWidth = 2
                ring.stroke()
            }

            NSColor.white.withAlphaComponent(0.38).setFill()
            NSBezierPath(ovalIn: NSRect(x: 78, y: 158, width: 86, height: 34)).fill()

            NSColor(calibratedRed: 0.08, green: 0.28, blue: 0.40, alpha: 0.22).setStroke()
            let swirl = NSBezierPath()
            swirl.lineWidth = 5
            swirl.move(to: NSPoint(x: 128, y: 128))
            swirl.curve(
                to: NSPoint(x: 188, y: 96),
                controlPoint1: NSPoint(x: 148, y: 150),
                controlPoint2: NSPoint(x: 176, y: 132)
            )
            swirl.curve(
                to: NSPoint(x: 96, y: 72),
                controlPoint1: NSPoint(x: 204, y: 56),
                controlPoint2: NSPoint(x: 132, y: 48)
            )
            swirl.stroke()
            return true
        }
    }

    static func contactShadow() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        return NSImage(size: size, flipped: false) { rect in
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 6, dy: 18))
            let gradient = NSGradient(colorsAndLocations:
                (NSColor.black.withAlphaComponent(0.30), 0.0),
                (NSColor.black.withAlphaComponent(0.14), 0.38),
                (NSColor.black.withAlphaComponent(0.0), 1.0)
            )
            gradient?.draw(in: path, relativeCenterPosition: .zero)
            return true
        }
    }

    static func monogram() -> NSImage {
        let size = NSSize(width: 128, height: 56)
        return NSImage(size: size, flipped: false) { rect in
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()
            let text = "DT" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 30, weight: .heavy),
                .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 0.42),
            ]
            let textSize = text.size(withAttributes: attributes)
            let origin = NSPoint(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2
            )
            text.draw(at: origin, withAttributes: attributes)
            return true
        }
    }

    static func studioEnvironment() -> NSImage {
        let size = NSSize(width: 64, height: 32)
        return NSImage(size: size, flipped: false) { rect in
            let gradient = NSGradient(colors: [
                NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1),
                NSColor(calibratedRed: 0.78, green: 0.82, blue: 0.88, alpha: 1),
                NSColor(calibratedRed: 0.42, green: 0.45, blue: 0.50, alpha: 1),
            ])
            gradient?.draw(in: rect, angle: 90)
            return true
        }
    }
}

enum SceneMesh {
    static func geometry(from mesh: MeshData) -> SCNGeometry {
        var positions: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        positions.reserveCapacity(mesh.vertices.count)
        normals.reserveCapacity(mesh.vertices.count)
        uvs.reserveCapacity(mesh.vertices.count)

        for vertex in mesh.vertices {
            positions.append(SCNVector3(CGFloat(vertex.px), CGFloat(vertex.py), CGFloat(vertex.pz)))
            normals.append(SCNVector3(CGFloat(vertex.nx), CGFloat(vertex.ny), CGFloat(vertex.nz)))
            uvs.append(CGPoint(x: CGFloat(vertex.u), y: CGFloat(vertex.v)))
        }

        let sources = [
            SCNGeometrySource(vertices: positions),
            SCNGeometrySource(normals: normals),
            SCNGeometrySource(textureCoordinates: uvs),
        ]
        let element = SCNGeometryElement(indices: mesh.indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: sources, elements: [element])
        geometry.firstMaterial = ToiletMaterials.porcelain()
        return geometry
    }
}
#endif
