import Foundation
import AppIntents

// Declared-depth conversions: synchronous, in-process pins for UIKit overlay
// classes, overlay View identities, placeholder builders, prediction
// containers, and intent-parameter metadata. No daemon, Siri service,
// Spotlight index, waiting, or suspension point. Async request/donate,
// View-taking result factories, macros, and service success stay declared
// or fail-closed.

private struct DeclaredProbeIntent: AppIntent {
    static var title: LocalizedStringResource { "Declared Probe" }
    @Parameter(title: "Name")
    var name: String
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: name)
    }
}

func testUIKitOverlayIdentities() {
    let button = ShortcutsUIButton()
    precondition(button.style == .automatic)
    button.addTarget(nil, action: Selector(), for: .touchUpInside)
    let fitted = button.sizeThatFits(CGSize(width: 44, height: 44))
    precondition(fitted.width == 44 && fitted.height == 44)
    let tipView = SiriTipUIView()
    precondition(tipView.isPresented == false)
    precondition(tipView.allowsDismissal == true)
    precondition(tipView.style == .automatic)
    tipView.didMoveToWindow()
    let fittedTip = tipView.sizeThatFits(CGSize(width: 10, height: 20))
    precondition(fittedTip.width == 10 && fittedTip.height == 20)
    precondition(tipView.intrinsicContentSize.width == 0)
    precondition(tipView.intrinsicContentSize.height == 0)
    tipView.setIntent(intent: DeclaredProbeIntent())
}

func testSwiftUIViewIdentities() {
    let tip = SiriTipView(intent: DeclaredProbeIntent())
    _ = tip.body
    let link = ShortcutsLink()
    _ = link.body
    precondition(SiriTipViewStyle.dark != SiriTipViewStyle.light)
    precondition(SiriTipViewStyle.automatic == .automatic)
    precondition(ShortcutsLinkStyle.automatic == .automatic)
}

func testSetFocusFilterIntentErrorCases() {
    let missing = SetFocusFilterIntentError.missingParameterValue
    let notFound = SetFocusFilterIntentError.notFound
    precondition(missing != notFound)
    let all: [SetFocusFilterIntentError] = [.missingParameterValue, .notFound]
    precondition(all.count == 2)
}

func testPlaceholderBuilderIdentities() {
    precondition(IntentPredictionsBuilder._appIntentsPlaceholder == ._appIntentsPlaceholder)
    precondition(ParameterSummaryCaseBuilder._appIntentsPlaceholder == ._appIntentsPlaceholder)
}

func testPredictionContainerIdentities() {
    let prediction = IntentPrediction<DeclaredProbeIntent, String>()
    _ = prediction
    let tuple = TupleIntentPrediction<DeclaredProbeIntent, String>()
    _ = tuple
    let context = FocusFilterSuggestionContext()
    _ = context
}

func testIntentParameterMetadataIdentities() {
    let probe = DeclaredProbeIntent()
    precondition(probe.$name.title.key == "Name")
    precondition(probe.$name.isOptional == false)
    precondition(DeclaredProbeIntent.parameterSummary.evaluatedDisplayString == "")
    precondition(probe.systemContext.currentMode == .background)
    let summary = DeclaredProbeIntent.Summary()
    precondition(summary.evaluatedDisplayString == "")
}
