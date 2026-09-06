import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

func testPlatformCases() {
    let cases: [Platform] = [.iOS, .macOS, .visionOS]
    precondition(cases.count == 3)
    precondition(Platform.iOS != .macOS)
    precondition(Platform.macOS != .visionOS)
    precondition(Platform.iOS != .visionOS)
}

func testPlatformDescription() {
    precondition(Platform.iOS.description == "iOS")
    precondition(Platform.macOS.description == "macOS")
    precondition(Platform.visionOS.description == "visionOS")
    precondition(String(describing: Platform.iOS) == "iOS")
}

func testPlatformHashable() {
    precondition(Platform.iOS == Platform.iOS)
    precondition(Set([Platform.iOS, .iOS, .macOS]).count == 2)
    var hasher = Hasher()
    Platform.visionOS.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Platform.macOS.hashValue == Platform.macOS.hashValue)
}

func testPlatformInequality() {
    precondition(Platform.iOS != Platform.macOS)
    precondition(!(Platform.iOS != Platform.iOS))
}

func testManagedAppPlatformCases() {
    let cases: [ManagedApp.Platform] = [.iOS, .macOS, .visionOS]
    precondition(cases.count == 3)
    precondition(ManagedApp.Platform.iOS != .macOS)
    precondition(ManagedApp.Platform.macOS != .visionOS)
}

func testManagedAppPlatformDescription() {
    precondition(ManagedApp.Platform.iOS.description == "iOS")
    precondition(ManagedApp.Platform.macOS.description == "macOS")
    precondition(ManagedApp.Platform.visionOS.description == "visionOS")
}

func testManagedAppPlatformHashable() {
    precondition(ManagedApp.Platform.iOS == ManagedApp.Platform.iOS)
    precondition(Set([ManagedApp.Platform.iOS, .visionOS]).count == 2)
    var hasher = Hasher()
    ManagedApp.Platform.macOS.hash(into: &hasher)
    _ = hasher.finalize()
}

func testManagedAppPlatformInequality() {
    precondition(ManagedApp.Platform.iOS != ManagedApp.Platform.macOS)
    precondition(!(ManagedApp.Platform.visionOS != .visionOS))
}
