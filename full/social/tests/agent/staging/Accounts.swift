import Foundation

// Unit-fixture lookalike only. Not platform Accounts identity.
// Real ACAccount has no zero-argument production initializer; this type
// exists only so isolated unit fixtures can compile without Accounts.

open class ACAccount: NSObject {
    public override init() {
        super.init()
    }
}
