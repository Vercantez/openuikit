import Foundation

/// A row shown in a share-extension compose sheet configuration list.
///
/// Title, value, pending flag, and tap handler are local state. Tapping is
/// host-driven: this type never presents Apple settings UI.
open class SLComposeSheetConfigurationItem: NSObject {
    public override init() {
        super.init()
    }

    open var title: String!
    open var value: String!
    open var valuePending: Bool = false
    open var tapHandler: SLComposeSheetConfigurationItemTapHandler!
}
