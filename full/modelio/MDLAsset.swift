import Foundation

public class MDLPathAssetResolver: NSObject, MDLAssetResolver {
    public var path: String

    public init(path: String) {
        self.path = path
        super.init()
    }

    public func canResolveAssetNamed(_ name: String) -> Bool {
        let url = resolveAssetNamed(name)
        return FileManager.default.fileExists(atPath: url.path)
    }

    public func resolveAssetNamed(_ name: String) -> URL {
        if name.hasPrefix("/") {
            return URL(fileURLWithPath: name)
        }
        return URL(fileURLWithPath: path).appendingPathComponent(name)
    }
}

public class MDLBundleAssetResolver: NSObject, MDLAssetResolver {
    public var path: String

    public init(bundle path: String) {
        self.path = path
        super.init()
    }

    public func canResolveAssetNamed(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: resolveAssetNamed(name).path)
    }

    public func resolveAssetNamed(_ name: String) -> URL {
        URL(fileURLWithPath: path).appendingPathComponent(name)
    }
}

public class MDLRelativeAssetResolver: NSObject, MDLAssetResolver {
    public weak var asset: MDLAsset?

    public init(asset: MDLAsset) {
        self.asset = asset
        super.init()
    }

    public func canResolveAssetNamed(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: resolveAssetNamed(name).path)
    }

    public func resolveAssetNamed(_ name: String) -> URL {
        if let base = asset?.url {
            return base.deletingLastPathComponent().appendingPathComponent(name)
        }
        return URL(fileURLWithPath: name)
    }
}

public class MDLAsset: NSObject, NSCopying {
    private var objects: [MDLObject] = []
    public private(set) var url: URL?
    public private(set) var bufferAllocator: any MDLMeshBufferAllocator
    public var vertexDescriptor: MDLVertexDescriptor?
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    public var frameInterval: TimeInterval = 1.0 / 30.0
    public var upAxis: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    public var resolver: (any MDLAssetResolver)?
    public var masters: any MDLObjectContainerComponent = MDLObjectContainer()
    public var originals: any MDLObjectContainerComponent = MDLObjectContainer()
    public var animations: any MDLObjectContainerComponent = MDLObjectContainer()

    public var count: UInt { UInt(objects.count) }

    public var boundingBox: MDLAxisAlignedBoundingBox {
        boundingBox(atTime: startTime)
    }

    public func boundingBox(atTime time: TimeInterval) -> MDLAxisAlignedBoundingBox {
        objects.reduce(MDLAxisAlignedBoundingBox()) { MDLAxisAlignedBoundingBox.union($0, $1.boundingBox(atTime: time)) }
    }

    public init(bufferAllocator: (any MDLMeshBufferAllocator)?) {
        self.bufferAllocator = mdlDefaultAllocator(bufferAllocator)
        super.init()
    }

    public convenience override init() {
        self.init(bufferAllocator: nil)
    }

    public convenience init(url URL: URL) {
        self.init(url: URL, vertexDescriptor: nil, bufferAllocator: nil)
    }

    public convenience init(URL: URL) {
        self.init(url: URL)
    }

    public convenience init(
        url URL: URL?,
        vertexDescriptor: MDLVertexDescriptor?,
        bufferAllocator: (any MDLMeshBufferAllocator)?
    ) {
        self.init(bufferAllocator: bufferAllocator)
        self.vertexDescriptor = vertexDescriptor
        self.url = URL
        if let URL {
            _ = MDLAsset.importInto(self, url: URL, preserveTopology: false, error: nil)
        }
    }

    public convenience init(
        URL: URL?,
        vertexDescriptor: MDLVertexDescriptor?,
        bufferAllocator: (any MDLMeshBufferAllocator)?
    ) {
        self.init(url: URL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
    }

    public init(
        url URL: URL,
        vertexDescriptor: MDLVertexDescriptor?,
        bufferAllocator: (any MDLMeshBufferAllocator)?,
        preserveTopology: Bool,
        error: UnsafeMutablePointer<NSError?>?
    ) {
        self.bufferAllocator = mdlDefaultAllocator(bufferAllocator)
        self.vertexDescriptor = vertexDescriptor
        self.url = URL
        super.init()
        _ = MDLAsset.importInto(self, url: URL, preserveTopology: preserveTopology, error: error)
    }

    public convenience init(
        URL: URL,
        vertexDescriptor: MDLVertexDescriptor?,
        bufferAllocator: (any MDLMeshBufferAllocator)?,
        preserveTopology: Bool,
        error: UnsafeMutablePointer<NSError?>?
    ) {
        self.init(
            url: URL,
            vertexDescriptor: vertexDescriptor,
            bufferAllocator: bufferAllocator,
            preserveTopology: preserveTopology,
            error: error
        )
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLAsset(bufferAllocator: bufferAllocator)
        clone.vertexDescriptor = vertexDescriptor
        clone.url = url
        clone.startTime = startTime
        clone.endTime = endTime
        clone.frameInterval = frameInterval
        clone.upAxis = upAxis
        for object in objects {
            clone.add(object)
        }
        return clone
    }

    public func add(_ object: MDLObject) {
        if !objects.contains(where: { $0 === object }) {
            objects.append(object)
        }
    }

    public func remove(_ object: MDLObject) {
        objects.removeAll { $0 === object }
    }

    public func object(at index: UInt) -> MDLObject {
        objects[Int(index)]
    }

    public subscript(index: UInt) -> MDLObject? {
        guard index < count else { return nil }
        return objects[Int(index)]
    }

    public func object(atPath path: String) -> MDLObject {
        if objects.isEmpty {
            return MDLObject()
        }
        if path == "/" || path.isEmpty {
            return objects[0]
        }
        for object in objects {
            let found = object.atPath(path)
            if found !== object || path.hasSuffix(object.name) {
                return found
            }
        }
        return objects[0].atPath(path)
    }

    public func childObjects(of objectClass: AnyClass) -> [MDLObject] {
        var result: [MDLObject] = []
        var stop = ObjCBool(false)
        for object in objects {
            object.enumerateChildObjects(of: objectClass, root: object, using: { child, _ in
                result.append(child)
            }, stopPointer: &stop)
            if object.isKind(of: objectClass) {
                result.insert(object, at: 0)
            }
        }
        return result
    }

    public func loadTextures() {
        // URL textures stay unloaded without ImageIO; resolvers still record names.
    }

    public class func canImportFileExtension(_ extension: String) -> Bool {
        ["obj", "stl"].contains(`extension`.lowercased())
    }

    public class func canExportFileExtension(_ extension: String) -> Bool {
        ["obj", "stl"].contains(`extension`.lowercased())
    }

    public func export(to URL: URL) throws {
        let ext = URL.pathExtension.lowercased()
        guard MDLAsset.canExportFileExtension(ext) else {
            throw ModelIOLinuxError.exportFailed(ext)
        }
        let meshes = childObjects(of: MDLMesh.self).compactMap { $0 as? MDLMesh }
        if ext == "obj" {
            try mdlWriteOBJ(meshes, to: URL)
        } else {
            try mdlWriteSTL(meshes, to: URL)
        }
    }

    public class func placeLightProbes(
        withDensity value: Float,
        heuristic type: MDLProbePlacement,
        using dataSource: any MDLLightProbeIrradianceDataSource
    ) -> [MDLLightProbe] {
        let box = dataSource.boundingBox
        let density = max(value, 1)
        var probes: [MDLLightProbe] = []
        if type == .uniformGrid {
            let steps = max(Int(density.rounded()), 1)
            for z in 0..<steps {
                for y in 0..<steps {
                    for x in 0..<steps {
                        let fx = steps == 1 ? 0.5 : Float(x) / Float(steps - 1)
                        let fy = steps == 1 ? 0.5 : Float(y) / Float(steps - 1)
                        let fz = steps == 1 ? 0.5 : Float(z) / Float(steps - 1)
                        let position = SIMD3(
                            box.minBounds.x + (box.maxBounds.x - box.minBounds.x) * fx,
                            box.minBounds.y + (box.maxBounds.y - box.minBounds.y) * fy,
                            box.minBounds.z + (box.maxBounds.z - box.minBounds.z) * fz
                        )
                        let transform = MDLTransform()
                        transform.translation = position
                        if let probe = MDLLightProbe(
                            textureSize: 1,
                            forLocation: transform,
                            lightsToConsider: [],
                            objectsToConsider: [],
                            reflectiveCubemap: nil,
                            irradianceCubemap: nil
                        ) {
                            probes.append(probe)
                        }
                    }
                }
            }
        }
        return probes
    }

    @discardableResult
    static func importInto(
        _ asset: MDLAsset,
        url: URL,
        preserveTopology: Bool,
        error: UnsafeMutablePointer<NSError?>?
    ) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ["usd", "usda", "usdc", "usdz", "abc"].contains(ext) {
            error?.pointee = modelIOLinuxError(.appleImporterRequired(ext))
            return false
        }
        if ext == "obj" {
            do {
                let mesh = try mdlReadOBJ(url: url, allocator: asset.bufferAllocator)
                asset.add(mesh)
                return true
            } catch let caught {
                error?.pointee = caught as NSError
                return false
            }
        }
        if ext == "stl" {
            do {
                let mesh = try mdlReadSTL(url: url, allocator: asset.bufferAllocator)
                asset.add(mesh)
                return true
            } catch let caught {
                error?.pointee = caught as NSError
                return false
            }
        }
        error?.pointee = modelIOLinuxError(.unsupportedFileExtension(ext))
        return false
    }
}

func mdlReadOBJ(url: URL, allocator: any MDLMeshBufferAllocator) throws -> MDLMesh {
    let text = try String(contentsOf: url, encoding: .utf8)
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var uvs: [SIMD2<Float>] = []
    var outPositions: [SIMD3<Float>] = []
    var outNormals: [SIMD3<Float>] = []
    var outUVs: [SIMD2<Float>] = []
    var indices: [UInt32] = []

    func parseIndex(_ token: String, count: Int) -> Int {
        let value = Int(token.split(separator: "/").first ?? Substring(token)) ?? 0
        if value < 0 { return count + value }
        return max(value - 1, 0)
    }

    for rawLine in text.split(whereSeparator: \.isNewline) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty || line.hasPrefix("#") { continue }
        let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let head = parts.first else { continue }
        switch head {
        case "v" where parts.count >= 4:
            positions.append(SIMD3(Float(parts[1]) ?? 0, Float(parts[2]) ?? 0, Float(parts[3]) ?? 0))
        case "vn" where parts.count >= 4:
            normals.append(SIMD3(Float(parts[1]) ?? 0, Float(parts[2]) ?? 0, Float(parts[3]) ?? 0))
        case "vt" where parts.count >= 3:
            uvs.append(SIMD2(Float(parts[1]) ?? 0, Float(parts[2]) ?? 0))
        case "f":
            let verts = Array(parts.dropFirst())
            guard verts.count >= 3 else { continue }
            func emit(_ token: String) {
                let chunks = token.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
                let pi = parseIndex(chunks[0], count: positions.count)
                outPositions.append(positions.indices.contains(pi) ? positions[pi] : SIMD3<Float>(repeating: 0))
                if chunks.count > 1, !chunks[1].isEmpty {
                    let ti = parseIndex(chunks[1], count: uvs.count)
                    outUVs.append(uvs.indices.contains(ti) ? uvs[ti] : SIMD2<Float>(repeating: 0))
                } else {
                    outUVs.append(SIMD2<Float>(repeating: 0))
                }
                if chunks.count > 2, !chunks[2].isEmpty {
                    let ni = parseIndex(chunks[2], count: normals.count)
                    outNormals.append(normals.indices.contains(ni) ? normals[ni] : SIMD3<Float>(0, 1, 0))
                } else {
                    outNormals.append(SIMD3<Float>(0, 1, 0))
                }
                indices.append(UInt32(outPositions.count - 1))
            }
            emit(verts[0])
            for i in 1..<(verts.count - 1) {
                if i > 1 {
                    emit(verts[0])
                }
                emit(verts[i])
                emit(verts[i + 1])
            }
        default:
            continue
        }
    }
    return mdlMeshFromInterleaved(
        positions: outPositions,
        normals: outNormals,
        uvs: outUVs,
        indices: indices,
        allocator: allocator,
        name: url.deletingPathExtension().lastPathComponent
    )
}

func mdlReadSTL(url: URL, allocator: any MDLMeshBufferAllocator) throws -> MDLMesh {
    let data = try Data(contentsOf: url)
    if let text = String(data: data, encoding: .utf8), text.lowercased().contains("solid") {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var currentNormal = SIMD3<Float>(0, 1, 0)
        for raw in text.split(whereSeparator: \.isNewline) {
            let parts = raw.split(whereSeparator: \.isWhitespace).map(String.init)
            if parts.first == "facet", parts.count >= 5 {
                currentNormal = SIMD3(Float(parts[2]) ?? 0, Float(parts[3]) ?? 0, Float(parts[4]) ?? 0)
            } else if parts.first == "vertex", parts.count >= 4 {
                positions.append(SIMD3(Float(parts[1]) ?? 0, Float(parts[2]) ?? 0, Float(parts[3]) ?? 0))
                normals.append(currentNormal)
            }
        }
        let indices = (0..<UInt32(positions.count)).map { $0 }
        return mdlMeshFromInterleaved(
            positions: positions,
            normals: normals,
            uvs: Array(repeating: SIMD2<Float>(repeating: 0), count: positions.count),
            indices: indices,
            allocator: allocator,
            name: url.deletingPathExtension().lastPathComponent
        )
    }
    throw ModelIOLinuxError.unsupportedFileExtension("stl")
}

func mdlWriteOBJ(_ meshes: [MDLMesh], to url: URL) throws {
    var output = "# OpenUIKit ModelIO Linux OBJ\n"
    var vertexBase = 1
    for mesh in meshes {
        let (positions, normals, uvs, indices) = mdlExtractMeshChannels(mesh)
        for p in positions {
            output += "v \(p.x) \(p.y) \(p.z)\n"
        }
        for n in normals {
            output += "vn \(n.x) \(n.y) \(n.z)\n"
        }
        for t in uvs {
            output += "vt \(t.x) \(t.y)\n"
        }
        var i = 0
        while i + 2 < indices.count {
            let a = Int(indices[i]) + vertexBase
            let b = Int(indices[i + 1]) + vertexBase
            let c = Int(indices[i + 2]) + vertexBase
            output += "f \(a)/\(a)/\(a) \(b)/\(b)/\(b) \(c)/\(c)/\(c)\n"
            i += 3
        }
        vertexBase += positions.count
    }
    try output.write(to: url, atomically: true, encoding: .utf8)
}

func mdlWriteSTL(_ meshes: [MDLMesh], to url: URL) throws {
    var output = "solid modelio\n"
    for mesh in meshes {
        let (positions, normals, _, indices) = mdlExtractMeshChannels(mesh)
        var i = 0
        while i + 2 < indices.count {
            let ia = Int(indices[i]), ib = Int(indices[i + 1]), ic = Int(indices[i + 2])
            let n = ia < normals.count ? normals[ia] : SIMD3<Float>(0, 1, 0)
            let a = ia < positions.count ? positions[ia] : SIMD3<Float>()
            let b = ib < positions.count ? positions[ib] : SIMD3<Float>()
            let c = ic < positions.count ? positions[ic] : SIMD3<Float>()
            output += "  facet normal \(n.x) \(n.y) \(n.z)\n    outer loop\n"
            output += "      vertex \(a.x) \(a.y) \(a.z)\n"
            output += "      vertex \(b.x) \(b.y) \(b.z)\n"
            output += "      vertex \(c.x) \(c.y) \(c.z)\n"
            output += "    endloop\n  endfacet\n"
            i += 3
        }
    }
    output += "endsolid modelio\n"
    try output.write(to: url, atomically: true, encoding: .utf8)
}
