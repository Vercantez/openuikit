import Foundation

public struct SCNCPUImage: Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var rgba: [UInt8]

    public init(width: Int, height: Int, rgba: [UInt8]) {
        self.width = width
        self.height = height
        self.rgba = rgba
    }

    public func pixel(x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        let i = (y * width + x) * 4
        guard i + 3 < rgba.count else { return (0, 0, 0, 0) }
        return (rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3])
    }
}

func _scnReadVertices(_ geometry: SCNGeometry) -> [SCNVector3] {
    guard let source = geometry.sources(for: .vertex).first, source.usesFloatComponents else { return [] }
    var out: [SCNVector3] = []
    out.reserveCapacity(source.vectorCount)
    source.data.withUnsafeBytes { raw in
        let floats = raw.bindMemory(to: Float.self)
        var offset = source.dataOffset / 4
        let stride = max(source.dataStride / 4, source.componentsPerVector)
        for _ in 0..<source.vectorCount {
            if offset + 2 < floats.count {
                out.append(SCNVector3(floats[offset], floats[offset + 1], floats[offset + 2]))
            }
            offset += stride
        }
    }
    return out
}

func _scnReadNormals(_ geometry: SCNGeometry) -> [SCNVector3] {
    guard let source = geometry.sources(for: .normal).first, source.usesFloatComponents else { return [] }
    var out: [SCNVector3] = []
    source.data.withUnsafeBytes { raw in
        let floats = raw.bindMemory(to: Float.self)
        var offset = source.dataOffset / 4
        let stride = max(source.dataStride / 4, source.componentsPerVector)
        for _ in 0..<source.vectorCount {
            if offset + 2 < floats.count {
                out.append(SCNVector3(floats[offset], floats[offset + 1], floats[offset + 2]))
            }
            offset += stride
        }
    }
    return out
}

func _scnReadUVs(_ geometry: SCNGeometry) -> [CGPoint] {
    guard let source = geometry.sources(for: .texcoord).first, source.usesFloatComponents else { return [] }
    var out: [CGPoint] = []
    source.data.withUnsafeBytes { raw in
        let floats = raw.bindMemory(to: Float.self)
        var offset = source.dataOffset / 4
        let stride = max(source.dataStride / 4, source.componentsPerVector)
        for _ in 0..<source.vectorCount {
            if offset + 1 < floats.count {
                out.append(CGPoint(x: CGFloat(floats[offset]), y: CGFloat(floats[offset + 1])))
            }
            offset += stride
        }
    }
    return out
}

func _scnReadTriangles(_ geometry: SCNGeometry) -> [UInt32] {
    var indices: [UInt32] = []
    for element in geometry.elements where element.primitiveType == .triangles {
        element.data.withUnsafeBytes { raw in
            if element.bytesPerIndex == 4 {
                let values = raw.bindMemory(to: UInt32.self)
                indices.append(contentsOf: values)
            } else if element.bytesPerIndex == 2 {
                let values = raw.bindMemory(to: UInt16.self)
                indices.append(contentsOf: values.map { UInt32($0) })
            } else if element.bytesPerIndex == 1 {
                let values = raw.bindMemory(to: UInt8.self)
                indices.append(contentsOf: values.map { UInt32($0) })
            }
        }
    }
    return indices
}

func _scnHitOptions(from raw: [String: Any]?) -> [SCNHitTestOption: Any] {
    var out: [SCNHitTestOption: Any] = [:]
    guard let raw else { return out }
    for (key, value) in raw {
        out[SCNHitTestOption(rawValue: key)] = value
    }
    return out
}

func _scnBoolOption(_ options: [SCNHitTestOption: Any], _ key: SCNHitTestOption, default value: Bool) -> Bool {
    if let flag = options[key] as? Bool { return flag }
    if let number = options[key] as? NSNumber { return number.boolValue }
    return value
}

func _scnRayTriangle(origin: SCNVector3, dir: SCNVector3, a: SCNVector3, b: SCNVector3, c: SCNVector3) -> (t: Float, u: Float, v: Float)? {
    let edge1 = _scnSub(b, a)
    let edge2 = _scnSub(c, a)
    let h = _scnCross(dir, edge2)
    let det = _scnDot(edge1, h)
    if abs(det) < 1e-8 { return nil }
    let inv = 1 / det
    let s = _scnSub(origin, a)
    let u = inv * _scnDot(s, h)
    if u < 0 || u > 1 { return nil }
    let q = _scnCross(s, edge1)
    let v = inv * _scnDot(dir, q)
    if v < 0 || u + v > 1 { return nil }
    let t = inv * _scnDot(edge2, q)
    if t < 1e-6 { return nil }
    return (t, u, v)
}

func _scnHitTestSegment(root: SCNNode, from pointA: SCNVector3, to pointB: SCNVector3, options: [SCNHitTestOption: Any], spaceNode: SCNNode?) -> [SCNHitTestResult] {
    let worldA = spaceNode?.convertPosition(pointA, to: nil) ?? pointA
    let worldB = spaceNode?.convertPosition(pointB, to: nil) ?? pointB
    let dir = _scnSub(worldB, worldA)
    let maxT = _scnLength(dir)
    if maxT == 0 { return [] }
    let ndir = _scnScale(dir, 1 / maxT)
    let ignoreHidden = _scnBoolOption(options, .ignoreHiddenNodes, default: true)
    let ignoreChildren = _scnBoolOption(options, .ignoreChildNodes, default: false)
    let boundingOnly = _scnBoolOption(options, .boundingBoxOnly, default: false)
    let backface = _scnBoolOption(options, .backFaceCulling, default: true)
    let firstOnly = _scnBoolOption(options, .firstFoundOnly, default: false)
    let sort = _scnBoolOption(options, .sortResults, default: true)
    let search = options[.searchMode] as? SCNHitTestSearchMode ?? .closest
    let mask = (options[.categoryBitMask] as? Int) ?? Int.max
    let start = (options[.rootNode] as? SCNNode) ?? root
    var hits: [(Float, SCNHitTestResult)] = []

    func visit(_ node: SCNNode) {
        if ignoreHidden && node.isHidden { return }
        if node.categoryBitMask & mask == 0 { return }
        if let geometry = node.geometry {
            let model = node.worldTransform
            if boundingOnly {
                let box = geometry.boundingBox
                let corners = [
                    SCNVector3(box.min.x, box.min.y, box.min.z), SCNVector3(box.max.x, box.min.y, box.min.z),
                    SCNVector3(box.min.x, box.max.y, box.min.z), SCNVector3(box.max.x, box.max.y, box.min.z),
                    SCNVector3(box.min.x, box.min.y, box.max.z), SCNVector3(box.max.x, box.min.y, box.max.z),
                    SCNVector3(box.min.x, box.max.y, box.max.z), SCNVector3(box.max.x, box.max.y, box.max.z)
                ].map { _scnTransformPoint(model, $0) }
                let b = _scnBounds(corners)
                if let t = _scnRayAABB(origin: worldA, dir: ndir, minB: b.0, maxB: b.1), t <= maxT {
                    let world = _scnAdd(worldA, _scnScale(ndir, t))
                    let local = _scnTransformPoint(SCNMatrix4Invert(model), world)
                    hits.append((t, SCNHitTestResult(
                        node: node, geometryIndex: 0, faceIndex: 0,
                        localCoordinates: local, worldCoordinates: world,
                        localNormal: SCNVector3(0, 1, 0), worldNormal: SCNVector3(0, 1, 0),
                        modelTransform: model
                    )))
                }
            } else {
                let verts = _scnReadVertices(geometry)
                let norms = _scnReadNormals(geometry)
                let tris = _scnReadTriangles(geometry)
                var i = 0
                var face = 0
                while i + 2 < tris.count {
                    let ia = Int(tris[i]), ib = Int(tris[i + 1]), ic = Int(tris[i + 2])
                    i += 3
                    guard ia < verts.count, ib < verts.count, ic < verts.count else { continue }
                    let a = _scnTransformPoint(model, verts[ia])
                    let b = _scnTransformPoint(model, verts[ib])
                    let c = _scnTransformPoint(model, verts[ic])
                    let n = _scnNormalize(_scnCross(_scnSub(b, a), _scnSub(c, a)))
                    if backface && _scnDot(n, ndir) > 0 {
                        face += 1
                        continue
                    }
                    if let hit = _scnRayTriangle(origin: worldA, dir: ndir, a: a, b: b, c: c), hit.t <= maxT {
                        let world = _scnAdd(worldA, _scnScale(ndir, hit.t))
                        let local = _scnTransformPoint(SCNMatrix4Invert(model), world)
                        var ln = SCNVector3(0, 1, 0)
                        if ia < norms.count, ib < norms.count, ic < norms.count {
                            ln = _scnNormalize(_scnAdd(_scnScale(norms[ia], 1 - hit.u - hit.v), _scnAdd(_scnScale(norms[ib], hit.u), _scnScale(norms[ic], hit.v))))
                        }
                        hits.append((hit.t, SCNHitTestResult(
                            node: node, geometryIndex: 0, faceIndex: face,
                            localCoordinates: local, worldCoordinates: world,
                            localNormal: ln, worldNormal: _scnNormalize(_scnTransformDirection(model, ln)),
                            modelTransform: model
                        )))
                        if firstOnly || search == .any {
                            return
                        }
                    }
                    face += 1
                }
            }
        }
        if !ignoreChildren {
            for child in node.childNodes {
                visit(child)
                if (firstOnly || search == .any) && !hits.isEmpty { return }
            }
        }
    }

    visit(start)
    if sort || search == .closest {
        hits.sort { $0.0 < $1.0 }
    }
    if search == .closest || firstOnly {
        return hits.first.map { [$0.1] } ?? []
    }
    return hits.map(\.1)
}

func _scnRayAABB(origin: SCNVector3, dir: SCNVector3, minB: SCNVector3, maxB: SCNVector3) -> Float? {
    func slab(_ o: Float, _ d: Float, _ minV: Float, _ maxV: Float) -> (Float, Float) {
        if abs(d) < 1e-8 {
            if o < minV || o > maxV { return (Float.infinity, -Float.infinity) }
            return (-Float.infinity, Float.infinity)
        }
        var t1 = (minV - o) / d
        var t2 = (maxV - o) / d
        if t1 > t2 { swap(&t1, &t2) }
        return (t1, t2)
    }
    let x = slab(origin.x, dir.x, minB.x, maxB.x)
    let y = slab(origin.y, dir.y, minB.y, maxB.y)
    let z = slab(origin.z, dir.z, minB.z, maxB.z)
    let tmin = max(x.0, y.0, z.0)
    let tmax = min(x.1, y.1, z.1)
    if tmax < tmin || tmax < 0 { return nil }
    return tmin >= 0 ? tmin : tmax
}

func _scnApplyConstraint(_ constraint: SCNConstraint, to node: SCNNode) {
    let factor = Float(constraint.influenceFactor)
    if let look = constraint as? SCNLookAtConstraint, let target = look.target {
        let dest = _scnAdd(target.worldPosition, look.targetOffset)
        let current = node.worldOrientation
        node.look(at: dest, up: look.worldUp, localFront: look.localFront)
        if factor < 1 {
            let q = node.worldOrientation
            node.worldOrientation = SCNQuaternion(
                x: current.x + (q.x - current.x) * factor,
                y: current.y + (q.y - current.y) * factor,
                z: current.z + (q.z - current.z) * factor,
                w: current.w + (q.w - current.w) * factor
            )
        }
        return
    }
    if let billboard = constraint as? SCNBillboardConstraint {
        var root = node
        while let parent = root.parent { root = parent }
        var eye: SCNNode?
        root.enumerateHierarchy { candidate, stop in
            if candidate.camera != nil {
                eye = candidate
                stop.pointee = true
            }
        }
        let target = eye?.worldPosition ?? SCNVector3(0, 0, 10)
        if billboard.freeAxes.contains(.Y) || billboard.freeAxes == .all {
            node.look(at: target)
        } else if billboard.freeAxes.contains(.X) {
            node.look(at: SCNVector3(node.worldPosition.x, target.y, node.worldPosition.z))
        }
        return
    }
    if let distance = constraint as? SCNDistanceConstraint, let target = distance.target {
        let delta = _scnSub(node.worldPosition, target.worldPosition)
        let len = _scnLength(delta)
        if len == 0 { return }
        let minD = Float(distance.minimumDistance)
        let maxD = Float(distance.maximumDistance)
        var desired = len
        if minD > 0 && len < minD { desired = minD }
        if maxD > 0 && len > maxD { desired = maxD }
        if desired != len {
            let scaled = _scnAdd(target.worldPosition, _scnScale(_scnNormalize(delta), desired))
            node.worldPosition = _scnLerp(node.worldPosition, scaled, factor == 0 ? 1 : factor)
        }
        return
    }
    if let transform = constraint as? SCNTransformConstraint, let block = transform._block {
        let input = transform._worldSpace ? node.worldTransform : node.transform
        let output = block(node, input)
        if transform._worldSpace {
            node.worldTransform = output
        } else {
            node.transform = output
        }
    }
}

func _scnViewMatrix(_ pointOfView: SCNNode?) -> SCNMatrix4 {
    guard let node = pointOfView else {
        return SCNMatrix4MakeTranslation(0, 0, -4)
    }
    return SCNMatrix4Invert(node.worldTransform)
}

func _scnProjectionMatrix(_ pointOfView: SCNNode?, size: CGSize) -> SCNMatrix4 {
    let viewport = size.width > 0 && size.height > 0 ? size : CGSize(width: 1, height: 1)
    if let camera = pointOfView?.camera {
        return camera.projectionTransform(withViewportSize: viewport)
    }
    return _scnPerspectiveProjection(fovYRadians: Float.pi / 3, aspect: Float(viewport.width / max(viewport.height, 1)), zNear: 0.1, zFar: 100)
}

func _scnTransformH(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector4 {
    SCNVector4(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43,
        w: m.m14 * p.x + m.m24 * p.y + m.m34 * p.z + m.m44
    )
}

func _scnTransformH4(_ m: SCNMatrix4, _ p: SCNVector4) -> SCNVector4 {
    SCNVector4(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41 * p.w,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42 * p.w,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43 * p.w,
        w: m.m14 * p.x + m.m24 * p.y + m.m34 * p.z + m.m44 * p.w
    )
}

func _scnColorContents(_ contents: Any?) -> (Float, Float, Float, Float) {
    if let v = contents as? SCNVector3 {
        return (v.x, v.y, v.z, 1)
    }
    if let v = contents as? SCNVector4 {
        return (v.x, v.y, v.z, v.w)
    }
    return (0.8, 0.8, 0.8, 1)
}

func _scnShade(
    material: SCNMaterial,
    normal: SCNVector3,
    viewDir: SCNVector3,
    worldPos: SCNVector3,
    lights: [(SCNNode, SCNLight)]
) -> (Float, Float, Float, Float) {
    let diffuse = _scnColorContents(material.diffuse.contents)
    let specular = _scnColorContents(material.specular.contents)
    let ambient = _scnColorContents(material.ambient.contents)
    let n = _scnNormalize(normal)
    let v = _scnNormalize(viewDir)
    var rgb = (0.0 as Float, 0.0 as Float, 0.0 as Float)
    if material.lightingModel == .constant || lights.isEmpty {
        return (diffuse.0, diffuse.1, diffuse.2, Float(material.transparency) * diffuse.3)
    }
    rgb.0 += ambient.0 * 0.1
    rgb.1 += ambient.1 * 0.1
    rgb.2 += ambient.2 * 0.1
    for (node, light) in lights {
        let lightColor = _scnColorContents(light.color)
        let intensity = Float(light.intensity) / 1000
        var l: SCNVector3
        if light.type == .directional {
            // SceneKit lights emit along local -Z; Lambert L is the opposite
            // (from the surface toward the light), which is worldFront (+Z).
            l = _scnNormalize(node.worldFront)
        } else if light.type == .ambient {
            rgb.0 += lightColor.0 * intensity * diffuse.0
            rgb.1 += lightColor.1 * intensity * diffuse.1
            rgb.2 += lightColor.2 * intensity * diffuse.2
            continue
        } else {
            l = _scnNormalize(_scnSub(node.worldPosition, worldPos))
        }
        let ndotl = max(0, _scnDot(n, l))
        rgb.0 += diffuse.0 * lightColor.0 * intensity * ndotl
        rgb.1 += diffuse.1 * lightColor.1 * intensity * ndotl
        rgb.2 += diffuse.2 * lightColor.2 * intensity * ndotl
        if material.lightingModel == .phong || material.lightingModel == .blinn {
            let specPow = max(Float(material.shininess), 1)
            let spec: Float
            if material.lightingModel == .blinn {
                let h = _scnNormalize(_scnAdd(l, v))
                spec = pow(max(0, _scnDot(n, h)), specPow)
            } else {
                let r = _scnNormalize(_scnSub(_scnScale(n, 2 * ndotl), l))
                spec = pow(max(0, _scnDot(r, v)), specPow)
            }
            rgb.0 += specular.0 * lightColor.0 * intensity * spec
            rgb.1 += specular.1 * lightColor.1 * intensity * spec
            rgb.2 += specular.2 * lightColor.2 * intensity * spec
        }
    }
    return (
        min(1, max(0, rgb.0)),
        min(1, max(0, rgb.1)),
        min(1, max(0, rgb.2)),
        Float(material.transparency) * diffuse.3
    )
}

func _scnRasterize(scene: SCNScene?, pointOfView: SCNNode?, size: CGSize, autoenablesDefaultLighting: Bool) -> SCNCPUImage {
    let width = max(1, Int(size.width.rounded()))
    let height = max(1, Int(size.height.rounded()))
    var rgba = [UInt8](repeating: 0, count: width * height * 4)
    var depth = [Float](repeating: Float.greatestFiniteMagnitude, count: width * height)
    if let bg = scene?.background.contents {
        let c = _scnColorContents(bg)
        for i in stride(from: 0, to: rgba.count, by: 4) {
            rgba[i] = UInt8(c.0 * 255)
            rgba[i + 1] = UInt8(c.1 * 255)
            rgba[i + 2] = UInt8(c.2 * 255)
            rgba[i + 3] = 255
        }
    } else {
        for i in stride(from: 0, to: rgba.count, by: 4) {
            rgba[i + 3] = 255
        }
    }
    guard let root = scene?.rootNode else {
        return SCNCPUImage(width: width, height: height, rgba: rgba)
    }
    let view = _scnViewMatrix(pointOfView)
    let proj = _scnProjectionMatrix(pointOfView, size: CGSize(width: width, height: height))
    // Row-vector: p_clip = p_world * view * proj.
    let viewProj = SCNMatrix4Mult(view, proj)
    var lights: [(SCNNode, SCNLight)] = []
    root.enumerateHierarchy { node, _ in
        if let light = node.light {
            lights.append((node, light))
        }
    }
    if lights.isEmpty && autoenablesDefaultLighting {
        let light = SCNLight()
        light.type = .directional
        light.intensity = 1000
        let dummy = SCNNode()
        dummy.light = light
        dummy.eulerAngles = SCNVector3(-0.4, 0.4, 0)
        lights.append((dummy, light))
    }
    struct Tri {
        var ax, ay, az, aw: Float
        var bx, by, bz, bw: Float
        var cx, cy, cz, cw: Float
        var na, nb, nc: SCNVector3
        var wa, wb, wc: SCNVector3
        var material: SCNMaterial
        var doubleSided: Bool
    }
    var tris: [Tri] = []
    root.enumerateHierarchy { node, _ in
        if node.isHidden { return }
        guard let geometry = node.geometry else { return }
        let verts = _scnReadVertices(geometry)
        let norms = _scnReadNormals(geometry)
        let indices = _scnReadTriangles(geometry)
        let model = node.worldTransform
        let material = geometry.firstMaterial ?? SCNMaterial()
        var i = 0
        while i + 2 < indices.count {
            let ia = Int(indices[i]), ib = Int(indices[i + 1]), ic = Int(indices[i + 2])
            i += 3
            guard ia < verts.count, ib < verts.count, ic < verts.count else { continue }
            let wa = _scnTransformPoint(model, verts[ia])
            let wb = _scnTransformPoint(model, verts[ib])
            let wc = _scnTransformPoint(model, verts[ic])
            let ca = _scnTransformH(viewProj, wa)
            let cb = _scnTransformH(viewProj, wb)
            let cc = _scnTransformH(viewProj, wc)
            var na = SCNVector3(0, 1, 0)
            var nb = na
            var nc = na
            if ia < norms.count, ib < norms.count, ic < norms.count {
                na = _scnNormalize(_scnTransformDirection(model, norms[ia]))
                nb = _scnNormalize(_scnTransformDirection(model, norms[ib]))
                nc = _scnNormalize(_scnTransformDirection(model, norms[ic]))
            }
            tris.append(Tri(
                ax: ca.x, ay: ca.y, az: ca.z, aw: ca.w,
                bx: cb.x, by: cb.y, bz: cb.z, bw: cb.w,
                cx: cc.x, cy: cc.y, cz: cc.z, cw: cc.w,
                na: na, nb: nb, nc: nc, wa: wa, wb: wb, wc: wc,
                material: material, doubleSided: material.isDoubleSided
            ))
        }
    }
    let eye = pointOfView?.worldPosition ?? SCNVector3(0, 0, 4)
    for tri in tris {
        if tri.aw <= 1e-6 || tri.bw <= 1e-6 || tri.cw <= 1e-6 { continue }
        let ax = (tri.ax / tri.aw * 0.5 + 0.5) * Float(width - 1)
        let ay = (1 - (tri.ay / tri.aw * 0.5 + 0.5)) * Float(height - 1)
        let bx = (tri.bx / tri.bw * 0.5 + 0.5) * Float(width - 1)
        let by = (1 - (tri.by / tri.bw * 0.5 + 0.5)) * Float(height - 1)
        let cx = (tri.cx / tri.cw * 0.5 + 0.5) * Float(width - 1)
        let cy = (1 - (tri.cy / tri.cw * 0.5 + 0.5)) * Float(height - 1)
        let area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
        if abs(area) < 1e-8 { continue }
        if area > 0 && !tri.doubleSided && tri.material.cullMode == .back { continue }
        let minX = max(0, Int(floor(min(ax, bx, cx))))
        let maxX = min(width - 1, Int(ceil(max(ax, bx, cx))))
        let minY = max(0, Int(floor(min(ay, by, cy))))
        let maxY = min(height - 1, Int(ceil(max(ay, by, cy))))
        let invA = 1 / area
        for y in minY...maxY {
            for x in minX...maxX {
                let px = Float(x) + 0.5
                let py = Float(y) + 0.5
                let w0 = ((bx - px) * (cy - py) - (by - py) * (cx - px)) * invA
                let w1 = ((cx - px) * (ay - py) - (cy - py) * (ax - px)) * invA
                let w2 = 1 - w0 - w1
                if w0 < 0 || w1 < 0 || w2 < 0 { continue }
                let z = w0 * (tri.az / tri.aw) + w1 * (tri.bz / tri.bw) + w2 * (tri.cz / tri.cw)
                let idx = y * width + x
                if z >= depth[idx] { continue }
                depth[idx] = z
                let n = _scnNormalize(SCNVector3(
                    x: tri.na.x * w0 + tri.nb.x * w1 + tri.nc.x * w2,
                    y: tri.na.y * w0 + tri.nb.y * w1 + tri.nc.y * w2,
                    z: tri.na.z * w0 + tri.nb.z * w1 + tri.nc.z * w2
                ))
                let world = SCNVector3(
                    x: tri.wa.x * w0 + tri.wb.x * w1 + tri.wc.x * w2,
                    y: tri.wa.y * w0 + tri.wb.y * w1 + tri.wc.y * w2,
                    z: tri.wa.z * w0 + tri.wb.z * w1 + tri.wc.z * w2
                )
                let color = _scnShade(
                    material: tri.material,
                    normal: n,
                    viewDir: _scnNormalize(_scnSub(eye, world)),
                    worldPos: world,
                    lights: lights
                )
                let o = idx * 4
                rgba[o] = UInt8((color.0 * 255).rounded())
                rgba[o + 1] = UInt8((color.1 * 255).rounded())
                rgba[o + 2] = UInt8((color.2 * 255).rounded())
                rgba[o + 3] = UInt8((color.3 * 255).rounded())
            }
        }
    }
    return SCNCPUImage(width: width, height: height, rgba: rgba)
}
