import Foundation

public class MDLSubmeshTopology: NSObject {
    public var edgeCreaseCount: UInt = 0
    public var edgeCreaseIndices: (any MDLMeshBuffer)?
    public var edgeCreases: (any MDLMeshBuffer)?
    public var faceCount: UInt = 0
    public var faceTopology: (any MDLMeshBuffer)?
    public var holeCount: UInt = 0
    public var holes: (any MDLMeshBuffer)?
    public var vertexCreaseCount: UInt = 0
    public var vertexCreaseIndices: (any MDLMeshBuffer)?
    public var vertexCreases: (any MDLMeshBuffer)?

    public init(submesh: MDLSubmesh) {
        faceCount = submesh.indexCount / 3
        super.init()
    }
}

public class MDLSubmesh: NSObject, MDLNamed {
    public var name: String
    public private(set) var indexBuffer: any MDLMeshBuffer
    public private(set) var indexCount: UInt
    public private(set) var indexType: MDLIndexBitDepth
    public private(set) var geometryType: MDLGeometryType
    public var material: MDLMaterial?
    public var topology: MDLSubmeshTopology?

    public init(
        indexBuffer: any MDLMeshBuffer,
        indexCount: UInt,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType,
        material: MDLMaterial?
    ) {
        self.name = ""
        self.indexBuffer = indexBuffer
        self.indexCount = indexCount
        self.indexType = indexType
        self.geometryType = geometryType
        self.material = material
        super.init()
    }

    public convenience init(
        name: String,
        indexBuffer: any MDLMeshBuffer,
        indexCount: UInt,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType,
        material: MDLMaterial?
    ) {
        self.init(
            indexBuffer: indexBuffer,
            indexCount: indexCount,
            indexType: indexType,
            geometryType: geometryType,
            material: material
        )
        self.name = name
    }

    public convenience init(
        name: String,
        indexBuffer: any MDLMeshBuffer,
        indexCount: UInt,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType,
        material: MDLMaterial?,
        topology: MDLSubmeshTopology?
    ) {
        self.init(
            name: name,
            indexBuffer: indexBuffer,
            indexCount: indexCount,
            indexType: indexType,
            geometryType: geometryType,
            material: material
        )
        self.topology = topology
    }

    public convenience init?(
        mdlSubmesh submesh: MDLSubmesh,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType
    ) {
        let converted = submesh.indexBuffer(asIndexType: indexType)
        self.init(
            name: submesh.name,
            indexBuffer: converted,
            indexCount: submesh.indexCount,
            indexType: indexType,
            geometryType: geometryType,
            material: submesh.material,
            topology: submesh.topology
        )
    }

    public convenience init?(
        MDLSubmesh submesh: MDLSubmesh,
        indexType: MDLIndexBitDepth,
        geometryType: MDLGeometryType
    ) {
        self.init(mdlSubmesh: submesh, indexType: indexType, geometryType: geometryType)
    }

    public func indexBuffer(asIndexType indexType: MDLIndexBitDepth) -> any MDLMeshBuffer {
        if indexType == self.indexType {
            return indexBuffer
        }
        let source = mdlUnpackIndices(mdlBufferData(indexBuffer), type: self.indexType, count: Int(indexCount))
        let packed = mdlPackIndices(source, type: indexType)
        return MDLMeshBufferData(type: .index, data: packed)
    }
}

open class MDLMesh: MDLObject {
    public var allocator: any MDLMeshBufferAllocator
    public var vertexBuffers: [any MDLMeshBuffer]
    public var vertexCount: UInt
    public var vertexDescriptor: MDLVertexDescriptor
    public var submeshes: NSMutableArray?

    public var boundingBox: MDLAxisAlignedBoundingBox {
        boundingBox(atTime: 0)
    }

    public init(bufferAllocator: (any MDLMeshBufferAllocator)?) {
        self.allocator = mdlDefaultAllocator(bufferAllocator)
        self.vertexBuffers = []
        self.vertexCount = 0
        self.vertexDescriptor = MDLVertexDescriptor()
        self.submeshes = NSMutableArray()
        super.init()
    }

    public convenience init(
        vertexBuffer: any MDLMeshBuffer,
        vertexCount: UInt,
        descriptor: MDLVertexDescriptor,
        submeshes: [MDLSubmesh]
    ) {
        self.init(vertexBuffers: [vertexBuffer], vertexCount: vertexCount, descriptor: descriptor, submeshes: submeshes)
    }

    public init(
        vertexBuffers: [any MDLMeshBuffer],
        vertexCount: UInt,
        descriptor: MDLVertexDescriptor,
        submeshes: [MDLSubmesh]
    ) {
        self.allocator = vertexBuffers.first?.allocator ?? MDLMeshBufferDataAllocator()
        self.vertexBuffers = vertexBuffers
        self.vertexCount = vertexCount
        self.vertexDescriptor = MDLVertexDescriptor(vertexDescriptor: descriptor)
        self.submeshes = NSMutableArray(array: submeshes)
        super.init()
    }

    override func localBoundingBox(atTime time: TimeInterval) -> MDLAxisAlignedBoundingBox {
        let (positions, _, _, _) = mdlExtractMeshChannels(self)
        return mdlBoundsFromPositions(positions)
    }

    public func addAttribute(withName name: String, format: MDLVertexFormat) {
        let stride = modelIOVertexFormatStride(format)
        let data = Data(count: Int(vertexCount) * stride)
        addAttribute(withName: name, format: format, type: "float", data: data, stride: stride)
    }

    public func addAttribute(withName name: String, format: MDLVertexFormat, type: String, data: Data, stride: Int) {
        addAttribute(withName: name, format: format, type: type, data: data, stride: stride, time: 0)
    }

    public func addAttribute(
        withName name: String,
        format: MDLVertexFormat,
        type: String,
        data: Data,
        stride: Int,
        time: TimeInterval
    ) {
        let buffer = allocator.newBuffer(with: data, type: .vertex)
        let bufferIndex = UInt(vertexBuffers.count)
        vertexBuffers.append(buffer)
        let attribute = MDLVertexAttribute(name: name, format: format, offset: 0, bufferIndex: bufferIndex)
        attribute.time = time
        vertexDescriptor.addOrReplaceAttribute(attribute)
        while UInt(vertexDescriptor.layouts.count) <= bufferIndex {
            vertexDescriptor.layouts.add(MDLVertexBufferLayout(stride: 0))
        }
        if let layout = vertexDescriptor.layouts[Int(bufferIndex)] as? MDLVertexBufferLayout {
            layout.stride = UInt(stride)
        }
    }

    public func removeAttributeNamed(_ name: String) {
        vertexDescriptor.removeAttributeNamed(name)
    }

    public func vertexAttributeData(forAttributeNamed name: String) -> MDLVertexAttributeData? {
        guard let attribute = vertexDescriptor.attributeNamed(name) else { return nil }
        return vertexAttributeData(forAttributeNamed: name, as: attribute.format)
    }

    public func vertexAttributeData(forAttributeNamed name: String, as format: MDLVertexFormat) -> MDLVertexAttributeData? {
        guard let attribute = vertexDescriptor.attributeNamed(name) else { return nil }
        let index = Int(attribute.bufferIndex)
        guard vertexBuffers.indices.contains(index) else { return nil }
        let buffer = vertexBuffers[index]
        let map = buffer.map()
        let layout: UInt
        if index < vertexDescriptor.layouts.count,
           let bufferLayout = vertexDescriptor.layouts[index] as? MDLVertexBufferLayout {
            layout = bufferLayout.stride
        } else {
            layout = UInt(modelIOVertexFormatStride(format))
        }
        return MDLVertexAttributeData(map: map, stride: layout, format: format, bufferSize: buffer.length)
    }

    public func replaceAttributeNamed(_ name: String, with newData: MDLVertexAttributeData) {
        guard let attribute = vertexDescriptor.attributeNamed(name) else { return }
        let bytes = Data(bytes: newData.dataStart, count: Int(newData.bufferSize))
        let index = Int(attribute.bufferIndex)
        if vertexBuffers.indices.contains(index) {
            vertexBuffers[index].fill(bytes, offset: 0)
        }
        attribute.format = newData.format
    }

    public func updateAttributeNamed(_ name: String, with newData: MDLVertexAttributeData) {
        replaceAttributeNamed(name, with: newData)
    }

    public func addNormals(withAttributeNamed attributeName: String?, creaseThreshold: Float) {
        let (positions, _, uvs, indices) = mdlExtractMeshChannels(self)
        var normals = Array(repeating: SIMD3<Float>(repeating: 0), count: positions.count)
        var i = 0
        while i + 2 < indices.count {
            let ia = Int(indices[i]), ib = Int(indices[i + 1]), ic = Int(indices[i + 2])
            if ia < positions.count, ib < positions.count, ic < positions.count {
                let n = simd_cross(positions[ib] - positions[ia], positions[ic] - positions[ia])
                normals[ia] += n
                normals[ib] += n
                normals[ic] += n
            }
            i += 3
        }
        normals = normals.map { simd_length($0) > 1e-8 ? simd_normalize($0) : SIMD3<Float>(0, 1, 0) }
        _ = creaseThreshold
        let name = attributeName ?? MDLVertexAttributeNormal
        removeAttributeNamed(name)
        var data = Data()
        for n in normals {
            var v = n
            data.append(Data(bytes: &v, count: MemoryLayout<SIMD3<Float>>.size))
        }
        addAttribute(withName: name, format: .float3, type: "float", data: data, stride: MemoryLayout<SIMD3<Float>>.stride)
        _ = uvs
    }

    public func addUnwrappedTextureCoordinates(forAttributeNamed textureCoordinateAttributeName: String) {
        let (positions, _, _, _) = mdlExtractMeshChannels(self)
        var data = Data()
        for p in positions {
            var uv = SIMD2<Float>(p.x * 0.5 + 0.5, p.y * 0.5 + 0.5)
            data.append(Data(bytes: &uv, count: MemoryLayout<SIMD2<Float>>.size))
        }
        removeAttributeNamed(textureCoordinateAttributeName)
        addAttribute(
            withName: textureCoordinateAttributeName,
            format: .float2,
            type: "float",
            data: data,
            stride: MemoryLayout<SIMD2<Float>>.stride
        )
    }

    public func flipTextureCoordinates(inAttributeNamed textureCoordinateAttributeName: String) {
        var (positions, normals, uvs, indices) = mdlExtractMeshChannels(self)
        uvs = uvs.map { SIMD2($0.x, 1 - $0.y) }
        mdlReplaceMesh(self, positions: positions, normals: normals, uvs: uvs, indices: indices)
    }

    public func addOrthTanBasis(
        forTextureCoordinateAttributeNamed textureCoordinateAttributeName: String,
        normalAttributeNamed normalAttributeName: String,
        tangentAttributeNamed tangentAttributeName: String
    ) {
        addTangentBasis(
            forTextureCoordinateAttributeNamed: textureCoordinateAttributeName,
            normalAttributeNamed: normalAttributeName,
            tangentAttributeNamed: tangentAttributeName
        )
    }

    public func addTangentBasis(
        forTextureCoordinateAttributeNamed textureCoordinateAttributeName: String,
        normalAttributeNamed normalAttributeName: String,
        tangentAttributeNamed tangentAttributeName: String
    ) {
        let (positions, normals, uvs, indices) = mdlExtractMeshChannels(self)
        var tangents = Array(repeating: SIMD3<Float>(1, 0, 0), count: positions.count)
        var i = 0
        while i + 2 < indices.count {
            let ia = Int(indices[i]), ib = Int(indices[i + 1]), ic = Int(indices[i + 2])
            if ia < positions.count, ib < positions.count, ic < positions.count,
               ia < uvs.count, ib < uvs.count, ic < uvs.count {
                let e1 = positions[ib] - positions[ia]
                let e2 = positions[ic] - positions[ia]
                let du1 = uvs[ib].x - uvs[ia].x
                let dv1 = uvs[ib].y - uvs[ia].y
                let du2 = uvs[ic].x - uvs[ia].x
                let dv2 = uvs[ic].y - uvs[ia].y
                let denom = du1 * dv2 - du2 * dv1
                let t = abs(denom) < 1e-8 ? e1 : (e1 * dv2 - e2 * dv1) / denom
                tangents[ia] += t
                tangents[ib] += t
                tangents[ic] += t
            }
            i += 3
        }
        tangents = tangents.map { simd_length($0) > 1e-8 ? simd_normalize($0) : SIMD3<Float>(1, 0, 0) }
        _ = normals
        _ = normalAttributeName
        var data = Data()
        for t in tangents {
            var v = t
            data.append(Data(bytes: &v, count: MemoryLayout<SIMD3<Float>>.size))
        }
        removeAttributeNamed(tangentAttributeName)
        addAttribute(withName: tangentAttributeName, format: .float3, type: "float", data: data, stride: MemoryLayout<SIMD3<Float>>.stride)
        _ = textureCoordinateAttributeName
    }

    public func addTangentBasis(
        forTextureCoordinateAttributeNamed textureCoordinateAttributeName: String,
        tangentAttributeNamed tangentAttributeName: String,
        bitangentAttributeNamed bitangentAttributeName: String
    ) {
        addTangentBasis(
            forTextureCoordinateAttributeNamed: textureCoordinateAttributeName,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: tangentAttributeName
        )
        let (positions, normals, _, _) = mdlExtractMeshChannels(self)
        var bitangents: [SIMD3<Float>] = []
        let tangents: [SIMD3<Float>] = {
            if let data = vertexAttributeData(forAttributeNamed: tangentAttributeName) {
                return mdlReadFloat3(data, count: Int(vertexCount))
            }
            return Array(repeating: SIMD3<Float>(1, 0, 0), count: Int(vertexCount))
        }()
        for i in 0..<positions.count {
            let n = i < normals.count ? normals[i] : SIMD3<Float>(0, 1, 0)
            let t = i < tangents.count ? tangents[i] : SIMD3<Float>(1, 0, 0)
            bitangents.append(simd_cross(n, t))
        }
        var data = Data()
        for b in bitangents {
            var v = b
            data.append(Data(bytes: &v, count: MemoryLayout<SIMD3<Float>>.size))
        }
        removeAttributeNamed(bitangentAttributeName)
        addAttribute(withName: bitangentAttributeName, format: .float3, type: "float", data: data, stride: MemoryLayout<SIMD3<Float>>.stride)
    }

    public func makeVerticesUnique() {
        try? makeVerticesUniqueAndReturnError()
    }

    public func makeVerticesUniqueAndReturnError() throws {
        let (positions, normals, uvs, indices) = mdlExtractMeshChannels(self)
        var newPositions: [SIMD3<Float>] = []
        var newNormals: [SIMD3<Float>] = []
        var newUVs: [SIMD2<Float>] = []
        var newIndices: [UInt32] = []
        for index in indices {
            let i = Int(index)
            newIndices.append(UInt32(newPositions.count))
            newPositions.append(i < positions.count ? positions[i] : SIMD3<Float>())
            newNormals.append(i < normals.count ? normals[i] : SIMD3<Float>(0, 1, 0))
            newUVs.append(i < uvs.count ? uvs[i] : SIMD2<Float>())
        }
        mdlReplaceMesh(self, positions: newPositions, normals: newNormals, uvs: newUVs, indices: newIndices)
    }

    @discardableResult
    public func generateAmbientOcclusionTexture(
        withQuality bakeQuality: Float,
        attenuationFactor: Float,
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String,
        materialPropertyNamed materialPropertyName: String
    ) -> Bool {
        _ = (bakeQuality, attenuationFactor, objectsToConsider, vertexAttributeName, materialPropertyName)
        return false
    }

    @discardableResult
    public func generateAmbientOcclusionTexture(
        withSize textureSize: SIMD2<Int32>,
        raysPerSample: Int,
        attenuationFactor: Float,
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String,
        materialPropertyNamed materialPropertyName: String
    ) -> Bool {
        _ = (textureSize, raysPerSample, attenuationFactor, objectsToConsider, vertexAttributeName, materialPropertyName)
        return false
    }

    @discardableResult
    public func generateAmbientOcclusionVertexColors(
        withQuality bakeQuality: Float,
        attenuationFactor: Float,
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String
    ) -> Bool {
        _ = (bakeQuality, attenuationFactor, objectsToConsider, vertexAttributeName)
        return false
    }

    @discardableResult
    public func generateAmbientOcclusionVertexColors(
        withRaysPerSample raysPerSample: Int,
        attenuationFactor: Float,
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String
    ) -> Bool {
        _ = (raysPerSample, attenuationFactor, objectsToConsider, vertexAttributeName)
        return false
    }

    @discardableResult
    public func generateLightMapTexture(
        withQuality bakeQuality: Float,
        lightsToConsider: [MDLLight],
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String,
        materialPropertyNamed materialPropertyName: String
    ) -> Bool {
        _ = (bakeQuality, lightsToConsider, objectsToConsider, vertexAttributeName, materialPropertyName)
        return false
    }

    @discardableResult
    public func generateLightMapTexture(
        withTextureSize textureSize: SIMD2<Int32>,
        lightsToConsider: [MDLLight],
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String,
        materialPropertyNamed materialPropertyName: String
    ) -> Bool {
        _ = (textureSize, lightsToConsider, objectsToConsider, vertexAttributeName, materialPropertyName)
        return false
    }

    @discardableResult
    public func generateLightMapVertexColorsWithLights(
        toConsider lightsToConsider: [MDLLight],
        objectsToConsider: [MDLObject],
        vertexAttributeNamed vertexAttributeName: String
    ) -> Bool {
        _ = (lightsToConsider, objectsToConsider, vertexAttributeName)
        return false
    }

    public convenience init(
        boxWithExtent extent: SIMD3<Float>,
        segments: SIMD3<UInt32>,
        inwardNormals: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildBox(extent: extent, segments: segments, inwardNormals: inwardNormals, geometryType: geometryType)
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "box"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "box"
    }

    public convenience init(
        planeWithExtent extent: SIMD3<Float>,
        segments: SIMD2<UInt32>,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildPlane(extent: extent, segments: segments)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "plane"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "plane"
    }

    public convenience init(
        sphereWithExtent extent: SIMD3<Float>,
        segments: SIMD2<UInt32>,
        inwardNormals: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildSphere(radii: extent, segments: segments, hemisphere: false, inwardNormals: inwardNormals)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "sphere"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "sphere"
    }

    public convenience init(
        hemisphereWithExtent extent: SIMD3<Float>,
        segments: SIMD2<UInt32>,
        inwardNormals: Bool,
        cap: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildSphere(radii: extent, segments: segments, hemisphere: true, inwardNormals: inwardNormals)
        _ = (cap, geometryType)
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "hemisphere"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "hemisphere"
    }

    public convenience init(
        cylinderWithExtent extent: SIMD3<Float>,
        segments: SIMD2<UInt32>,
        inwardNormals: Bool,
        topCap: Bool,
        bottomCap: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildCylinder(extent: extent, segments: segments, inwardNormals: inwardNormals, topCap: topCap, bottomCap: bottomCap, cone: false)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "cylinder"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "cylinder"
    }

    public convenience init(
        coneWithExtent extent: SIMD3<Float>,
        segments: SIMD2<UInt32>,
        inwardNormals: Bool,
        cap: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildCylinder(extent: extent, segments: segments, inwardNormals: inwardNormals, topCap: false, bottomCap: cap, cone: true)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "cone"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "cone"
    }

    public convenience init(
        capsuleWithExtent extent: SIMD3<Float>,
        cylinderSegments segments: SIMD2<UInt32>,
        hemisphereSegments: Int32,
        inwardNormals: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildCapsule(extent: extent, segments: segments, hemisphereSegments: max(Int(hemisphereSegments), 1), inwardNormals: inwardNormals)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "capsule"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "capsule"
    }

    public convenience init(
        icosahedronWithExtent extent: SIMD3<Float>,
        inwardNormals: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        let built = mdlBuildIcosahedron(extent: extent, inwardNormals: inwardNormals)
        _ = geometryType
        let mesh = mdlMeshFromInterleaved(
            positions: built.positions,
            normals: built.normals,
            uvs: built.uvs,
            indices: built.indices,
            allocator: mdlDefaultAllocator(allocator),
            name: "icosahedron"
        )
        self.init(
            vertexBuffers: mesh.vertexBuffers,
            vertexCount: mesh.vertexCount,
            descriptor: mesh.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(mesh)
        )
        self.name = "icosahedron"
    }

    public convenience init(
        meshBySubdividingMesh mesh: MDLMesh,
        submeshIndex: Int32,
        subdivisionLevels: UInt32,
        allocator: (any MDLMeshBufferAllocator)?
    ) {
        var (positions, normals, uvs, indices) = mdlExtractMeshChannels(mesh)
        var level = subdivisionLevels
        while level > 0 {
            (positions, normals, uvs, indices) = mdlSubdivideOnce(positions, normals, uvs, indices)
            level -= 1
        }
        _ = submeshIndex
        let built = mdlMeshFromInterleaved(
            positions: positions,
            normals: normals,
            uvs: uvs,
            indices: indices,
            allocator: mdlDefaultAllocator(allocator ?? mesh.allocator),
            name: mesh.name
        )
        self.init(
            vertexBuffers: built.vertexBuffers,
            vertexCount: built.vertexCount,
            descriptor: built.vertexDescriptor,
            submeshes: mdlCopiedSubmeshes(built)
        )
        self.name = mesh.name
    }

    public class func newBox(
        withDimensions dimensions: SIMD3<Float>,
        segments: SIMD3<UInt32>,
        geometryType: MDLGeometryType,
        inwardNormals: Bool,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(boxWithExtent: dimensions, segments: segments, inwardNormals: inwardNormals, geometryType: geometryType, allocator: allocator) as! Self
    }

    public class func newPlane(
        withDimensions dimensions: SIMD2<Float>,
        segments: SIMD2<UInt32>,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(
            planeWithExtent: SIMD3(dimensions.x, 0, dimensions.y),
            segments: segments,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newEllipsoid(
        withRadii radii: SIMD3<Float>,
        radialSegments: UInt,
        verticalSegments: UInt,
        geometryType: MDLGeometryType,
        inwardNormals: Bool,
        hemisphere: Bool,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        if hemisphere {
            return MDLMesh(
                hemisphereWithExtent: radii * 2,
                segments: SIMD2(UInt32(radialSegments), UInt32(verticalSegments)),
                inwardNormals: inwardNormals,
                cap: true,
                geometryType: geometryType,
                allocator: allocator
            ) as! Self
        }
        return MDLMesh(
            sphereWithExtent: radii * 2,
            segments: SIMD2(UInt32(radialSegments), UInt32(verticalSegments)),
            inwardNormals: inwardNormals,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newCylinder(
        withHeight height: Float,
        radii: SIMD2<Float>,
        radialSegments: UInt,
        verticalSegments: UInt,
        geometryType: MDLGeometryType,
        inwardNormals: Bool,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(
            cylinderWithExtent: SIMD3(radii.x * 2, height, radii.y * 2),
            segments: SIMD2(UInt32(radialSegments), UInt32(verticalSegments)),
            inwardNormals: inwardNormals,
            topCap: true,
            bottomCap: true,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newEllipticalCone(
        withHeight height: Float,
        radii: SIMD2<Float>,
        radialSegments: UInt,
        verticalSegments: UInt,
        geometryType: MDLGeometryType,
        inwardNormals: Bool,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(
            coneWithExtent: SIMD3(radii.x * 2, height, radii.y * 2),
            segments: SIMD2(UInt32(radialSegments), UInt32(verticalSegments)),
            inwardNormals: inwardNormals,
            cap: true,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newCapsule(
        withHeight height: Float,
        radii: SIMD2<Float>,
        radialSegments: UInt,
        verticalSegments: UInt,
        hemisphereSegments: UInt,
        geometryType: MDLGeometryType,
        inwardNormals: Bool,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(
            capsuleWithExtent: SIMD3(radii.x * 2, height, radii.y * 2),
            cylinderSegments: SIMD2(UInt32(radialSegments), UInt32(verticalSegments)),
            hemisphereSegments: Int32(hemisphereSegments),
            inwardNormals: inwardNormals,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newIcosahedron(withRadius radius: Float, inwardNormals: Bool, allocator: (any MDLMeshBufferAllocator)?) -> Self {
        MDLMesh(
            icosahedronWithExtent: SIMD3(repeating: radius * 2),
            inwardNormals: inwardNormals,
            geometryType: .triangles,
            allocator: allocator
        ) as! Self
    }

    public class func newIcosahedron(
        withRadius radius: Float,
        inwardNormals: Bool,
        geometryType: MDLGeometryType,
        allocator: (any MDLMeshBufferAllocator)?
    ) -> Self {
        MDLMesh(
            icosahedronWithExtent: SIMD3(repeating: radius * 2),
            inwardNormals: inwardNormals,
            geometryType: geometryType,
            allocator: allocator
        ) as! Self
    }

    public class func newSubdividedMesh(_ mesh: MDLMesh, submeshIndex: UInt, subdivisionLevels: UInt) -> Self? {
        return Optional(
            MDLMesh(
                meshBySubdividingMesh: mesh,
                submeshIndex: Int32(submeshIndex),
                subdivisionLevels: UInt32(subdivisionLevels),
                allocator: mesh.allocator
            ) as! Self
        )
    }
}
