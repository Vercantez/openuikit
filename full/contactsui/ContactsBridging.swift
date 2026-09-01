import Foundation

#if !canImport(Contacts)
/// Minimal Contacts-shaped types so ContactsUI can compile and be exercised
/// before the Contacts module lands. These are not a Contacts implementation:
/// they hold caller-supplied identity only and never wrap a system store.

public protocol CNKeyDescriptor: NSObjectProtocol {}
#endif

public final class CNContactKeyDescriptor: NSObject, CNKeyDescriptor, NSCopying {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return CNContactKeyDescriptor(keys: keys)
    }
}

#if !canImport(Contacts)
open class CNContact: NSObject {
    public var identifier: String
    public var givenName: String
    public var familyName: String
    public var organizationName: String
    public var emailAddresses: [String]
    public var phoneNumbers: [String]
    public var imageData: Data?
    public let id: UUID

    public init(
        identifier: String = UUID().uuidString,
        givenName: String = "",
        familyName: String = "",
        organizationName: String = "",
        emailAddresses: [String] = [],
        phoneNumbers: [String] = [],
        imageData: Data? = nil,
        id: UUID = UUID()
    ) {
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.emailAddresses = emailAddresses
        self.phoneNumbers = phoneNumbers
        self.imageData = imageData
        self.id = id
        super.init()
    }
}

open class CNMutableContact: CNContact {}

open class CNContactStore: NSObject {
    public override init() {
        super.init()
    }
}

open class CNContactProperty: NSObject {
    public let contact: CNContact
    public let key: String
    public let value: Any?
    public let identifier: String?
    public let label: String?

    public init(
        contact: CNContact,
        key: String,
        value: Any? = nil,
        identifier: String? = nil,
        label: String? = nil
    ) {
        self.contact = contact
        self.key = key
        self.value = value
        self.identifier = identifier
        self.label = label
        super.init()
    }
}

open class CNContainer: NSObject {
    public var identifier: String
    public var name: String

    public init(identifier: String = UUID().uuidString, name: String = "") {
        self.identifier = identifier
        self.name = name
        super.init()
    }
}

open class CNGroup: NSObject {
    public var identifier: String
    public var name: String

    public init(identifier: String = UUID().uuidString, name: String = "") {
        self.identifier = identifier
        self.name = name
        super.init()
    }
}

#endif

#if canImport(Contacts)
extension CNMutableContact {
    /// ContactsUI overlay of `CNContact.id`. Mapping from `identifier` remains
    /// an open oracle question; this forwards the Contacts identity UUID.
    public override var id: UUID { super.id }
}
#endif
