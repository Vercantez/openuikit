import Foundation

// Exact unchanged ButtonKit call shape. This intentionally validates only the
// initializer and Error conversion; Darwin's textual description for the
// empty-domain sentinel is not a stable operation.
func buttonKitDefaultNSErrorShape() throws {
    throw NSError() as Error
}

func validateDefaultNSErrorStorage() {
    let error = NSError()
    precondition(error.domain.isEmpty)
    precondition(error.code == 0)
    precondition(error.userInfo.isEmpty)
}
