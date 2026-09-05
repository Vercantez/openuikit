@_spi(OpenUIKitHost) import ExtensionKit
import Foundation

private func onMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    precondition(Thread.isMainThread, "ExtensionKit tests require the main thread")
    MainActor.assumeIsolated(work)
}

@MainActor
private func primitive(_ id: String, accept: Bool) -> PrimitiveAppExtensionScene {
    PrimitiveAppExtensionScene(
        id: id,
        content: { EmptyView() },
        onConnection: { _ in accept }
    )
}

@MainActor
private func ids<S: AppExtensionScene>(_ scene: S) -> [String] {
    AppExtensionSceneConfiguration(scene).host_sceneIDs
}

func testSceneBuilderBuildBlockOne() {
    onMain {
        let scene = primitive("1", accept: true)
        let built = AppExtensionSceneBuilder.buildBlock(scene)
        precondition(ids(built) == ["1"])
        precondition(AppExtensionSceneConfiguration(built).accept(connection: NSXPCConnection()) == true)
    }
}

func testSceneBuilderBuildBlockTwo() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: true)
        )
        precondition(ids(built) == ["1", "2"])
        precondition(AppExtensionSceneConfiguration(built).accept(connection: NSXPCConnection()) == true)
    }
}

func testSceneBuilderBuildBlockThree() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3"])
    }
}

func testSceneBuilderBuildBlockFour() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4"])
    }
}

func testSceneBuilderBuildBlockFive() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5"])
    }
}

func testSceneBuilderBuildBlockSix() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: false),
            primitive("6", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5", "6"])
    }
}

func testSceneBuilderBuildBlockSeven() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: false),
            primitive("6", accept: false),
            primitive("7", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5", "6", "7"])
    }
}

func testSceneBuilderBuildBlockEight() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: false),
            primitive("6", accept: false),
            primitive("7", accept: false),
            primitive("8", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5", "6", "7", "8"])
    }
}

func testSceneBuilderBuildBlockNine() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: false),
            primitive("6", accept: false),
            primitive("7", accept: false),
            primitive("8", accept: false),
            primitive("9", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5", "6", "7", "8", "9"])
    }
}

func testSceneBuilderBuildBlockTen() {
    onMain {
        let built = AppExtensionSceneBuilder.buildBlock(
            primitive("1", accept: false),
            primitive("2", accept: false),
            primitive("3", accept: false),
            primitive("4", accept: false),
            primitive("5", accept: false),
            primitive("6", accept: false),
            primitive("7", accept: false),
            primitive("8", accept: false),
            primitive("9", accept: false),
            primitive("10", accept: true)
        )
        precondition(ids(built) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
        precondition(AppExtensionSceneConfiguration(built).accept(connection: NSXPCConnection()) == true)
    }
}
