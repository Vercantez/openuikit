import Foundation
@_spi(OpenUIKitHost) import LockedCameraCapture

private struct ProbeLeaf: LockedCameraCaptureExtensionScene {
    typealias Body = Never
    var body: Never { fatalError("probe leaf") }
}

private struct ProbeScene: LockedCameraCaptureExtensionScene {
    var body: ProbeLeaf { ProbeLeaf() }
}

private struct ProbeExtension: LockedCameraCaptureExtension {
    var body: ProbeScene { ProbeScene() }
}

private struct ProbeView: View {
    var body: EmptyView { EmptyView() }
}

func testLockedCameraCaptureExtensionSceneProtocol() {
    let scene = ProbeScene()
    let asProtocol: any LockedCameraCaptureExtensionScene = scene
    _ = asProtocol
    let asAppScene: any AppExtensionScene = scene
    _ = asAppScene
}

func testLockedCameraCaptureExtensionProtocol() {
    let ext = ProbeExtension()
    let asProtocol: any LockedCameraCaptureExtension = ext
    _ = asProtocol
    let asApp: any AppExtension = ext
    _ = asApp
}

func testLockedCameraCaptureExtensionBodyAssociatedType() {
    precondition(ProbeExtension.Body.self == ProbeScene.self)
}

func testLockedCameraCaptureExtensionBody() {
    let ext = ProbeExtension()
    let body = ext.body
    precondition(type(of: body) == ProbeScene.self)
}

func testLockedCameraCaptureExtensionConfiguration() {
    let ext = ProbeExtension()
    let configuration = ext.configuration
    precondition(type(of: configuration) == AppExtensionSceneConfiguration.self)
    precondition(configuration.hostSceneTypeName.contains("ProbeScene"))
}

func testLockedCameraCaptureUISceneType() {
    let scene = LockedCameraCaptureUIScene<ProbeView> { _ in ProbeView() }
    precondition(type(of: scene) == LockedCameraCaptureUIScene<ProbeView>.self)
}

func testLockedCameraCaptureUISceneBodyTypealias() {
    precondition(
        LockedCameraCaptureUIScene<ProbeView>.Body.self
            == LockedCameraCaptureHostExtensionScene.self
    )
}

func testLockedCameraCaptureUISceneInit() {
    var received: LockedCameraCaptureSession?
    let scene = LockedCameraCaptureUIScene<ProbeView> { session in
        received = session
        return ProbeView()
    }
    let rendered = scene.hostRenderContent()
    precondition(type(of: rendered) == ProbeView.self)
    precondition(received === scene.session)
}

func testLockedCameraCaptureUISceneSession() {
    let scene = LockedCameraCaptureUIScene<ProbeView> { _ in ProbeView() }
    let url = scene.session.sessionContentURL
    precondition(url.isFileURL)
    var isDirectory: ObjCBool = false
    precondition(
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    )
    precondition(isDirectory.boolValue)
}

func testLockedCameraCaptureUISceneBody() {
    let scene = LockedCameraCaptureUIScene<ProbeView> { _ in ProbeView() }
    let body = scene.body
    precondition(type(of: body) == LockedCameraCaptureHostExtensionScene.self)
    precondition(body.session === scene.session)
}
