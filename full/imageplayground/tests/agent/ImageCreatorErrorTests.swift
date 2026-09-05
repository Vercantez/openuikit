import Foundation
import ImagePlayground

/// Table-driven `ImageCreator.Error` cases, `allCases`, and `AllCases`.
func testCreatorErrorCases() {
    let expected: [ImageCreator.Error] = [
        .unsupportedInputImage,
        .faceInImageTooSmall,
        .unavailable,
        .notSupported,
        .creationFailed,
        .creationCancelled,
        .unsupportedLanguage,
        .backgroundCreationForbidden,
        .conceptsRequirePersonIdentity,
    ]
    precondition(ImageCreator.Error.allCases == expected)
    precondition(Set(ImageCreator.Error.allCases).count == expected.count)
    precondition(ImageCreator.Error.AllCases.self == [ImageCreator.Error].self)
    for item in expected {
        precondition(ImageCreator.Error.allCases.contains(item))
    }
}

func testCreatorErrorEquatableHashable() {
    let a = ImageCreator.Error.unavailable
    let b = ImageCreator.Error.creationFailed
    precondition(a == .unavailable)
    precondition(a != b)
    precondition(!(a == b))
    precondition(!(a != ImageCreator.Error.unavailable))
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    ImageCreator.Error.unavailable.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == ImageCreator.Error.unavailable.hashValue)
    precondition(Set(ImageCreator.Error.allCases).count == ImageCreator.Error.allCases.count)
}
