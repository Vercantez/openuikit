import TranslationUIProvider
import Foundation
@_spi(OpenUIKitHost) import TranslationUIProvider

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest success. This file is
// not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build TranslationUIProvider with that module on `-I` / `-L`.
// 3. Link this file as a client that imports TranslationUIProvider and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `TRANSLATIONUIPROVIDER_DEPENDENCY_IDENTITY_OK` and that
//    `libTranslationUIProvider.dylib` was loaded.

private func assertNotTranslationUIProviderType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("TranslationUIProvider."))
}

func assertFoundationIdentity() {
    let text: AttributedString = AttributedString("dependency-identity")
    assertNotTranslationUIProviderType(text)
    let context = TranslationUIProviderHostContext(
        inputText: text,
        allowsReplacement: true
    )
    let input: AttributedString? = context.inputText
    precondition(input == text)
    context.finish(translation: text)
    let applied: AttributedString? = context.hostFinishRecord?.appliedReplacement
    precondition(applied == text)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

func translationUIProviderDependencyIdentityMain() {
    assertFoundationIdentity()
    print("TRANSLATIONUIPROVIDER_DEPENDENCY_IDENTITY_OK")
}
