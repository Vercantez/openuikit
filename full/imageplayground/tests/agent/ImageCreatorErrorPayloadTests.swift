import Foundation
import ImagePlayground

func testCreatorErrorDomain() {
    precondition(ImageCreator.Error.errorDomain == "ImagePlayground.ImageCreator.Error")
    let nsError = ImageCreator.Error.unavailable as NSError
    precondition(nsError.domain == ImageCreator.Error.errorDomain)
}

func testCreatorErrorCode() {
    for (index, item) in ImageCreator.Error.allCases.enumerated() {
        precondition(item.errorCode == index)
        let nsError = item as NSError
        precondition(nsError.code == index)
    }
}

func testCreatorErrorUserInfo() {
    for item in ImageCreator.Error.allCases {
        precondition(item.errorUserInfo.isEmpty)
    }
}

func testCreatorErrorLocalizedPayload() {
    let descriptions: [ImageCreator.Error: String] = [
        .unsupportedInputImage:
            "The system cannot use one of the specified source images.",
        .faceInImageTooSmall:
            "The system cannot use one of the source images because the face in it is too small.",
        .unavailable:
            "Image creation is currently unavailable.",
        .notSupported:
            "The device doesn’t support image generation.",
        .creationFailed:
            "A general failure occurred during image creation.",
        .creationCancelled:
            "Image creation was cancelled.",
        .unsupportedLanguage:
            "The input text uses an unsupported language.",
        .backgroundCreationForbidden:
            "The app is hidden or in the background.",
        .conceptsRequirePersonIdentity:
            "A source image containing a person's face needs to be added in order to complete the request.",
    ]
    for item in ImageCreator.Error.allCases {
        let expected = descriptions[item]!
        precondition(item.errorDescription == expected)
        precondition(item.failureReason == nil)
        precondition(item.recoverySuggestion == nil)
        precondition(item.helpAnchor == nil)
        // swift-corelibs-foundation synthesizes NSError-style text; Darwin
        // may surface errorDescription directly. Both paths are nonempty.
        precondition(!item.localizedDescription.isEmpty)
        precondition(item.localizedDescription.contains(ImageCreator.Error.errorDomain))
        precondition(item.localizedDescription.contains("error \(item.errorCode)"))
    }
}
