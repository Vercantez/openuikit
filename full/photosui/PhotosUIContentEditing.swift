import Foundation

public protocol PHContentEditingController: AnyObject {
    var shouldShowCancelConfirmation: Bool { get }

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool

    func startContentEditing(
        with contentEditingInput: PHContentEditingInput,
        placeholderImage: UIImage
    )

    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void)

    func cancelContentEditing()
}
