import CoreGraphics
import Dispatch
import Foundation
import GLKit
import ModelIO
import OpenGLES
import UIKit

#if os(Linux)
import Glibc
#else
import Darwin
#endif

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func requireModuleTypeName(_ value: Any, expectedPrefix: String, label: String) {
    let name = String(reflecting: type(of: value))
    require(
        name == expectedPrefix || name.hasPrefix(expectedPrefix) || name.contains(expectedPrefix),
        "\(label) must be a \(expectedPrefix) identity, got \(name)"
    )
}

func inspectLoadedGLKitDylib() {
    var searchPaths: [String] = ["libGLKit.dylib", "./libGLKit.dylib"]
    if let raw = getenv("LD_LIBRARY_PATH") {
        let roots = String(cString: raw).split(separator: ":")
        searchPaths.append(contentsOf: roots.map { "\($0)/libGLKit.dylib" })
    }

    var loadedPath: String?
    var handle: UnsafeMutableRawPointer?
    for path in searchPaths {
        if let opened = dlopen(path, RTLD_NOW) {
            handle = opened
            loadedPath = path
            break
        }
    }
    require(handle != nil, "dlopen(libGLKit.dylib) must succeed")
    require(loadedPath != nil, "libGLKit.dylib path")
    let path = loadedPath!

    let readelfCandidates = ["/usr/bin/llvm-readelf", "/usr/bin/readelf", "/bin/readelf"]
    var neededOutput = ""
    var dynsymOutput = ""
    for tool in readelfCandidates where FileManager.default.isExecutableFile(atPath: tool) {
        let needed = Process()
        needed.executableURL = URL(fileURLWithPath: tool)
        needed.arguments = ["-d", path]
        let neededPipe = Pipe()
        needed.standardOutput = neededPipe
        needed.standardError = neededPipe
        try! needed.run()
        needed.waitUntilExit()
        neededOutput = String(data: neededPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        let dynsym = Process()
        dynsym.executableURL = URL(fileURLWithPath: tool)
        dynsym.arguments = ["-Ws", path]
        let dynsymPipe = Pipe()
        dynsym.standardOutput = dynsymPipe
        dynsym.standardError = dynsymPipe
        try! dynsym.run()
        dynsym.waitUntilExit()
        dynsymOutput = String(data: dynsymPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if !neededOutput.isEmpty || !dynsymOutput.isEmpty {
            break
        }
    }

    require(
        neededOutput.contains("NEEDED") || neededOutput.contains("Shared library"),
        "libGLKit.dylib dynamic dependencies must be readable"
    )
    let neededUpper = neededOutput.uppercased()
    require(
        neededUpper.contains("OPENGLES") || neededUpper.contains("UIKIT") || neededUpper.contains("LIBSWIFT"),
        "libGLKit.dylib NEEDED entries must include a real runtime/dependency module"
    )
    require(
        dynsymOutput.contains("GLK") || dynsymOutput.contains("GLKit"),
        "libGLKit.dylib must export GLKit symbols"
    )
}

func makeIdentityCGImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var pixels: [UInt8] = [255, 0, 0, 255]
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard
        let context = CGContext(
            data: &pixels,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ),
        let image = context.makeImage()
    else {
        fatalError("CoreGraphics must produce a real CGImage")
    }
    return image
}

func testOpenGLESIdentity() -> (EAGLContext, EAGLSharegroup) {
    let context = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2)
    require(context != nil, "OpenGLES.EAGLContext must construct a real context")
    let realContext = context!
    requireModuleTypeName(realContext, expectedPrefix: "EAGLContext", label: "EAGLContext")
    let contextType = String(reflecting: type(of: realContext))
    require(
        contextType.contains("OpenGLES") || contextType.contains("EAGLContext"),
        "EAGLContext must be the OpenGLES module type, not a GLKit lookalike: \(contextType)"
    )
    let sharegroup = realContext.sharegroup
    require(sharegroup != nil, "EAGLContext.sharegroup must be a real EAGLSharegroup")
    let realSharegroup = sharegroup!
    requireModuleTypeName(realSharegroup, expectedPrefix: "EAGLSharegroup", label: "EAGLSharegroup")
    return (realContext, realSharegroup)
}

func testTextureCallbacks(loader: GLKTextureLoader, cgImage: CGImage) {
    var callbackInvocations = 0
    var callerReturned = false
    let lock = NSLock()
    let gate = DispatchSemaphore(value: 0)
    let queue = DispatchQueue(label: "glkit.identity.texture")
    loader.texture(withContentsOf: Data([0, 1, 2, 3]), options: nil, queue: queue) { texture, error in
        dispatchPrecondition(condition: .onQueue(queue))
        lock.lock()
        let sawReturn = callerReturned
        callbackInvocations += 1
        lock.unlock()
        require(sawReturn, "texture callback must not run inline on the caller")
        let _: GLKTextureInfo? = texture
        _ = error
        gate.signal()
    }
    lock.lock()
    callerReturned = true
    let invocationsAtReturn = callbackInvocations
    lock.unlock()
    require(invocationsAtReturn == 0, "completion must not fire before texture(withContentsOf:queue:) returns")
    gate.wait()
    require(callbackInvocations == 1, "completion must run exactly once")

    var imageInvocations = 0
    var imageCallerReturned = false
    let imageGate = DispatchSemaphore(value: 0)
    let imageQueue = DispatchQueue(label: "glkit.identity.cgimage")
    loader.texture(with: cgImage, options: nil, queue: imageQueue) { texture, error in
        dispatchPrecondition(condition: .onQueue(imageQueue))
        lock.lock()
        let sawReturn = imageCallerReturned
        imageInvocations += 1
        lock.unlock()
        require(sawReturn, "CGImage texture callback must not run inline")
        let _: GLKTextureInfo? = texture
        _ = error
        imageGate.signal()
    }
    lock.lock()
    imageCallerReturned = true
    let imageAtReturn = imageInvocations
    lock.unlock()
    require(imageAtReturn == 0, "CGImage completion must not fire before return")
    imageGate.wait()
    require(imageInvocations == 1, "CGImage completion must run exactly once")
}

func testModelIOIdentity() {
    let descriptor = MDLVertexDescriptor()
    requireModuleTypeName(descriptor, expectedPrefix: "MDLVertexDescriptor", label: "MDLVertexDescriptor")
    let allocator = MDLMeshBufferDataAllocator()
    let vertexData = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    let buffer = allocator.newBuffer(with: vertexData, type: .vertex)
    requireModuleTypeName(buffer, expectedPrefix: "MDL", label: "MDLMeshBuffer")
    let mesh = MDLMesh(
        vertexBuffer: buffer,
        vertexCount: 1,
        descriptor: descriptor,
        submeshes: []
    )
    mesh.name = "identity"
    requireModuleTypeName(mesh, expectedPrefix: "MDLMesh", label: "MDLMesh")
    do {
        _ = try GLKMesh(mesh: mesh)
    } catch {
        _ = error
    }
    let asset = MDLAsset()
    asset.add(mesh)
    requireModuleTypeName(asset, expectedPrefix: "MDLAsset", label: "MDLAsset")
    do {
        _ = try GLKMesh.newMeshes(from: asset, sourceMeshes: nil)
    } catch {
        _ = error
    }
    _ = GLKVertexAttributeParametersFromModelIO(.float3)
}

func testUIKitIdentity(context: EAGLContext, cgImage: CGImage) {
    let uiImage = UIImage(cgImage: cgImage)
    requireModuleTypeName(uiImage, expectedPrefix: "UIImage", label: "UIImage")
    let uiImageType = String(reflecting: type(of: uiImage))
    require(
        uiImageType.contains("UIKit") || uiImageType.contains("UIImage"),
        "UIImage must be the UIKit module type, not a GLKit lookalike: \(uiImageType)"
    )

    MainActor.assumeIsolated {
        let view = GLKView(frame: CGRect(x: 0, y: 0, width: 64, height: 64), context: context)
        require(view is UIView, "GLKView instance must be a UIKit.UIView")
        require(GLKView.self is UIView.Type, "GLKView must inherit UIKit.UIView")
        let uiViewTypeName = String(reflecting: UIView.self)
        require(
            uiViewTypeName == "UIKit.UIView" || uiViewTypeName.hasPrefix("UIKit."),
            "UIView must be the UIKit module type, not a GLKit lookalike: \(uiViewTypeName)"
        )
        require((view.context as AnyObject) === (context as AnyObject), "GLKView must store the EAGLContext")
        view.bindDrawable()
        view.display()
        view.deleteDrawable()

        let controller = GLKViewController()
        require(controller is UIViewController, "GLKViewController instance must be a UIKit.UIViewController")
        require(GLKViewController.self is UIViewController.Type, "GLKViewController must inherit UIKit.UIViewController")
        let uiViewControllerTypeName = String(reflecting: UIViewController.self)
        require(
            uiViewControllerTypeName == "UIKit.UIViewController" || uiViewControllerTypeName.hasPrefix("UIKit."),
            "UIViewController must be the UIKit module type, not a GLKit lookalike: \(uiViewControllerTypeName)"
        )
        _ = uiImage.size
    }
}

inspectLoadedGLKitDylib()
let (context, sharegroup) = testOpenGLESIdentity()
let loader = GLKTextureLoader(sharegroup: sharegroup)
let cgImage = makeIdentityCGImage()
testTextureCallbacks(loader: loader, cgImage: cgImage)
testModelIOIdentity()
testUIKitIdentity(context: context, cgImage: cgImage)
print("GLKIT_DEPENDENCY_IDENTITY_OK")
