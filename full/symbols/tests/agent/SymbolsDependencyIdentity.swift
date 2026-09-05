import Symbols
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Symbols with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s Symbols and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `TimeInterval` / `Date` values flow through public
//    Symbols APIs without a framework-local stand-in.

private func assertNotSymbolsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Symbols."))
}

func symbolsDependencyIdentityMain() {
    let delay: TimeInterval = Date(timeIntervalSince1970: 1).timeIntervalSince1970
    assertNotSymbolsType(delay)
    precondition(type(of: delay) == TimeInterval.self)
    precondition(!String(reflecting: TimeInterval.self).hasPrefix("Symbols."))

    let behavior = SymbolEffectOptions.RepeatBehavior.periodic(2, delay: delay)
    let options = SymbolEffectOptions.default.repeat(behavior).speed(1.5)
    precondition(options != SymbolEffectOptions.default)
    precondition(options == SymbolEffectOptions.speed(1.5).repeat(behavior))

    let angle = Double.pi
    assertNotSymbolsType(angle)
    let wiggle = WiggleSymbolEffect.wiggle.custom(angle: angle)
    precondition(wiggle != WiggleSymbolEffect.wiggle)
}

symbolsDependencyIdentityMain()
