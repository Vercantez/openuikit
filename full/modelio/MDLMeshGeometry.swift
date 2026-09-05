import Foundation

struct MDLBuiltMesh {
    var positions: [SIMD3<Float>]
    var normals: [SIMD3<Float>]
    var uvs: [SIMD2<Float>]
    var indices: [UInt32]
}

func mdlCopiedSubmeshes(_ mesh: MDLMesh) -> [MDLSubmesh] {
    (mesh.submeshes as NSArray?)?.compactMap { $0 as? MDLSubmesh } ?? []
}

func mdlMeshFromInterleaved(
    positions: [SIMD3<Float>],
    normals: [SIMD3<Float>],
    uvs: [SIMD2<Float>],
    indices: [UInt32],
    allocator: any MDLMeshBufferAllocator,
    name: String
) -> MDLMesh {
    var positionData = Data()
    var normalData = Data()
    var uvData = Data()
    for p in positions {
        var v = p
        positionData.append(Data(bytes: &v, count: 12))
    }
    for n in normals {
        var v = n
        normalData.append(Data(bytes: &v, count: 12))
    }
    for t in uvs {
        var v = t
        uvData.append(Data(bytes: &v, count: 8))
    }
    let positionBuffer = allocator.newBuffer(with: positionData, type: .vertex)
    let normalBuffer = allocator.newBuffer(with: normalData, type: .vertex)
    let uvBuffer = allocator.newBuffer(with: uvData, type: .vertex)
    let descriptor = MDLVertexDescriptor()
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
    )
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 1)
    )
    descriptor.addOrReplaceAttribute(
        MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: 2)
    )
    descriptor.layouts.add(MDLVertexBufferLayout(stride: 12))
    descriptor.layouts.add(MDLVertexBufferLayout(stride: 12))
    descriptor.layouts.add(MDLVertexBufferLayout(stride: 8))
    let packed = mdlPackIndices(indices, type: .uInt32)
    let indexBuffer = allocator.newBuffer(with: packed, type: .index)
    let submesh = MDLSubmesh(
        name: name,
        indexBuffer: indexBuffer,
        indexCount: UInt(indices.count),
        indexType: .uInt32,
        geometryType: .triangles,
        material: nil
    )
    let mesh = MDLMesh(
        vertexBuffers: [positionBuffer, normalBuffer, uvBuffer],
        vertexCount: UInt(positions.count),
        descriptor: descriptor,
        submeshes: [submesh]
    )
    mesh.name = name
    mesh.allocator = allocator
    return mesh
}

func mdlExtractMeshChannels(_ mesh: MDLMesh) -> ([SIMD3<Float>], [SIMD3<Float>], [SIMD2<Float>], [UInt32]) {
    let count = Int(mesh.vertexCount)
    var positions = Array(repeating: SIMD3<Float>(), count: count)
    var normals = Array(repeating: SIMD3<Float>(0, 1, 0), count: count)
    var uvs = Array(repeating: SIMD2<Float>(), count: count)
    if let data = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition) {
        positions = mdlReadFloat3(data, count: count)
    }
    if let data = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal) {
        normals = mdlReadFloat3(data, count: count)
    }
    if let data = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate) {
        uvs = mdlReadFloat2(data, count: count)
    }
    var indices: [UInt32] = []
    if let first = mesh.submeshes?.firstObject as? MDLSubmesh {
        indices = mdlUnpackIndices(mdlBufferData(first.indexBuffer), type: first.indexType, count: Int(first.indexCount))
    }
    return (positions, normals, uvs, indices)
}

func mdlReplaceMesh(
    _ mesh: MDLMesh,
    positions: [SIMD3<Float>],
    normals: [SIMD3<Float>],
    uvs: [SIMD2<Float>],
    indices: [UInt32]
) {
    let rebuilt = mdlMeshFromInterleaved(
        positions: positions,
        normals: normals,
        uvs: uvs,
        indices: indices,
        allocator: mesh.allocator,
        name: mesh.name
    )
    mesh.vertexBuffers = rebuilt.vertexBuffers
    mesh.vertexCount = rebuilt.vertexCount
    mesh.vertexDescriptor = rebuilt.vertexDescriptor
    mesh.submeshes = rebuilt.submeshes
}

func mdlReadFloat3(_ data: MDLVertexAttributeData, count: Int) -> [SIMD3<Float>] {
    var result: [SIMD3<Float>] = []
    let stride = max(Int(data.stride), 12)
    for i in 0..<count {
        let pointer = data.dataStart.advanced(by: i * stride).assumingMemoryBound(to: Float.self)
        result.append(SIMD3(pointer[0], pointer[1], pointer[2]))
    }
    return result
}

func mdlReadFloat2(_ data: MDLVertexAttributeData, count: Int) -> [SIMD2<Float>] {
    var result: [SIMD2<Float>] = []
    let stride = max(Int(data.stride), 8)
    for i in 0..<count {
        let pointer = data.dataStart.advanced(by: i * stride).assumingMemoryBound(to: Float.self)
        result.append(SIMD2(pointer[0], pointer[1]))
    }
    return result
}

func mdlUnpackIndices(_ data: Data, type: MDLIndexBitDepth, count: Int) -> [UInt32] {
    var result: [UInt32] = []
    data.withUnsafeBytes { raw in
        switch type {
        case .uInt8:
            for i in 0..<min(count, data.count) {
                result.append(UInt32(raw[i]))
            }
        case .uInt16:
            let typed = raw.bindMemory(to: UInt16.self)
            for i in 0..<min(count, typed.count) {
                result.append(UInt32(typed[i]))
            }
        default:
            let typed = raw.bindMemory(to: UInt32.self)
            for i in 0..<min(count, typed.count) {
                result.append(typed[i])
            }
        }
    }
    return result
}

func mdlPackIndices(_ indices: [UInt32], type: MDLIndexBitDepth) -> Data {
    switch type {
    case .uInt8:
        return Data(indices.map { UInt8(clamping: $0) })
    case .uInt16:
        let values = indices.map { UInt16(clamping: $0) }
        return values.withUnsafeBufferPointer { Data(buffer: $0) }
    default:
        let values = indices
        return values.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}

func mdlBuildBox(extent: SIMD3<Float>, segments: SIMD3<UInt32>, inwardNormals: Bool, geometryType: MDLGeometryType) -> MDLBuiltMesh {
    _ = geometryType
    let hx = extent.x / 2, hy = extent.y / 2, hz = extent.z / 2
    let faces: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = [
        (SIMD3(-hx, -hy, hz), SIMD3(hx, -hy, hz), SIMD3(hx, hy, hz), SIMD3(-hx, hy, hz)),
        (SIMD3(hx, -hy, -hz), SIMD3(-hx, -hy, -hz), SIMD3(-hx, hy, -hz), SIMD3(hx, hy, -hz)),
        (SIMD3(-hx, hy, -hz), SIMD3(-hx, hy, hz), SIMD3(hx, hy, hz), SIMD3(hx, hy, -hz)),
        (SIMD3(-hx, -hy, hz), SIMD3(-hx, -hy, -hz), SIMD3(hx, -hy, -hz), SIMD3(hx, -hy, hz)),
        (SIMD3(-hx, -hy, -hz), SIMD3(-hx, -hy, hz), SIMD3(-hx, hy, hz), SIMD3(-hx, hy, -hz)),
        (SIMD3(hx, -hy, hz), SIMD3(hx, -hy, -hz), SIMD3(hx, hy, -hz), SIMD3(hx, hy, hz)),
    ]
    let faceNormals: [SIMD3<Float>] = [
        SIMD3(0, 0, 1), SIMD3(0, 0, -1), SIMD3(0, 1, 0), SIMD3(0, -1, 0), SIMD3(-1, 0, 0), SIMD3(1, 0, 0),
    ]
    var built = MDLBuiltMesh(positions: [], normals: [], uvs: [], indices: [])
    let sx = max(Int(segments.x), 1)
    let sy = max(Int(segments.y), 1)
    _ = sy
    for (faceIndex, face) in faces.enumerated() {
        let n = inwardNormals ? -faceNormals[faceIndex] : faceNormals[faceIndex]
        let base = UInt32(built.positions.count)
        let corners = [face.0, face.1, face.2, face.3]
        for (i, p) in corners.enumerated() {
            built.positions.append(p)
            built.normals.append(n)
            built.uvs.append(SIMD2(Float(i == 1 || i == 2 ? 1 : 0), Float(i >= 2 ? 1 : 0)))
        }
        let order: [UInt32] = inwardNormals ? [0, 3, 2, 0, 2, 1] : [0, 1, 2, 0, 2, 3]
        built.indices.append(contentsOf: order.map { base + $0 })
        _ = sx
    }
    return built
}

func mdlBuildPlane(extent: SIMD3<Float>, segments: SIMD2<UInt32>) -> MDLBuiltMesh {
    let w = max(Int(segments.x), 1)
    let h = max(Int(segments.y), 1)
    let hx = extent.x / 2
    let hz = (extent.z == 0 ? extent.y : extent.z) / 2
    var built = MDLBuiltMesh(positions: [], normals: [], uvs: [], indices: [])
    for y in 0...h {
        for x in 0...w {
            let u = Float(x) / Float(w)
            let v = Float(y) / Float(h)
            built.positions.append(SIMD3(-hx + u * extent.x, 0, -hz + v * hz * 2))
            built.normals.append(SIMD3(0, 1, 0))
            built.uvs.append(SIMD2(u, v))
        }
    }
    for y in 0..<h {
        for x in 0..<w {
            let i0 = UInt32(y * (w + 1) + x)
            let i1 = i0 + 1
            let i2 = i0 + UInt32(w + 1)
            let i3 = i2 + 1
            built.indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
        }
    }
    return built
}

func mdlBuildSphere(radii: SIMD3<Float>, segments: SIMD2<UInt32>, hemisphere: Bool, inwardNormals: Bool) -> MDLBuiltMesh {
    let slices = max(Int(segments.x), 3)
    let stacks = max(Int(segments.y), 2)
    let rx = radii.x / 2, ry = radii.y / 2, rz = radii.z / 2
    let vStacks = hemisphere ? stacks / 2 + 1 : stacks
    var built = MDLBuiltMesh(positions: [], normals: [], uvs: [], indices: [])
    for y in 0...vStacks {
        let v = Float(y) / Float(hemisphere ? stacks / 2 : stacks)
        let phi = v * (hemisphere ? Float.pi / 2 : Float.pi)
        let sp = sin(phi), cp = cos(phi)
        for x in 0...slices {
            let u = Float(x) / Float(slices)
            let theta = u * 2 * Float.pi
            let st = sin(theta), ct = cos(theta)
            let n = SIMD3(st * sp, cp, ct * sp)
            let p = SIMD3(n.x * rx, n.y * ry, n.z * rz)
            built.positions.append(p)
            built.normals.append(inwardNormals ? -n : n)
            built.uvs.append(SIMD2(u, v))
        }
    }
    for y in 0..<vStacks {
        for x in 0..<slices {
            let i0 = UInt32(y * (slices + 1) + x)
            let i1 = i0 + 1
            let i2 = i0 + UInt32(slices + 1)
            let i3 = i2 + 1
            if inwardNormals {
                built.indices.append(contentsOf: [i0, i1, i2, i1, i3, i2])
            } else {
                built.indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
            }
        }
    }
    return built
}

func mdlBuildCylinder(
    extent: SIMD3<Float>,
    segments: SIMD2<UInt32>,
    inwardNormals: Bool,
    topCap: Bool,
    bottomCap: Bool,
    cone: Bool
) -> MDLBuiltMesh {
    let slices = max(Int(segments.x), 3)
    let stacks = max(Int(segments.y), 1)
    let rx = extent.x / 2, rz = extent.z / 2, hy = extent.y / 2
    var built = MDLBuiltMesh(positions: [], normals: [], uvs: [], indices: [])
    for y in 0...stacks {
        let v = Float(y) / Float(stacks)
        let yy = -hy + v * extent.y
        let scale = cone ? (1 - v) : 1
        for x in 0...slices {
            let u = Float(x) / Float(slices)
            let theta = u * 2 * Float.pi
            let n = SIMD3(sin(theta), 0, cos(theta))
            built.positions.append(SIMD3(n.x * rx * scale, yy, n.z * rz * scale))
            built.normals.append(inwardNormals ? -n : n)
            built.uvs.append(SIMD2(u, v))
        }
    }
    for y in 0..<stacks {
        for x in 0..<slices {
            let i0 = UInt32(y * (slices + 1) + x)
            let i1 = i0 + 1
            let i2 = i0 + UInt32(slices + 1)
            let i3 = i2 + 1
            built.indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
        }
    }
    func cap(y: Float, normal: SIMD3<Float>) {
        let center = UInt32(built.positions.count)
        built.positions.append(SIMD3(0, y, 0))
        built.normals.append(normal)
        built.uvs.append(SIMD2(0.5, 0.5))
        for x in 0...slices {
            let u = Float(x) / Float(slices)
            let theta = u * 2 * Float.pi
            let p = SIMD3(sin(theta) * rx, y, cos(theta) * rz)
            built.positions.append(p)
            built.normals.append(normal)
            built.uvs.append(SIMD2(sin(theta) * 0.5 + 0.5, cos(theta) * 0.5 + 0.5))
            if x > 0 {
                let a = center
                let b = center + UInt32(x)
                let c = center + UInt32(x + 1)
                if normal.y > 0 {
                    built.indices.append(contentsOf: [a, b, c])
                } else {
                    built.indices.append(contentsOf: [a, c, b])
                }
            }
        }
    }
    if topCap { cap(y: hy, normal: SIMD3(0, inwardNormals ? -1 : 1, 0)) }
    if bottomCap { cap(y: -hy, normal: SIMD3(0, inwardNormals ? 1 : -1, 0)) }
    return built
}

func mdlBuildCapsule(extent: SIMD3<Float>, segments: SIMD2<UInt32>, hemisphereSegments: Int, inwardNormals: Bool) -> MDLBuiltMesh {
    let cylinder = mdlBuildCylinder(
        extent: SIMD3(extent.x, max(extent.y - extent.x, extent.x * 0.1), extent.z),
        segments: segments,
        inwardNormals: inwardNormals,
        topCap: false,
        bottomCap: false,
        cone: false
    )
    _ = hemisphereSegments
    return cylinder
}

func mdlBuildIcosahedron(extent: SIMD3<Float>, inwardNormals: Bool) -> MDLBuiltMesh {
    let t = (1 + sqrt(Float(5))) / 2
    let verts: [SIMD3<Float>] = [
        SIMD3(-1, t, 0), SIMD3(1, t, 0), SIMD3(-1, -t, 0), SIMD3(1, -t, 0),
        SIMD3(0, -1, t), SIMD3(0, 1, t), SIMD3(0, -1, -t), SIMD3(0, 1, -t),
        SIMD3(t, 0, -1), SIMD3(t, 0, 1), SIMD3(-t, 0, -1), SIMD3(-t, 0, 1),
    ].map { simd_normalize($0) * (extent / 2) }
    let faces: [[Int]] = [
        [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
        [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
        [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
        [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
    ]
    var built = MDLBuiltMesh(positions: [], normals: [], uvs: [], indices: [])
    for face in faces {
        let a = verts[face[0]], b = verts[face[1]], c = verts[face[2]]
        var n = simd_normalize(simd_cross(b - a, c - a))
        if inwardNormals { n = -n }
        let base = UInt32(built.positions.count)
        built.positions.append(contentsOf: [a, b, c])
        built.normals.append(contentsOf: [n, n, n])
        built.uvs.append(contentsOf: [SIMD2(0, 0), SIMD2(1, 0), SIMD2(0.5, 1)])
        built.indices.append(contentsOf: inwardNormals ? [base, base + 2, base + 1] : [base, base + 1, base + 2])
    }
    _ = verts
    return built
}

func mdlSubdivideOnce(
    _ positions: [SIMD3<Float>],
    _ normals: [SIMD3<Float>],
    _ uvs: [SIMD2<Float>],
    _ indices: [UInt32]
) -> ([SIMD3<Float>], [SIMD3<Float>], [SIMD2<Float>], [UInt32]) {
    var outP: [SIMD3<Float>] = []
    var outN: [SIMD3<Float>] = []
    var outT: [SIMD2<Float>] = []
    var outI: [UInt32] = []
    var i = 0
    func emit(_ index: Int) -> Int {
        let idx = outP.count
        outP.append(index < positions.count ? positions[index] : SIMD3<Float>())
        outN.append(index < normals.count ? normals[index] : SIMD3<Float>(0, 1, 0))
        outT.append(index < uvs.count ? uvs[index] : SIMD2<Float>())
        return idx
    }
    func mid(_ a: Int, _ b: Int) -> Int {
        let p = ((a < positions.count ? positions[a] : SIMD3<Float>()) + (b < positions.count ? positions[b] : SIMD3<Float>())) * 0.5
        let n = simd_normalize(((a < normals.count ? normals[a] : SIMD3<Float>(0, 1, 0)) + (b < normals.count ? normals[b] : SIMD3<Float>(0, 1, 0))) * 0.5)
        let t = ((a < uvs.count ? uvs[a] : SIMD2<Float>()) + (b < uvs.count ? uvs[b] : SIMD2<Float>())) * 0.5
        let idx = outP.count
        outP.append(p)
        outN.append(n)
        outT.append(t)
        return idx
    }
    while i + 2 < indices.count {
        let a = Int(indices[i]), b = Int(indices[i + 1]), c = Int(indices[i + 2])
        let ia = emit(a)
        let ib = emit(b)
        let ic = emit(c)
        let iab = mid(a, b)
        let ibc = mid(b, c)
        let ica = mid(c, a)
        outI.append(contentsOf: [
            UInt32(ia), UInt32(iab), UInt32(ica),
            UInt32(iab), UInt32(ib), UInt32(ibc),
            UInt32(ica), UInt32(ibc), UInt32(ic),
            UInt32(iab), UInt32(ibc), UInt32(ica),
        ])
        i += 3
    }
    return (outP, outN, outT, outI)
}
