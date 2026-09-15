import Foundation
import AppIntents

// Wave 20: synchronous pins for leftover declared `Never` surface. Every
// test below is a top-level synchronous no-argument function; no Siri
// daemon, Shortcuts registrar, run loop, semaphore, or suspension point is
// used. Async `Never.perform()`, the uncallable `Never.init()`, and all
// async request/donation/confirmation paths stay fail-closed and declared.

private func wave20KeyPathValueName<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> String {
    String(describing: Value.self)
}

func testWave20NeverResultAliases() {
    precondition(String(describing: Never.Value.self) == "Never")
    precondition(String(describing: Never.Dialog.self) == "Never")
    precondition(String(describing: Never.Snippet.self) == "Never")
    precondition(String(describing: Never.OpensAppIntent.self) == "Never")
}

func testWave20NeverIntentAndValue() {
    precondition(String(describing: Never.Intent.self) == "Never")
    precondition(wave20KeyPathValueName(\Never.value) == "Optional<Never>")
}
