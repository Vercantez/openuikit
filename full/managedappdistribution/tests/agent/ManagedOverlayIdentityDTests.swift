import Foundation
import ManagedAppDistribution

// Identity coverage for the synthesized SwiftUI View-modifier census.
// Linux has no SwiftUI layout engine; each modifier is a documented
// no-op returning `self`. Each test calls every overload of one
// modifier on both overlay views and checks the value passes through
// unchanged. All calls are synchronous; no queues, run loops, or semaphores are used.

func testScrollContentBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollContentBackground(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollContentBackground(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollDismissesKeyboardIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollDismissesKeyboard(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollDismissesKeyboard(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollEdgeEffectHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollEdgeEffectHidden(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollEdgeEffectHidden(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollEdgeEffectStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollEdgeEffectStyle(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollEdgeEffectStyle(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollIndicatorsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollIndicators(nil, axes: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollIndicators(nil, axes: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollIndicatorsFlashIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollIndicatorsFlash(trigger: nil)
    let appOut1 = appView.scrollIndicatorsFlash(onAppear: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollIndicatorsFlash(trigger: nil)
    let contentOut1 = contentView.scrollIndicatorsFlash(onAppear: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testScrollInputBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollInputBehavior(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollInputBehavior(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollPositionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollPosition(id: nil, anchor: nil)
    let appOut1 = appView.scrollPosition(nil, anchor: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollPosition(id: nil, anchor: nil)
    let contentOut1 = contentView.scrollPosition(nil, anchor: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testScrollTargetBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollTargetBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollTargetBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollTargetLayoutIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollTargetLayout(isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollTargetLayout(isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollTransitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
    let appOut1 = appView.scrollTransition(nil, axis: nil, transition: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
    let contentOut1 = contentView.scrollTransition(nil, axis: nil, transition: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSearchCompletionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchCompletion(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchCompletion(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSearchDictationBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchDictationBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchDictationBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSearchFocusedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchFocused(nil, equals: nil)
    let appOut1 = appView.searchFocused(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchFocused(nil, equals: nil)
    let contentOut1 = contentView.searchFocused(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSearchPresentationToolbarBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchPresentationToolbarBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchPresentationToolbarBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSearchScopesIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchScopes(nil, activation: nil, nil)
    let appOut1 = appView.searchScopes(nil, scopes: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchScopes(nil, activation: nil, nil)
    let contentOut1 = contentView.searchScopes(nil, scopes: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSearchSelectionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchSelection(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchSelection(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSearchSuggestionsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchSuggestions(nil, for: nil)
    let appOut1 = appView.searchSuggestions(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchSuggestions(nil, for: nil)
    let contentOut1 = contentView.searchSuggestions(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSearchToolbarBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchToolbarBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchToolbarBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSearchableIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    let appOut1 = appView.searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let appOut2 = appView.searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    let appOut3 = appView.searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let appOut4 = appView.searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let appOut5 = appView.searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
    let appOut6 = appView.searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    let appOut7 = appView.searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    let appOut8 = appView.searchable(text: nil, placement: nil, prompt: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    precondition(type(of: appOut4) == ManagedAppView.self)
    precondition(appOut4.body.storage == "OverlayProbe")
    precondition(type(of: appOut5) == ManagedAppView.self)
    precondition(appOut5.body.storage == "OverlayProbe")
    precondition(type(of: appOut6) == ManagedAppView.self)
    precondition(appOut6.body.storage == "OverlayProbe")
    precondition(type(of: appOut7) == ManagedAppView.self)
    precondition(appOut7.body.storage == "OverlayProbe")
    precondition(type(of: appOut8) == ManagedAppView.self)
    precondition(appOut8.body.storage == "OverlayProbe")
    let contentOut0 = contentView.searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    let contentOut1 = contentView.searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let contentOut2 = contentView.searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    let contentOut3 = contentView.searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let contentOut4 = contentView.searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    let contentOut5 = contentView.searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
    let contentOut6 = contentView.searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    let contentOut7 = contentView.searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    let contentOut8 = contentView.searchable(text: nil, placement: nil, prompt: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
    precondition(type(of: contentOut4) == ManagedContentView<Text>.self)
    precondition(contentOut4.body.storage == "ProbeIcon")
    precondition(type(of: contentOut5) == ManagedContentView<Text>.self)
    precondition(contentOut5.body.storage == "ProbeIcon")
    precondition(type(of: contentOut6) == ManagedContentView<Text>.self)
    precondition(contentOut6.body.storage == "ProbeIcon")
    precondition(type(of: contentOut7) == ManagedContentView<Text>.self)
    precondition(contentOut7.body.storage == "ProbeIcon")
    precondition(type(of: contentOut8) == ManagedContentView<Text>.self)
    precondition(contentOut8.body.storage == "ProbeIcon")
}

func testSectionActionsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.sectionActions(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.sectionActions(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSectionIndexLabelIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.sectionIndexLabel(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.sectionIndexLabel(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSelectionDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.selectionDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.selectionDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSensoryFeedbackIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.sensoryFeedback(trigger: nil, nil)
    let appOut1 = appView.sensoryFeedback(nil, trigger: nil, condition: nil)
    let appOut2 = appView.sensoryFeedback(nil, trigger: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.sensoryFeedback(trigger: nil, nil)
    let contentOut1 = contentView.sensoryFeedback(nil, trigger: nil, condition: nil)
    let contentOut2 = contentView.sensoryFeedback(nil, trigger: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testShadowIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.shadow(color: nil, radius: nil, x: nil, y: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.shadow(color: nil, radius: nil, x: nil, y: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSheetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.sheet(isPresented: nil, onDismiss: nil, content: nil)
    let appOut1 = appView.sheet(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.sheet(isPresented: nil, onDismiss: nil, content: nil)
    let contentOut1 = contentView.sheet(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSimultaneousGestureIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.simultaneousGesture(nil, name: nil, isEnabled: nil)
    let appOut1 = appView.simultaneousGesture(nil, including: nil)
    let appOut2 = appView.simultaneousGesture(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.simultaneousGesture(nil, name: nil, isEnabled: nil)
    let contentOut1 = contentView.simultaneousGesture(nil, including: nil)
    let contentOut2 = contentView.simultaneousGesture(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testSliderThumbVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.sliderThumbVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.sliderThumbVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSpeechAdjustedPitchIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.speechAdjustedPitch(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.speechAdjustedPitch(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSpeechAlwaysIncludesPunctuationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.speechAlwaysIncludesPunctuation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.speechAlwaysIncludesPunctuation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSpeechAnnouncementsQueuedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.speechAnnouncementsQueued(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.speechAnnouncementsQueued(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSpeechSpellsOutCharactersIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.speechSpellsOutCharacters(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.speechSpellsOutCharacters(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSpringLoadingBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.springLoadingBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.springLoadingBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testStatusBarIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.statusBar(hidden: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.statusBar(hidden: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testStatusBarHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.statusBarHidden(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.statusBarHidden(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testStrikethroughIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.strikethrough(nil, pattern: nil, color: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.strikethrough(nil, pattern: nil, color: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSubmitLabelIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.submitLabel(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.submitLabel(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSubmitScopeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.submitScope(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.submitScope(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSwipeActionsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSymbolColorRenderingModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolColorRenderingMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolColorRenderingMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSymbolEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolEffect(nil, options: nil, value: nil)
    let appOut1 = appView.symbolEffect(nil, options: nil, isActive: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolEffect(nil, options: nil, value: nil)
    let contentOut1 = contentView.symbolEffect(nil, options: nil, isActive: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSymbolEffectsRemovedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolEffectsRemoved(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolEffectsRemoved(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSymbolRenderingModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolRenderingMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolRenderingMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSymbolVariableValueModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolVariableValueMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolVariableValueMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSymbolVariantIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.symbolVariant(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.symbolVariant(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabBarMinimizeBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabBarMinimizeBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabBarMinimizeBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabItemIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabItem(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabItem(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewBottomAccessoryIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewBottomAccessory(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewBottomAccessory(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewCustomizationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewCustomization(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewCustomization(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewSearchActivationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewSearchActivation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewSearchActivation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewSidebarBottomBarIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewSidebarBottomBar(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewSidebarBottomBar(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewSidebarFooterIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewSidebarFooter(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewSidebarFooter(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewSidebarHeaderIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewSidebarHeader(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewSidebarHeader(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTabViewStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tabViewStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tabViewStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTableColumnHeadersIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tableColumnHeaders(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tableColumnHeaders(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTableStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tableStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tableStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTagIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tag(nil, includeOptional: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tag(nil, includeOptional: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTaskIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)
    let appOut1 = appView.task(id: nil, priority: nil, nil)
    let appOut2 = appView.task(priority: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)
    let contentOut1 = contentView.task(id: nil, priority: nil, nil)
    let contentOut2 = contentView.task(priority: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testTextCaseIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textCase(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textCase(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextContentTypeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textContentType(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textContentType(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextEditorStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textEditorStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textEditorStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextFieldStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textFieldStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textFieldStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextInputAutocapitalizationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textInputAutocapitalization(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textInputAutocapitalization(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextInputFormattingControlVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textInputFormattingControlVisibility(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textInputFormattingControlVisibility(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextRendererIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textRenderer(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textRenderer(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextScaleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textScale(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textScale(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextSelectionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textSelection(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textSelection(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTextSelectionAffinityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.textSelectionAffinity(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.textSelectionAffinity(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTintIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tint(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tint(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToggleStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toggleStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toggleStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbar(id: nil, content: nil)
    let appOut1 = appView.toolbar(content: nil)
    let appOut2 = appView.toolbar(removing: nil)
    let appOut3 = appView.toolbar(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbar(id: nil, content: nil)
    let contentOut1 = contentView.toolbar(content: nil)
    let contentOut2 = contentView.toolbar(removing: nil)
    let contentOut3 = contentView.toolbar(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testToolbarBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarBackground(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarBackground(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarBackgroundVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarBackgroundVisibility(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarBackgroundVisibility(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarColorSchemeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarColorScheme(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarColorScheme(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarForegroundStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarForegroundStyle(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarForegroundStyle(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarRoleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarRole(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarRole(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarTitleDisplayModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarTitleDisplayMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarTitleDisplayMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarTitleMenuIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarTitleMenu(content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarTitleMenu(content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testToolbarVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.toolbarVisibility(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.toolbarVisibility(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTrackingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.tracking(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.tracking(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTransactionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transaction(value: nil, nil)
    let appOut1 = appView.transaction(nil, body: nil)
    let appOut2 = appView.transaction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transaction(value: nil, nil)
    let contentOut1 = contentView.transaction(nil, body: nil)
    let contentOut2 = contentView.transaction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testTransformAnchorPreferenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transformAnchorPreference(key: nil, value: nil, transform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transformAnchorPreference(key: nil, value: nil, transform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTransformEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transformEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transformEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTransformEnvironmentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transformEnvironment(nil, transform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transformEnvironment(nil, transform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTransformPreferenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transformPreference(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transformPreference(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTransitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.transition(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.transition(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTruncationModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.truncationMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.truncationMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTypeSelectEquivalentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.typeSelectEquivalent(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.typeSelectEquivalent(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testTypesettingLanguageIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.typesettingLanguage(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.typesettingLanguage(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testUnderlineIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.underline(nil, pattern: nil, color: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.underline(nil, pattern: nil, color: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testUnredactedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.unredacted()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.unredacted()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testUserActivityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.userActivity(nil, element: nil, nil)
    let appOut1 = appView.userActivity(nil, isActive: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.userActivity(nil, element: nil, nil)
    let contentOut1 = contentView.userActivity(nil, isActive: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testVisualEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.visualEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.visualEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testWindowToolbarFullScreenVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.windowToolbarFullScreenVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.windowToolbarFullScreenVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testWritingDirectionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.writingDirection(strategy: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.writingDirection(strategy: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testWritingToolsAffordanceVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.writingToolsAffordanceVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.writingToolsAffordanceVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testWritingToolsBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.writingToolsBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.writingToolsBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testZIndexIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.zIndex(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.zIndex(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}
