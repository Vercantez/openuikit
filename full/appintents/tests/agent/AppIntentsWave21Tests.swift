import Foundation
import AppIntents

// Wave 21: synchronous pins for leftover declared `_System` parameter
// shapes and `ShortcutsLinkStyle` static members. Every test below is a
// top-level synchronous no-argument function that blocks on nothing; no
// Siri daemon or Shortcuts registrar is involved. Options
// providers and resolver specifications attach metadata only and are never
// consulted; async request/confirmation/donation paths stay fail-closed
// and declared. Style tokens are host-local: Linux renders no SwiftUI.

private struct Wave21StringOptions: DynamicOptionsProvider {
    typealias Result = [String]
    init() {}
    func results() async throws -> [String] { ["alpha"] }
}

func testWave21SystemParameterDescriptionProviderShapes() {
    let both = IntentParameter<String>(
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default,
        optionsProvider: Wave21StringOptions(),
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(both.wrappedValue == "v")
    precondition(both.metadata.description == "Find")
    precondition(both.metadata.requestValueDialog?.text == "need value")
    precondition(both.hasOptionsProvider == true)
    precondition(both.title.key == "")
    let providerOnly = IntentParameter<String>(
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default,
        optionsProvider: Wave21StringOptions()
    )
    precondition(providerOnly.wrappedValue == "v")
    precondition(providerOnly.metadata.description == "Find")
    precondition(providerOnly.hasOptionsProvider == true)
}

func testWave21SystemParameterDescriptionResolverShapes() {
    let resolversOnly = IntentParameter<String>(
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default,
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(resolversOnly.wrappedValue == "v")
    precondition(resolversOnly.metadata.description == "Find")
    precondition(resolversOnly.metadata.requestValueDialog?.text == "need value")
    precondition(resolversOnly.hasOptionsProvider == false)
    let plain = IntentParameter<String>(
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default
    )
    precondition(plain.wrappedValue == "v")
    precondition(plain.metadata.description == "Find")
    precondition(plain.hasOptionsProvider == false)
}

func testWave21SystemParameterTitledShapes() {
    let both = IntentParameter<String>(
        title: LocalizedStringResource("Site"),
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default,
        optionsProvider: Wave21StringOptions(),
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(both.wrappedValue == "v")
    precondition(both.title.key == "Site")
    precondition(both.metadata.description == "Find")
    precondition(both.hasOptionsProvider == true)
    let resolversOnly = IntentParameter<String>(
        title: LocalizedStringResource("Site"),
        description: LocalizedStringResource("Find"),
        default: "v",
        requestValueDialog: IntentDialog("need value"),
        inputConnectionBehavior: .default,
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(resolversOnly.wrappedValue == "v")
    precondition(resolversOnly.title.key == "Site")
    precondition(resolversOnly.hasOptionsProvider == false)
}

func testWave21ShortcutsLinkStyleIdentities() {
    precondition(ShortcutsLinkStyle.dark != ShortcutsLinkStyle.light)
    precondition(ShortcutsLinkStyle.dark != ShortcutsLinkStyle.automatic)
    precondition(ShortcutsLinkStyle.light != ShortcutsLinkStyle.automatic)
    precondition(ShortcutsLinkStyle() == ShortcutsLinkStyle.automatic)
    var hasher = Hasher()
    ShortcutsLinkStyle.dark.hash(into: &hasher)
    let hashed = hasher.finalize()
    var hasher2 = Hasher()
    ShortcutsLinkStyle.dark.hash(into: &hasher2)
    precondition(hashed == hasher2.finalize())
}

func testWave21ShortcutsLinkStyleOutlines() {
    precondition(ShortcutsLinkStyle.darkOutline != ShortcutsLinkStyle.lightOutline)
    precondition(ShortcutsLinkStyle.darkOutline != ShortcutsLinkStyle.automaticOutline)
    precondition(ShortcutsLinkStyle.lightOutline != ShortcutsLinkStyle.automaticOutline)
    precondition(ShortcutsLinkStyle.automaticOutline != ShortcutsLinkStyle.automatic)
    precondition(ShortcutsLinkStyle.darkOutline != ShortcutsLinkStyle.dark)
    precondition(ShortcutsLinkStyle.lightOutline != ShortcutsLinkStyle.light)
}
