import Foundation
@_spi(OpenUIKitHost) import TranslationUIProvider

private struct ProbeLeaf: TranslationUIProviderExtensionScene {
    typealias Body = Never
    var body: Never { fatalError("probe leaf") }
}

private struct ProbeScene: TranslationUIProviderExtensionScene {
    var body: ProbeLeaf { ProbeLeaf() }
}

private struct ProbeExtension: TranslationUIProviderExtension {
    var body: ProbeScene { ProbeScene() }
}

func testTranslationUIProviderExtensionSceneProtocol() {
    let scene = ProbeScene()
    let asProtocol: any TranslationUIProviderExtensionScene = scene
    _ = asProtocol
    let asAppScene: any AppExtensionScene = scene
    _ = asAppScene
}

func testTranslationUIProviderExtensionProtocol() {
    let ext = ProbeExtension()
    let asProtocol: any TranslationUIProviderExtension = ext
    _ = asProtocol
    let asApp: any AppExtension = ext
    _ = asApp
}

func testTranslationUIProviderExtensionBodyAssociatedType() {
    precondition(ProbeExtension.Body.self == ProbeScene.self)
}

func testTranslationUIProviderExtensionBody() {
    let ext = ProbeExtension()
    let body = ext.body
    precondition(type(of: body) == ProbeScene.self)
}

func testTranslationUIProviderExtensionConfiguration() {
    let ext = ProbeExtension()
    let configuration = ext.configuration
    precondition(type(of: configuration) == AppExtensionSceneConfiguration.self)
    precondition(configuration.hostSceneTypeName.contains("ProbeScene"))
}

func testTranslationProviderUIExtensionConfigurationType() {
    let ext = ProbeExtension()
    let configuration = TranslationProviderUIExtensionConfiguration(ext)
    precondition(type(of: configuration) == TranslationProviderUIExtensionConfiguration.self)
    let asConfig: any AppExtensionConfiguration = configuration
    _ = asConfig
}

func testTranslationProviderUIExtensionConfigurationInit() {
    let ext = ProbeExtension()
    let configuration = TranslationProviderUIExtensionConfiguration(ext)
    precondition(configuration.hostExtensionTypeName.contains("ProbeExtension"))
    precondition(configuration.hostAcceptConnection() == false)
}
