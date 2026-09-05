import Foundation

/// Photo-editing extension host protocol.
/// https://developer.apple.com/documentation/photosui/phcontenteditingcontroller
/// Linux has no Photos extension session; a conforming type can still be
/// constructed and messaged. Session lifecycle (adjustment data, output
/// URL, cancel confirmation UI) is unobserved.
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
