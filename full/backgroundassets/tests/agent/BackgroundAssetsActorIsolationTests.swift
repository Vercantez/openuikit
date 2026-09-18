@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation

extension AssetPackManager {
    func agentWithIsolatedCheck(_ body: (isolated AssetPackManager) -> Void) {
        body(self)
    }

    func agentVerifyAssumeIsolated() {
        self.assertIsolated()
        self.preconditionIsolated()
        self.assumeIsolated { $0.assertIsolated() }
    }
}

func testAssetPackManagerAssertIsolated() async {
    await AssetPackManager.shared.agentWithIsolatedCheck { isolated in
        isolated.assertIsolated()
    }
}

func testAssetPackManagerPreconditionIsolated() async {
    await AssetPackManager.shared.agentWithIsolatedCheck { isolated in
        isolated.preconditionIsolated()
    }
}

func testAssetPackManagerAssumeIsolated() async {
    await AssetPackManager.shared.agentVerifyAssumeIsolated()
    let fn: ((isolated AssetPackManager) throws -> Void, StaticString, UInt) throws -> Void =
        AssetPackManager.shared.assumeIsolated
    _ = fn
}
