@_spi(OpenUIKitHost) import ExtensionKit
import Foundation

private func onMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    precondition(Thread.isMainThread, "ExtensionKit tests require the main thread")
    MainActor.assumeIsolated(work)
}

private final class ContentProbe: @unchecked Sendable {
    var count = 0
}

@MainActor
private struct SampleScene: AppExtensionScene {
    var body: PrimitiveAppExtensionScene {
        PrimitiveAppExtensionScene(
            id: "sample",
            content: { EmptyView() },
            onConnection: { _ in true }
        )
    }
}

private struct RecordingConfiguration: AppExtensionConfiguration, @unchecked Sendable {
    let result: Bool
    let seen: ContentProbe

    func accept(connection: NSXPCConnection) -> Bool {
        seen.count += 1
        _ = connection
        return result
    }
}

@MainActor
private struct MainProbeExtension: @MainActor AppExtension {
    var configuration: AppExtensionSceneConfiguration {
        AppExtensionSceneConfiguration(
            PrimitiveAppExtensionScene(id: "main", content: { EmptyView() })
        )
    }
}

func testPrimitiveAppExtensionSceneInit() {
    onMain {
        let probe = ContentProbe()
        let scene = PrimitiveAppExtensionScene(
            id: "editor",
            content: {
                probe.count += 1
                return EmptyView()
            },
            onConnection: { _ in true }
        )
        precondition(scene.host_sceneID == "editor")
        precondition(probe.count == 0)
        scene.host_renderContent()
        precondition(probe.count == 1)
        scene.host_renderContent()
        precondition(probe.count == 2)
    }
}

func testPrimitiveAppExtensionSceneDebugDescription() {
    onMain {
        let scene = PrimitiveAppExtensionScene(
            id: "debug-id",
            content: { EmptyView() }
        )
        precondition(scene.debugDescription.contains("debug-id"))
        precondition(scene.debugDescription.contains("PrimitiveAppExtensionScene"))
    }
}

func testPrimitiveAppExtensionSceneDefaultOnConnectionRejects() {
    onMain {
        let scene = PrimitiveAppExtensionScene(
            id: "reject",
            content: { EmptyView() }
        )
        let configuration = AppExtensionSceneConfiguration(scene)
        precondition(configuration.accept(connection: NSXPCConnection()) == false)
        precondition(configuration.accept(connection: NSXPCConnection(serviceName: "x")) == false)
    }
}

func testPrimitiveAppExtensionSceneOnConnectionAccepts() {
    onMain {
        let scene = PrimitiveAppExtensionScene(
            id: "accept",
            content: { EmptyView() },
            onConnection: { connection in
                connection.serviceName == "ok"
            }
        )
        let configuration = AppExtensionSceneConfiguration(scene)
        precondition(configuration.accept(connection: NSXPCConnection(serviceName: "ok")) == true)
        precondition(configuration.accept(connection: NSXPCConnection(serviceName: "no")) == false)
    }
}

func testPrimitiveAppExtensionSceneBodyTypealias() {
    precondition(PrimitiveAppExtensionScene.Body.self == Never.self)
}

func testAppExtensionSceneProtocolConformance() {
    onMain {
        let scene = SampleScene()
        let body = scene.body
        precondition(body.host_sceneID == "sample")
        let configuration = AppExtensionSceneConfiguration(scene)
        precondition(configuration.accept(connection: NSXPCConnection()) == true)
        precondition(configuration.host_sceneIDs == ["sample"])
    }
}

func testAppExtensionSceneConfigurationInit() {
    onMain {
        let scene = PrimitiveAppExtensionScene(
            id: "solo",
            content: { EmptyView() },
            onConnection: { _ in true }
        )
        let configuration = AppExtensionSceneConfiguration(scene)
        precondition(configuration.host_sceneIDs == ["solo"])
        precondition(configuration.accept(connection: NSXPCConnection()) == true)
    }
}

func testAppExtensionSceneConfigurationInitWithConfiguration() {
    onMain {
        let nestedSeen = ContentProbe()
        let nested = RecordingConfiguration(result: true, seen: nestedSeen)
        let scene = PrimitiveAppExtensionScene(
            id: "nested",
            content: { EmptyView() },
            onConnection: { _ in true }
        )
        let configuration = AppExtensionSceneConfiguration(
            scene,
            configuration: nested
        )
        precondition(configuration.accept(connection: NSXPCConnection()) == true)
        precondition(nestedSeen.count == 1)
    }
}

func testAppExtensionSceneConfigurationAcceptDefaultFalse() {
    onMain {
        let configuration = AppExtensionSceneConfiguration(
            PrimitiveAppExtensionScene(id: "none", content: { EmptyView() })
        )
        precondition(configuration.accept(connection: NSXPCConnection()) == false)
    }
}

func testAppExtensionSceneConfigurationAcceptTrue() {
    onMain {
        let reject = PrimitiveAppExtensionScene(
            id: "a",
            content: { EmptyView() },
            onConnection: { _ in false }
        )
        let accept = PrimitiveAppExtensionScene(
            id: "b",
            content: { EmptyView() },
            onConnection: { _ in true }
        )
        let composed = AppExtensionSceneBuilder.buildBlock(reject, accept)
        let configuration = AppExtensionSceneConfiguration(composed)
        precondition(configuration.accept(connection: NSXPCConnection()) == true)
        precondition(configuration.host_sceneIDs == ["a", "b"])
    }
}

func testAppExtensionSceneConfigurationNestedRejects() {
    onMain {
        let nested = RecordingConfiguration(result: false, seen: ContentProbe())
        let scene = PrimitiveAppExtensionScene(
            id: "blocked",
            content: { EmptyView() },
            onConnection: { _ in true }
        )
        let configuration = AppExtensionSceneConfiguration(
            scene,
            configuration: nested
        )
        precondition(configuration.accept(connection: NSXPCConnection()) == false)
    }
}

func testAppExtensionMainThrows() {
    onMain {
        do {
            try MainProbeExtension.main()
            fatalError("AppExtension.main must fail closed")
        } catch let error as ExtensionKitHostError {
            precondition(error == .extensionProcessUnavailable)
            precondition((error as NSError).code == 2)
        } catch {
            fatalError("unexpected error \(error)")
        }
    }
}

func testArrayAppExtensionSceneBodyTypealias() {
    precondition(Array<PrimitiveAppExtensionScene>.Body.self == Never.self)
}

func testArrayAppExtensionSceneComposition() {
    onMain {
        let scenes = [
            PrimitiveAppExtensionScene(
                id: "one",
                content: { EmptyView() },
                onConnection: { _ in false }
            ),
            PrimitiveAppExtensionScene(
                id: "two",
                content: { EmptyView() },
                onConnection: { _ in true }
            ),
        ]
        let configuration = AppExtensionSceneConfiguration(scenes)
        precondition(configuration.host_sceneIDs == ["one", "two"])
        precondition(configuration.accept(connection: NSXPCConnection()) == true)
    }
}

func testAppExtensionSceneBuilderType() {
    onMain {
        let _: AppExtensionSceneBuilder.Type = AppExtensionSceneBuilder.self
        let scene = PrimitiveAppExtensionScene(id: "builder", content: { EmptyView() })
        let passthrough = AppExtensionSceneBuilder.buildBlock(scene)
        let configuration = AppExtensionSceneConfiguration(passthrough)
        precondition(configuration.host_sceneIDs == ["builder"])
    }
}
