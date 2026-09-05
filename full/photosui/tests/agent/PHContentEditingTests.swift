import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private final class HostContentEditor: PHContentEditingController {
    var shouldShowCancelConfirmation = false
    var handledFormat: String?
    var startedInput: PHContentEditingInput?
    var startedPlaceholder: UIImage?
    var finished = false
    var cancelled = false
    var output: PHContentEditingOutput?

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        handledFormat = adjustmentData.formatIdentifier
        return adjustmentData.formatIdentifier == "public.host.adjustment"
    }

    func startContentEditing(
        with contentEditingInput: PHContentEditingInput,
        placeholderImage: UIImage
    ) {
        startedInput = contentEditingInput
        startedPlaceholder = placeholderImage
        shouldShowCancelConfirmation = contentEditingInput.adjustmentData != nil
    }

    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        finished = true
        if let input = startedInput {
            let produced = PHContentEditingOutput(contentEditingInput: input)
            produced.adjustmentData = PHAdjustmentData(
                formatIdentifier: "public.host.adjustment",
                formatVersion: "1",
                data: Data("edit".utf8)
            )
            output = produced
            completionHandler(produced)
        } else {
            completionHandler(nil)
        }
    }

    func cancelContentEditing() {
        cancelled = true
        shouldShowCancelConfirmation = false
    }
}

func testContentEditingCanHandle() {
    let editor = HostContentEditor()
    let matching = PHAdjustmentData(
        formatIdentifier: "public.host.adjustment",
        formatVersion: "1",
        data: Data()
    )
    let other = PHAdjustmentData(
        formatIdentifier: "other",
        formatVersion: "1",
        data: Data()
    )
    precondition(editor.canHandle(matching))
    precondition(!editor.canHandle(other))
    precondition(editor.handledFormat == "other")
}

func testContentEditingStart() {
    let editor = HostContentEditor()
    let input = PHContentEditingInput()
    input.adjustmentData = PHAdjustmentData(
        formatIdentifier: "public.host.adjustment",
        formatVersion: "1",
        data: Data("adj".utf8)
    )
    let placeholder = UIImage()
    editor.startContentEditing(with: input, placeholderImage: placeholder)
    precondition(editor.startedInput === input)
    precondition(editor.startedPlaceholder === placeholder)
    precondition(editor.shouldShowCancelConfirmation)
}

func testContentEditingFinishProducesOutput() {
    let editor = HostContentEditor()
    let input = PHContentEditingInput()
    editor.startContentEditing(with: input, placeholderImage: UIImage())
    var received: PHContentEditingOutput?
    editor.finishContentEditing { received = $0 }
    precondition(editor.finished)
    precondition(received === editor.output)
    precondition(received?.adjustmentData?.formatIdentifier == "public.host.adjustment")
    precondition(received?.adjustmentData?.data == Data("edit".utf8))
}

func testContentEditingCancel() {
    let editor = HostContentEditor()
    editor.shouldShowCancelConfirmation = true
    editor.cancelContentEditing()
    precondition(editor.cancelled)
    precondition(!editor.shouldShowCancelConfirmation)
}

func testContentEditingShouldShowCancelConfirmation() {
    let editor = HostContentEditor()
    precondition(!editor.shouldShowCancelConfirmation)
    editor.shouldShowCancelConfirmation = true
    precondition(editor.shouldShowCancelConfirmation)
}
