import Foundation
import Photos

// Measured against Apple Photos on iPhone 17 / iOS 26.1 (23B86), and
// cross-checked on macOS 26.5.2: each spelling is -1 / .internalError.
// Pure value tests: no library authorization, shared store, or callback waits.
func testInvalidErrorLegacyConstant() {
    let legacy: Int = PHPhotosErrorInvalid
    precondition(legacy == -1)
    precondition(PHPhotosError.Code(rawValue: legacy) == .internalError)
}

func testInvalidErrorOverlayAlias() {
    let code: PHPhotosError.Code = PHPhotosError.invalid
    precondition(code.rawValue == -1)
    precondition(code == PHPhotosError.internalError)
    precondition(PHPhotosError(code).code == .internalError)
}

func testInvalidErrorCodeAlias() {
    let code: PHPhotosError.Code = .invalid
    precondition(code.rawValue == -1)
    precondition(code == .internalError)
    precondition(PHPhotosError.Code(rawValue: code.rawValue) == code)
    precondition(Set([code, .internalError]).count == 1)
    let error: any Error = NSError(domain: PHPhotosErrorDomain, code: -1)
    precondition(code ~= error)
    let unrelated: any Error = NSError(domain: "PhotosInvalidErrorTests", code: -1)
    precondition(!(code ~= unrelated))
}
