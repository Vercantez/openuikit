import Foundation
import Observation
@_spi(OpenUIKitHost) import TranslationUIProvider

func testTranslationUIProviderContextProtocol() {
    let context = TranslationUIProviderHostContext()
    let asProtocol: any TranslationUIProviderContext = context
    _ = asProtocol
    let asObservable: any Observable = context
    _ = asObservable
}

func testTranslationUIProviderContextInputText() {
    let empty = TranslationUIProviderHostContext()
    precondition(empty.inputText == nil)

    let source = AttributedString("source text")
    let seeded = TranslationUIProviderHostContext(
        inputText: source,
        allowsReplacement: false
    )
    precondition(seeded.inputText == source)

    let injected = TranslationUIProviderHostContext()
    let updated = AttributedString("host-injected")
    injected.hostProvideText(updated, replacementAllowed: false)
    precondition(injected.inputText == updated)
}

func testTranslationUIProviderContextAllowsReplacement() {
    let closed = TranslationUIProviderHostContext()
    precondition(closed.allowsReplacement == false)

    let open = TranslationUIProviderHostContext(
        inputText: AttributedString("src"),
        allowsReplacement: true
    )
    precondition(open.allowsReplacement == true)

    let flipped = TranslationUIProviderHostContext(allowsReplacement: true)
    flipped.hostProvideText(AttributedString("later"), replacementAllowed: false)
    precondition(flipped.allowsReplacement == false)
}

func testTranslationUIProviderContextFinish() {
    let ignored = AttributedString("candidate")
    let source = AttributedString("src")

    let noReplaceNil = TranslationUIProviderHostContext(
        inputText: source,
        allowsReplacement: false
    )
    precondition(noReplaceNil.hostIsFinished == false)
    noReplaceNil.finish(translation: nil)
    precondition(noReplaceNil.hostIsFinished)
    precondition(noReplaceNil.hostFinishRecord?.submittedTranslation == nil)
    precondition(noReplaceNil.hostFinishRecord?.appliedReplacement == nil)

    let noReplaceValue = TranslationUIProviderHostContext(
        inputText: source,
        allowsReplacement: false
    )
    noReplaceValue.finish(translation: ignored)
    precondition(noReplaceValue.hostFinishRecord?.submittedTranslation == ignored)
    precondition(noReplaceValue.hostFinishRecord?.appliedReplacement == nil)

    let replaceValue = TranslationUIProviderHostContext(
        inputText: source,
        allowsReplacement: true
    )
    replaceValue.finish(translation: ignored)
    precondition(replaceValue.hostFinishRecord?.submittedTranslation == ignored)
    precondition(replaceValue.hostFinishRecord?.appliedReplacement == ignored)

    let replaceNil = TranslationUIProviderHostContext(
        inputText: source,
        allowsReplacement: true
    )
    replaceNil.finish(translation: nil)
    precondition(replaceNil.hostFinishRecord?.submittedTranslation == nil)
    precondition(replaceNil.hostFinishRecord?.appliedReplacement == nil)
}

func testTranslationUIProviderContextExpandSheet() {
    let context = TranslationUIProviderHostContext()
    precondition(context.hostExpandSheetRequestCount == 0)
    precondition(context.hostDidPresentExpandedSheet == false)
    context.expandSheet()
    precondition(context.hostExpandSheetRequestCount == 1)
    precondition(context.hostDidPresentExpandedSheet == false)
    context.expandSheet()
    precondition(context.hostExpandSheetRequestCount == 2)
    precondition(context.hostDidPresentExpandedSheet == false)
    do {
        try TranslationUIProviderHostControl.presentTranslationProviderUI()
        preconditionFailure("linux host must not present translation UI")
    } catch let error as TranslationUIProviderUnavailable {
        precondition(error == .linuxHost(operation: "presentTranslationProviderUI"))
    } catch {
        preconditionFailure("unexpected error from presentTranslationProviderUI")
    }
}
