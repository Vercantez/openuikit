#if canImport(Contacts)
import Contacts
import Foundation

extension CNMutableContact {
    /// ContactsUI overlay of `CNContact.id`. Mapping from `identifier` remains
    /// an open oracle question; this forwards the Contacts identity UUID.
    public override var id: UUID { super.id }
}
#endif
