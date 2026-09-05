import Foundation

struct _SCNMesh {
    var vertices: [SCNVector3]
    var normals: [SCNVector3]
    var uvs: [CGPoint]
    var indices: [UInt32]
    var min: SCNVector3
    var max: SCNVector3
}

func _scnAssignMesh(_ geometry: SCNGeometry, _ mesh: _SCNMesh) {
    geometry.sources = [
        SCNGeometrySource(vertices: mesh.vertices),
        SCNGeometrySource(normals: mesh.normals),
        SCNGeometrySource(textureCoordinates: mesh.uvs)
    ]
    geometry.elements = [SCNGeometryElement(indices: mesh.indices, primitiveType: .triangles)]
    geometry._linuxBoundingBox = (mesh.min, mesh.max)
}

func _scnPushTriangle(
    _ vertices: inout [SCNVector3],
    _ normals: inout [SCNVector3],
    _ uvs: inout [CGPoint],
    _ indices: inout [UInt32],
    _ a: SCNVector3, _ b: SCNVector3, _ c: SCNVector3,
    _ na: SCNVector3, _ nb: SCNVector3, _ nc: SCNVector3,
    _ ua: CGPoint, _ ub: CGPoint, _ uc: CGPoint
) {
    let base = UInt32(vertices.count)
    vertices.append(contentsOf: [a, b, c])
    normals.append(contentsOf: [na, nb, nc])
    uvs.append(contentsOf: [ua, ub, uc])
    indices.append(contentsOf: [base, base + 1, base + 2])
}

func _scnBounds(_ verts: [SCNVector3]) -> (SCNVector3, SCNVector3) {
    var minV = SCNVector3(x: Float.greatestFiniteMagnitude, y: Float.greatestFiniteMagnitude, z: Float.greatestFiniteMagnitude)
    var maxV = SCNVector3(x: -Float.greatestFiniteMagnitude, y: -Float.greatestFiniteMagnitude, z: -Float.greatestFiniteMagnitude)
    for v in verts {
        minV.x = min(minV.x, v.x); minV.y = min(minV.y, v.y); minV.z = min(minV.z, v.z)
        maxV.x = max(maxV.x, v.x); maxV.y = max(maxV.y, v.y); maxV.z = max(maxV.z, v.z)
    }
    return (minV, maxV)
}

func _scnBoxMesh(width: Float, height: Float, length: Float, wSeg: Int, hSeg: Int, lSeg: Int) -> _SCNMesh {
    let hx = width * 0.5
    let hy = height * 0.5
    let hz = length * 0.5
    let ws = max(1, wSeg)
    let hs = max(1, hSeg)
    let ls = max(1, lSeg)
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []

    func face(_ origin: SCNVector3, _ uDir: SCNVector3, _ vDir: SCNVector3, _ n: SCNVector3, _ uCount: Int, _ vCount: Int) {
        for v in 0..<vCount {
            let tv0 = Float(v) / Float(vCount)
            let tv1 = Float(v + 1) / Float(vCount)
            for u in 0..<uCount {
                let tu0 = Float(u) / Float(uCount)
                let tu1 = Float(u + 1) / Float(uCount)
                let p00 = _scnAdd(origin, _scnAdd(_scnScale(uDir, tu0), _scnScale(vDir, tv0)))
                let p10 = _scnAdd(origin, _scnAdd(_scnScale(uDir, tu1), _scnScale(vDir, tv0)))
                let p11 = _scnAdd(origin, _scnAdd(_scnScale(uDir, tu1), _scnScale(vDir, tv1)))
                let p01 = _scnAdd(origin, _scnAdd(_scnScale(uDir, tu0), _scnScale(vDir, tv1)))
                _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p10, p11, n, n, n,
                                 CGPoint(x: CGFloat(tu0), y: CGFloat(tv0)),
                                 CGPoint(x: CGFloat(tu1), y: CGFloat(tv0)),
                                 CGPoint(x: CGFloat(tu1), y: CGFloat(tv1)))
                _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p11, p01, n, n, n,
                                 CGPoint(x: CGFloat(tu0), y: CGFloat(tv0)),
                                 CGPoint(x: CGFloat(tu1), y: CGFloat(tv1)),
                                 CGPoint(x: CGFloat(tu0), y: CGFloat(tv1)))
            }
        }
    }

    face(SCNVector3(-hx, -hy, hz), SCNVector3(width, 0, 0), SCNVector3(0, height, 0), SCNVector3(0, 0, 1), ws, hs)
    face(SCNVector3(hx, -hy, -hz), SCNVector3(-width, 0, 0), SCNVector3(0, height, 0), SCNVector3(0, 0, -1), ws, hs)
    face(SCNVector3(-hx, -hy, -hz), SCNVector3(0, 0, length), SCNVector3(0, height, 0), SCNVector3(-1, 0, 0), ls, hs)
    face(SCNVector3(hx, -hy, hz), SCNVector3(0, 0, -length), SCNVector3(0, height, 0), SCNVector3(1, 0, 0), ls, hs)
    face(SCNVector3(-hx, hy, hz), SCNVector3(width, 0, 0), SCNVector3(0, 0, -length), SCNVector3(0, 1, 0), ws, ls)
    face(SCNVector3(-hx, -hy, -hz), SCNVector3(width, 0, 0), SCNVector3(0, 0, length), SCNVector3(0, -1, 0), ws, ls)
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnPlaneMesh(width: Float, height: Float, wSeg: Int, hSeg: Int) -> _SCNMesh {
    let hx = width * 0.5
    let hy = height * 0.5
    let ws = max(1, wSeg)
    let hs = max(1, hSeg)
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    let n = SCNVector3(0, 0, 1)
    for v in 0..<hs {
        let tv0 = Float(v) / Float(hs)
        let tv1 = Float(v + 1) / Float(hs)
        for u in 0..<ws {
            let tu0 = Float(u) / Float(ws)
            let tu1 = Float(u + 1) / Float(ws)
            let p00 = SCNVector3(-hx + width * tu0, -hy + height * tv0, 0)
            let p10 = SCNVector3(-hx + width * tu1, -hy + height * tv0, 0)
            let p11 = SCNVector3(-hx + width * tu1, -hy + height * tv1, 0)
            let p01 = SCNVector3(-hx + width * tu0, -hy + height * tv1, 0)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p10, p11, n, n, n,
                             CGPoint(x: CGFloat(tu0), y: CGFloat(tv0)),
                             CGPoint(x: CGFloat(tu1), y: CGFloat(tv0)),
                             CGPoint(x: CGFloat(tu1), y: CGFloat(tv1)))
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p11, p01, n, n, n,
                             CGPoint(x: CGFloat(tu0), y: CGFloat(tv0)),
                             CGPoint(x: CGFloat(tu1), y: CGFloat(tv1)),
                             CGPoint(x: CGFloat(tu0), y: CGFloat(tv1)))
        }
    }
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnSphereMesh(radius: Float, segments: Int, geodesic: Bool) -> _SCNMesh {
    _ = geodesic
    let seg = max(3, segments)
    let rings = seg
    let sectors = seg * 2
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    func point(_ r: Int, _ s: Int) -> (SCNVector3, CGPoint) {
        let v = Float(r) / Float(rings)
        let u = Float(s) / Float(sectors)
        let theta = v * Float.pi
        let phi = u * Float.pi * 2
        let x = radius * sin(theta) * cos(phi)
        let y = radius * cos(theta)
        let z = radius * sin(theta) * sin(phi)
        return (SCNVector3(x, y, z), CGPoint(x: CGFloat(u), y: CGFloat(v)))
    }
    for r in 0..<rings {
        for s in 0..<sectors {
            let a = point(r, s)
            let b = point(r, s + 1)
            let c = point(r + 1, s + 1)
            let d = point(r + 1, s)
            let na = _scnNormalize(a.0)
            let nb = _scnNormalize(b.0)
            let nc = _scnNormalize(c.0)
            let nd = _scnNormalize(d.0)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, a.0, b.0, c.0, na, nb, nc, a.1, b.1, c.1)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, a.0, c.0, d.0, na, nc, nd, a.1, c.1, d.1)
        }
    }
    let r = radius
    return _SCNMesh(
        vertices: vertices, normals: normals, uvs: uvs, indices: indices,
        min: SCNVector3(-r, -r, -r), max: SCNVector3(r, r, r)
    )
}

func _scnCylinderMesh(radius: Float, height: Float, radial: Int, heightSeg: Int, top: Bool, bottom: Bool) -> _SCNMesh {
    let radialN = max(3, radial)
    let hSeg = max(1, heightSeg)
    let hy = height * 0.5
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    for y in 0..<hSeg {
        let t0 = Float(y) / Float(hSeg)
        let t1 = Float(y + 1) / Float(hSeg)
        let y0 = -hy + height * t0
        let y1 = -hy + height * t1
        for i in 0..<radialN {
            let a0 = Float(i) / Float(radialN) * Float.pi * 2
            let a1 = Float(i + 1) / Float(radialN) * Float.pi * 2
            let n0 = SCNVector3(cos(a0), 0, sin(a0))
            let n1 = SCNVector3(cos(a1), 0, sin(a1))
            let p00 = SCNVector3(n0.x * radius, y0, n0.z * radius)
            let p10 = SCNVector3(n1.x * radius, y0, n1.z * radius)
            let p11 = SCNVector3(n1.x * radius, y1, n1.z * radius)
            let p01 = SCNVector3(n0.x * radius, y1, n0.z * radius)
            let u0 = CGFloat(i) / CGFloat(radialN)
            let u1 = CGFloat(i + 1) / CGFloat(radialN)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p10, p11, n0, n1, n1,
                             CGPoint(x: u0, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t1)))
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p11, p01, n0, n1, n0,
                             CGPoint(x: u0, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t1)), CGPoint(x: u0, y: CGFloat(t1)))
        }
    }
    func cap(_ y: Float, _ n: SCNVector3) {
        let center = SCNVector3(0, y, 0)
        for i in 0..<radialN {
            let a0 = Float(i) / Float(radialN) * Float.pi * 2
            let a1 = Float(i + 1) / Float(radialN) * Float.pi * 2
            let p0 = SCNVector3(cos(a0) * radius, y, sin(a0) * radius)
            let p1 = SCNVector3(cos(a1) * radius, y, sin(a1) * radius)
            if n.y > 0 {
                _scnPushTriangle(&vertices, &normals, &uvs, &indices, center, p0, p1, n, n, n,
                                 CGPoint(x: 0.5, y: 0.5),
                                 CGPoint(x: CGFloat(cos(a0)) * 0.5 + 0.5, y: CGFloat(sin(a0)) * 0.5 + 0.5),
                                 CGPoint(x: CGFloat(cos(a1)) * 0.5 + 0.5, y: CGFloat(sin(a1)) * 0.5 + 0.5))
            } else {
                _scnPushTriangle(&vertices, &normals, &uvs, &indices, center, p1, p0, n, n, n,
                                 CGPoint(x: 0.5, y: 0.5),
                                 CGPoint(x: CGFloat(cos(a1)) * 0.5 + 0.5, y: CGFloat(sin(a1)) * 0.5 + 0.5),
                                 CGPoint(x: CGFloat(cos(a0)) * 0.5 + 0.5, y: CGFloat(sin(a0)) * 0.5 + 0.5))
            }
        }
    }
    if top { cap(hy, SCNVector3(0, 1, 0)) }
    if bottom { cap(-hy, SCNVector3(0, -1, 0)) }
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnConeMesh(topRadius: Float, bottomRadius: Float, height: Float, radial: Int, heightSeg: Int) -> _SCNMesh {
    let radialN = max(3, radial)
    let hSeg = max(1, heightSeg)
    let hy = height * 0.5
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    for y in 0..<hSeg {
        let t0 = Float(y) / Float(hSeg)
        let t1 = Float(y + 1) / Float(hSeg)
        let r0 = bottomRadius + (topRadius - bottomRadius) * t0
        let r1 = bottomRadius + (topRadius - bottomRadius) * t1
        let y0 = -hy + height * t0
        let y1 = -hy + height * t1
        for i in 0..<radialN {
            let a0 = Float(i) / Float(radialN) * Float.pi * 2
            let a1 = Float(i + 1) / Float(radialN) * Float.pi * 2
            let p00 = SCNVector3(cos(a0) * r0, y0, sin(a0) * r0)
            let p10 = SCNVector3(cos(a1) * r0, y0, sin(a1) * r0)
            let p11 = SCNVector3(cos(a1) * r1, y1, sin(a1) * r1)
            let p01 = SCNVector3(cos(a0) * r1, y1, sin(a0) * r1)
            let n0 = _scnNormalize(_scnCross(_scnSub(p10, p00), _scnSub(p01, p00)))
            let n1 = n0
            let u0 = CGFloat(i) / CGFloat(radialN)
            let u1 = CGFloat(i + 1) / CGFloat(radialN)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p10, p11, n0, n1, n1,
                             CGPoint(x: u0, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t1)))
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, p00, p11, p01, n0, n1, n0,
                             CGPoint(x: u0, y: CGFloat(t0)), CGPoint(x: u1, y: CGFloat(t1)), CGPoint(x: u0, y: CGFloat(t1)))
        }
    }
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnTorusMesh(ringRadius: Float, pipeRadius: Float, ringSeg: Int, pipeSeg: Int) -> _SCNMesh {
    let rn = max(3, ringSeg)
    let pn = max(3, pipeSeg)
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    func vert(_ i: Int, _ j: Int) -> (SCNVector3, SCNVector3, CGPoint) {
        let u = Float(i) / Float(rn)
        let v = Float(j) / Float(pn)
        let theta = u * Float.pi * 2
        let phi = v * Float.pi * 2
        let cx = cos(theta) * ringRadius
        let cz = sin(theta) * ringRadius
        let x = (ringRadius + pipeRadius * cos(phi)) * cos(theta)
        let y = pipeRadius * sin(phi)
        let z = (ringRadius + pipeRadius * cos(phi)) * sin(theta)
        let p = SCNVector3(x, y, z)
        let center = SCNVector3(cx, 0, cz)
        return (p, _scnNormalize(_scnSub(p, center)), CGPoint(x: CGFloat(u), y: CGFloat(v)))
    }
    for i in 0..<rn {
        for j in 0..<pn {
            let a = vert(i, j)
            let b = vert(i + 1, j)
            let c = vert(i + 1, j + 1)
            let d = vert(i, j + 1)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, a.0, b.0, c.0, a.1, b.1, c.1, a.2, b.2, c.2)
            _scnPushTriangle(&vertices, &normals, &uvs, &indices, a.0, c.0, d.0, a.1, c.1, d.1, a.2, c.2, d.2)
        }
    }
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnPyramidMesh(width: Float, height: Float, length: Float) -> _SCNMesh {
    let hx = width * 0.5
    let hy = height * 0.5
    let hz = length * 0.5
    let apex = SCNVector3(0, hy, 0)
    let b0 = SCNVector3(-hx, -hy, -hz)
    let b1 = SCNVector3(hx, -hy, -hz)
    let b2 = SCNVector3(hx, -hy, hz)
    let b3 = SCNVector3(-hx, -hy, hz)
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var uvs: [CGPoint] = []
    var indices: [UInt32] = []
    func tri(_ a: SCNVector3, _ b: SCNVector3, _ c: SCNVector3) {
        let n = _scnNormalize(_scnCross(_scnSub(b, a), _scnSub(c, a)))
        _scnPushTriangle(&vertices, &normals, &uvs, &indices, a, b, c, n, n, n,
                         CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0))
    }
    tri(apex, b0, b1)
    tri(apex, b1, b2)
    tri(apex, b2, b3)
    tri(apex, b3, b0)
    let down = SCNVector3(0, -1, 0)
    _scnPushTriangle(&vertices, &normals, &uvs, &indices, b0, b2, b1, down, down, down,
                     CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 1, y: 0))
    _scnPushTriangle(&vertices, &normals, &uvs, &indices, b0, b3, b2, down, down, down,
                     CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1))
    let b = _scnBounds(vertices)
    return _SCNMesh(vertices: vertices, normals: normals, uvs: uvs, indices: indices, min: b.0, max: b.1)
}

func _scnTubeMesh(inner: Float, outer: Float, height: Float, radial: Int, heightSeg: Int) -> _SCNMesh {
    var outerMesh = _scnCylinderMesh(radius: outer, height: height, radial: radial, heightSeg: heightSeg, top: false, bottom: false)
    let innerMesh = _scnCylinderMesh(radius: inner, height: height, radial: radial, heightSeg: heightSeg, top: false, bottom: false)
    let base = UInt32(outerMesh.vertices.count)
    outerMesh.vertices.append(contentsOf: innerMesh.vertices.map { SCNVector3($0.x, $0.y, -$0.z) })
    outerMesh.normals.append(contentsOf: innerMesh.normals.map { SCNVector3(-$0.x, $0.y, -$0.z) })
    outerMesh.uvs.append(contentsOf: innerMesh.uvs)
    outerMesh.indices.append(contentsOf: innerMesh.indices.map { base + $0 })
    let hy = height * 0.5
    let radialN = max(3, radial)
    for y in [hy, -hy] {
        let n = SCNVector3(0, y > 0 ? 1 : -1, 0)
        for i in 0..<radialN {
            let a0 = Float(i) / Float(radialN) * Float.pi * 2
            let a1 = Float(i + 1) / Float(radialN) * Float.pi * 2
            let i0 = SCNVector3(cos(a0) * inner, y, sin(a0) * inner)
            let i1 = SCNVector3(cos(a1) * inner, y, sin(a1) * inner)
            let o0 = SCNVector3(cos(a0) * outer, y, sin(a0) * outer)
            let o1 = SCNVector3(cos(a1) * outer, y, sin(a1) * outer)
            if y > 0 {
                _scnPushTriangle(&outerMesh.vertices, &outerMesh.normals, &outerMesh.uvs, &outerMesh.indices, i0, o0, o1, n, n, n,
                                 .zero, .zero, .zero)
                _scnPushTriangle(&outerMesh.vertices, &outerMesh.normals, &outerMesh.uvs, &outerMesh.indices, i0, o1, i1, n, n, n,
                                 .zero, .zero, .zero)
            } else {
                _scnPushTriangle(&outerMesh.vertices, &outerMesh.normals, &outerMesh.uvs, &outerMesh.indices, i0, o1, o0, n, n, n,
                                 .zero, .zero, .zero)
                _scnPushTriangle(&outerMesh.vertices, &outerMesh.normals, &outerMesh.uvs, &outerMesh.indices, i0, i1, o1, n, n, n,
                                 .zero, .zero, .zero)
            }
        }
    }
    let b = _scnBounds(outerMesh.vertices)
    outerMesh.min = b.0
    outerMesh.max = b.1
    return outerMesh
}

func _scnCapsuleMesh(capRadius: Float, height: Float, radial: Int, heightSeg: Int, capSeg: Int) -> _SCNMesh {
    let cylinderHeight = max(0, height - 2 * capRadius)
    var mesh = _scnCylinderMesh(radius: capRadius, height: cylinderHeight, radial: radial, heightSeg: heightSeg, top: false, bottom: false)
    let spheres = _scnSphereMesh(radius: capRadius, segments: max(3, capSeg), geodesic: false)
    let hy = cylinderHeight * 0.5
    func addSphere(_ dy: Float) {
        let base = UInt32(mesh.vertices.count)
        mesh.vertices.append(contentsOf: spheres.vertices.map { SCNVector3($0.x, $0.y + dy, $0.z) })
        mesh.normals.append(contentsOf: spheres.normals)
        mesh.uvs.append(contentsOf: spheres.uvs)
        mesh.indices.append(contentsOf: spheres.indices.map { base + $0 })
    }
    addSphere(hy)
    addSphere(-hy)
    mesh.min = SCNVector3(-capRadius, -height * 0.5, -capRadius)
    mesh.max = SCNVector3(capRadius, height * 0.5, capRadius)
    return mesh
}
