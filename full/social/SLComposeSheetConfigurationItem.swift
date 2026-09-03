import Foundation

/// Configuration row shown by a compose-service extension sheet.
///
/// Darwin pins `init!()`. This type subclasses `NSObject`, whose designated
/// `init()` is nonfailable, so Swift requires a nonfailable `override init()`.
/// There is no isolated-host failure condition that would return nil.
open class SLComposeSheetConfigurationItem: NSObject {
    open var title: String!
    open var value: String!
    open var valuePending: Bool = false
    open var tapHandler: SLComposeSheetConfigurationItemTapHandler!

    /// Stronger than the pinned `init!()`: see file comment.
    public override init() {
        super.init()
        title = nil
        value = nil
        valuePending = false
        tapHandler = nil
    }
}
