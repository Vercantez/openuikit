import Foundation
@_spi(OpenUIKitHost) import IdentityDocumentServicesUI

private struct ProbeLeaf: IdentityDocumentRequestScene, Sendable {
    typealias Body = Never
    let id: String
    var body: Never { fatalError("probe leaf") }
}

private struct ProbeScene: IdentityDocumentRequestScene, Sendable {
    var body: ProbeLeaf { ProbeLeaf(id: "nested") }
}

private final class ProbeProvider: IdentityDocumentProvider {
    var registrationUpdates = 0
    var body: ProbeScene { ProbeScene() }

    func performRegistrationUpdates() {
        registrationUpdates += 1
    }
}

func testIdentityDocumentRequestSceneProtocol() {
    let scene = ProbeScene()
    let asProtocol: any IdentityDocumentRequestScene = scene
    _ = asProtocol
    let asAppScene: any AppExtensionScene = scene
    _ = asAppScene
}

func testIdentityDocumentRequestSceneBuilderType() {
    let builder = IdentityDocumentRequestSceneBuilder()
    _ = builder
    precondition(
        type(of: IdentityDocumentRequestSceneBuilder.self)
            == IdentityDocumentRequestSceneBuilder.Type.self
    )
}

func testIdentityDocumentRequestSceneBuilderBuildBlockOne() {
    let scene = ProbeLeaf(id: "one")
    let built = IdentityDocumentRequestSceneBuilder.buildBlock(scene)
    precondition(type(of: built) == ProbeLeaf.self)
    precondition(built.id == "one")
    let asScene: any IdentityDocumentRequestScene = built
    _ = asScene
}

func testIdentityDocumentRequestSceneBuilderBuildBlockTwo() {
    let first = ProbeLeaf(id: "first")
    let second = ProbeLeaf(id: "second")
    let pair = IdentityDocumentRequestSceneBuilder.buildBlock(first, second)
    precondition(type(of: pair) == IdentityDocumentRequestScenePair<ProbeLeaf, ProbeLeaf>.self)
    precondition(pair.first.id == "first")
    precondition(pair.second.id == "second")
    let asScene: any IdentityDocumentRequestScene = pair
    _ = asScene
}

func testIdentityDocumentRequestSceneBuilderBuildOptional() {
    let some = IdentityDocumentRequestSceneBuilder.buildOptional(
        Optional(ProbeLeaf(id: "present"))
    )
    precondition(type(of: some) == IdentityDocumentOptionalRequestScene<ProbeLeaf>.self)
    precondition(some.scene?.id == "present")
    let none = IdentityDocumentRequestSceneBuilder.buildOptional(Optional<ProbeLeaf>.none)
    precondition(none.scene == nil)
    let asScene: any IdentityDocumentRequestScene = none
    _ = asScene
}

func testIdentityDocumentRequestSceneBuilderBuildLimitedAvailability() {
    let scene = ProbeLeaf(id: "limited")
    let wrapped = IdentityDocumentRequestSceneBuilder.buildLimitedAvailability(scene)
    precondition(type(of: wrapped) == ProbeLeaf.self)
    precondition(wrapped.id == "limited")
}

func testIdentityDocumentProviderProtocol() {
    let provider = ProbeProvider()
    let asProtocol: any IdentityDocumentProvider = provider
    _ = asProtocol
    let asApp: any AppExtension = provider
    _ = asApp
}

func testIdentityDocumentProviderBodyAssociatedType() {
    precondition(ProbeProvider.Body.self == ProbeScene.self)
}

func testIdentityDocumentProviderBody() {
    let provider = ProbeProvider()
    let body = provider.body
    precondition(type(of: body) == ProbeScene.self)
}

func testIdentityDocumentProviderConfiguration() {
    let provider = ProbeProvider()
    let configuration = provider.configuration
    precondition(type(of: configuration) == AppExtensionSceneConfiguration.self)
    precondition(configuration.hostSceneTypeName.contains("ProbeScene"))
}

func testIdentityDocumentProviderPerformRegistrationUpdates() {
    let provider = ProbeProvider()
    precondition(provider.registrationUpdates == 0)
    provider.performRegistrationUpdates()
    precondition(provider.registrationUpdates == 1)
    provider.performRegistrationUpdates()
    precondition(provider.registrationUpdates == 2)
}
