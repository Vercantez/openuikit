import Foundation
import ModelIO

func testEmptyAsset() {
    let asset = MDLAsset()
    mdlCheck(asset.count == 0, "empty count")
    asset.startTime = 1
    asset.endTime = 2
    asset.frameInterval = 1 / 24
    asset.upAxis = SIMD3(0, 1, 0)
    asset.vertexDescriptor = MDLVertexDescriptor()
    let object = MDLObject()
    object.name = "solo"
    asset.add(object)
    mdlCheck(asset.count == 1, "added")
    mdlCheck(asset.object(at: 0) === object, "object(at:)")
    mdlCheck(asset[0] === object, "subscript")
    _ = asset.object(atPath: "/solo")
    _ = asset.bufferAllocator
    _ = asset.masters
    _ = asset.originals
    _ = asset.animations
    asset.loadTextures()
    asset.remove(object)
    mdlCheck(asset.count == 0, "removed")
    let allocated = MDLAsset(bufferAllocator: MDLMeshBufferDataAllocator())
    mdlCheck(allocated.count == 0, "allocator init")
}

func testPathResolver() {
    let resolver = MDLPathAssetResolver(path: "/tmp")
    mdlCheck(resolver.path == "/tmp", "path")
    mdlCheck(resolver.resolveAssetNamed("x").lastPathComponent == "x", "resolve")
}

func testBundleResolver() {
    let resolver = MDLBundleAssetResolver(bundle: "/opt")
    mdlCheck(resolver.path == "/opt", "bundle path")
    _ = resolver.canResolveAssetNamed("nope")
}

func testRelativeResolver() {
    let asset = MDLAsset()
    let resolver = MDLRelativeAssetResolver(asset: asset)
    asset.resolver = resolver
    mdlCheck(resolver.asset === asset, "asset")
    mdlCheck(asset.resolver != nil, "stored")
}

func testImportExportExtensions() {
    mdlCheck(MDLAsset.canImportFileExtension("obj"), "import obj")
    mdlCheck(MDLAsset.canExportFileExtension("stl"), "export stl")
    mdlCheck(!MDLAsset.canImportFileExtension("usd"), "no usd import")
    mdlCheck(!MDLAsset.canExportFileExtension("abc"), "no abc export")
}

func testOBJRoundTrip() {
    let directory = mdlTempDir()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let objURL = directory.appendingPathComponent("tri.obj")
    let text = """
    v 0 0 0
    v 1 0 0
    v 0 1 0
    vn 0 0 1
    vt 0 0
    vt 1 0
    vt 0 1
    f 1/1/1 2/2/1 3/3/1
    """
    try! text.write(to: objURL, atomically: true, encoding: .utf8)
    let asset = MDLAsset(url: objURL)
    mdlCheck(asset.count >= 1, "imported objects")
    mdlCheck(asset.url == objURL, "url")
    let meshes = asset.childObjects(of: MDLMesh.self)
    mdlCheck(!meshes.isEmpty, "mesh children")
    let box = asset.boundingBox
    mdlCheck(box.maxBounds.x >= box.minBounds.x, "bounds")
    _ = asset.boundingBox(atTime: 0)
    let out = directory.appendingPathComponent("out.obj")
    try! asset.export(to: out)
    mdlCheck(FileManager.default.fileExists(atPath: out.path), "exported")
    let viaURL = MDLAsset(URL: objURL)
    mdlCheck(viaURL.count >= 1, "URL: init")
    let withDesc = MDLAsset(url: objURL, vertexDescriptor: nil, bufferAllocator: nil)
    mdlCheck(withDesc.count >= 1, "triple init")
    let withDesc2 = MDLAsset(URL: objURL, vertexDescriptor: nil, bufferAllocator: nil)
    mdlCheck(withDesc2.count >= 1, "URL triple")
}

func testUSDFailClosed() {
    let directory = mdlTempDir()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let usd = directory.appendingPathComponent("scene.usd")
    try! Data().write(to: usd)
    var error: NSError?
    let asset = MDLAsset(
        url: usd,
        vertexDescriptor: nil,
        bufferAllocator: nil,
        preserveTopology: false,
        error: &error
    )
    mdlCheck(asset.count == 0, "usd not imported")
    mdlCheck(error != nil, "error populated")
    mdlCheck(error?.domain == ModelIOLinuxErrorDomain, "linux domain")
    var error2: NSError?
    let viaURL = MDLAsset(
        URL: usd,
        vertexDescriptor: nil,
        bufferAllocator: nil,
        preserveTopology: true,
        error: &error2
    )
    mdlCheck(viaURL.count == 0, "URL usd refused")
}
