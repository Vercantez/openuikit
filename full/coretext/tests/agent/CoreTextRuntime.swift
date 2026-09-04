import Foundation
import CoreText

/// Schema-v2 sealed runner compiles `CoreTextLoadSmoke.swift` and
/// `*Tests.swift`. This probe remains as the named runtime entry the wave-6
/// house rules ask for; it does not print.
func coreTextRuntimeProbe() {
    _ = CTGetCoreTextVersion()
    _ = kCTFontManagerErrorDomain
    _ = CTFontManagerScope.process
}
