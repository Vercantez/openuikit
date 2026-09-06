import Foundation
@_spi(OpenUIKitHost) import TranslationUIProvider

private struct ProbeView: View {
    var body: EmptyView { EmptyView() }
}

func testTranslationUIProviderSelectedTextSceneType() {
    let scene = TranslationUIProviderSelectedTextScene<ProbeView> { _ in ProbeView() }
    precondition(type(of: scene) == TranslationUIProviderSelectedTextScene<ProbeView>.self)
    let asScene: any TranslationUIProviderExtensionScene = scene
    _ = asScene
}

func testTranslationUIProviderSelectedTextSceneBodyTypealias() {
    precondition(
        TranslationUIProviderSelectedTextScene<ProbeView>.Body.self
            == TranslationUIProviderHostExtensionScene.self
    )
}

func testTranslationUIProviderSelectedTextSceneInit() {
    var received: (any TranslationUIProviderContext)?
    let scene = TranslationUIProviderSelectedTextScene<ProbeView> { context in
        received = context
        return ProbeView()
    }
    let context = TranslationUIProviderHostContext(
        inputText: AttributedString("selected"),
        allowsReplacement: true
    )
    let rendered = scene.hostRenderContent(context: context)
    precondition(type(of: rendered) == ProbeView.self)
    let receivedHost = received as? TranslationUIProviderHostContext
    precondition(receivedHost === context)
}

func testTranslationUIProviderSelectedTextSceneBody() {
    let scene = TranslationUIProviderSelectedTextScene<ProbeView> { _ in ProbeView() }
    let body = scene.body
    precondition(type(of: body) == TranslationUIProviderHostExtensionScene.self)
}
