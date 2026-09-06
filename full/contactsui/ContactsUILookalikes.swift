@_exported import Foundation

// Isolated-host stand-ins for Contacts, UIKit, and SwiftUI types named by the
// public ContactsUI surface. The sealed host gate compiles this module alone.
// When a real `Contacts` / `UIKit` / `SwiftUI` module is on the link line,
// these blocks compile out. They are not a Linux Contacts or UIKit port.
//
// Runtime gaps versus `full/contacts` (program against that declared API when
// the guest module is linked): no `CNContactStore.requestAccess`, no in-memory
// save/fetch graph, no `CNStorePredicate`, no vCard, no change history, and
// no `CNContactStoreDidChange`. Lookalike contacts exist only so picker /
// editor signatures and host-SPI fixtures type-check.

#if !canImport(Contacts)

public protocol CNKeyDescriptor: NSObjectProtocol, NSCopying, NSSecureCoding {}

extension NSString: CNKeyDescriptor {}

public final class CNContactKeyDescriptor: NSObject, CNKeyDescriptor, NSCopying, NSSecureCoding {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContactKeyDescriptor(keys: keys)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.keys = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "keys") as? [String]) ?? []
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(keys as NSArray, forKey: "keys")
    }
}

public let CNContactGivenNameKey = "givenName"
public let CNContactFamilyNameKey = "familyName"
public let CNContactOrganizationNameKey = "organizationName"
public let CNContactPhoneNumbersKey = "phoneNumbers"
public let CNContactEmailAddressesKey = "emailAddresses"
public let CNContactPostalAddressesKey = "postalAddresses"
public let CNContactIdentifierKey = "identifier"
public let CNLabelHome = "_$!<Home>!$_"
public let CNLabelWork = "_$!<Work>!$_"
public let CNLabelPhoneNumberMobile = "_$!<Mobile>!$_"

open class CNPhoneNumber: NSObject, NSCopying, NSSecureCoding {
    public let stringValue: String

    public init(stringValue string: String) {
        self.stringValue = string
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNPhoneNumber(stringValue: stringValue)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.stringValue = coder.decodeObject(of: NSString.self, forKey: "stringValue") as String? ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(stringValue as NSString, forKey: "stringValue")
    }
}

open class CNPostalAddress: NSObject, NSCopying, NSSecureCoding {
    public var street: String
    public var city: String
    public var state: String
    public var postalCode: String
    public var country: String

    public override init() {
        self.street = ""
        self.city = ""
        self.state = ""
        self.postalCode = ""
        self.country = ""
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CNPostalAddress()
        copy.street = street
        copy.city = city
        copy.state = state
        copy.postalCode = postalCode
        copy.country = country
        return copy
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.street = coder.decodeObject(of: NSString.self, forKey: "street") as String? ?? ""
        self.city = coder.decodeObject(of: NSString.self, forKey: "city") as String? ?? ""
        self.state = coder.decodeObject(of: NSString.self, forKey: "state") as String? ?? ""
        self.postalCode = coder.decodeObject(of: NSString.self, forKey: "postalCode") as String? ?? ""
        self.country = coder.decodeObject(of: NSString.self, forKey: "country") as String? ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(street as NSString, forKey: "street")
        coder.encode(city as NSString, forKey: "city")
        coder.encode(state as NSString, forKey: "state")
        coder.encode(postalCode as NSString, forKey: "postalCode")
        coder.encode(country as NSString, forKey: "country")
    }
}

public class CNLabeledValue<ValueType: NSCopying & NSSecureCoding>: NSObject {
    public let identifier: String
    public let label: String?
    public let value: ValueType

    public init(label: String?, value: ValueType) {
        self.identifier = UUID().uuidString
        self.label = label
        self.value = value.copy(with: nil) as? ValueType ?? value
        super.init()
    }

    public class func localizedString(forLabel label: String) -> String {
        switch label {
        case CNLabelHome: return "Home"
        case CNLabelWork: return "Work"
        case CNLabelPhoneNumberMobile: return "mobile"
        default: return label
        }
    }
}

open class CNContact: NSObject, Identifiable {
    public typealias ID = UUID

    public var id: UUID
    public var identifier: String
    public var givenName: String
    public var familyName: String
    public var organizationName: String
    public var phoneNumbers: [CNLabeledValue<CNPhoneNumber>]
    public var emailAddresses: [CNLabeledValue<NSString>]
    public var postalAddresses: [CNLabeledValue<CNPostalAddress>]

    public override init() {
        let uuid = UUID()
        self.id = uuid
        self.identifier = uuid.uuidString
        self.givenName = ""
        self.familyName = ""
        self.organizationName = ""
        self.phoneNumbers = []
        self.emailAddresses = []
        self.postalAddresses = []
        super.init()
    }

    open class func descriptorForAllComparatorKeys() -> any CNKeyDescriptor {
        CNContactKeyDescriptor(keys: [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactOrganizationNameKey,
        ])
    }

    /// Dictionary snapshot used by portable picker predicates. This is not
    /// Apple KVC; swift-corelibs-foundation does not parse predicate format
    /// strings.
    public func linuxPredicateSnapshot() -> [String: Any] {
        [
            CNContactGivenNameKey: givenName,
            CNContactFamilyNameKey: familyName,
            CNContactOrganizationNameKey: organizationName,
            CNContactIdentifierKey: identifier,
            CNContactPhoneNumbersKey: phoneNumbers.map(\.value.stringValue),
            CNContactEmailAddressesKey: emailAddresses.map { $0.value as String },
            CNContactPostalAddressesKey: postalAddresses.map {
                [$0.value.street, $0.value.city, $0.value.state, $0.value.postalCode]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            },
        ]
    }
}

open class CNMutableContact: CNContact {
    /// Darwin ContactsUI overlay adds `override dynamic var id: UUID` on
    /// `CNMutableContact`. The lookalike inherits `CNContact.id`.
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
        value: Any?,
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

    public func linuxPredicateSnapshot() -> [String: Any] {
        var snapshot: [String: Any] = [
            "key": key,
            "identifier": identifier ?? "",
            "label": label ?? "",
        ]
        if let value {
            snapshot["value"] = value
        }
        return snapshot
    }
}

open class CNContactStore: NSObject {
    /// Empty handle. Isolated Linux never attaches an address book.
    public override init() {
        super.init()
    }
}

open class CNGroup: NSObject {
    public var identifier: String
    public var name: String

    public override init() {
        self.identifier = UUID().uuidString
        self.name = ""
        super.init()
    }
}

open class CNContainer: NSObject {
    public var identifier: String
    public var name: String

    public override init() {
        self.identifier = UUID().uuidString
        self.name = ""
        super.init()
    }
}

#endif

#if !canImport(UIKit)

open class UIView: NSObject {
    public var frame: CGRect = .zero
}

open class UILabel: UIView {
    public var text: String?
}

open class UIViewController: NSObject {
    public var title: String?
    public var view: UIView?

    public override init() {
        super.init()
    }

    open func loadView() {
        if view == nil {
            view = UIView()
        }
    }

    open func viewDidLoad() {}

    open func loadViewIfNeeded() {
        if view == nil {
            loadView()
        }
        viewDidLoad()
    }
}

open class UITableView: UIView {
    public enum Style: Int, Sendable {
        case plain = 0
        case grouped = 1
        case insetGrouped = 2
    }

    public let style: Style

    public init(frame: CGRect, style: Style) {
        self.style = style
        super.init()
        self.frame = frame
    }
}

open class UITableViewCell: UIView {
    public var textLabel: UILabel? = UILabel()
    public var detailTextLabel: UILabel? = UILabel()
}

open class UITableViewController: UIViewController {
    public let tableView: UITableView

    public init(style: UITableView.Style = .plain) {
        self.tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), style: style)
        super.init()
        self.view = tableView
    }
}

open class UIApplicationShortcutIcon: NSObject {
    public private(set) var linuxContactIdentifier: String?

    public override init() {
        super.init()
    }

    public convenience init(contact: CNContact) {
        self.init()
        self.linuxContactIdentifier = contact.identifier
    }
}

#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

public struct Color: Equatable, Hashable, Sendable {
    public let linuxName: String

    public init(linuxName: String) {
        self.linuxName = linuxName
    }

    public static let accentColor = Color(linuxName: "accentColor")
}

@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        getter = get
        setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

public struct LocalizedStringKey: Equatable, Hashable, Sendable {
    public var linuxRaw: String
    public init(_ raw: String) { self.linuxRaw = raw }
}

public struct Text: Equatable, Hashable, Sendable {
    public var linuxRaw: String
    public init(_ raw: String) { self.linuxRaw = raw }
}

public struct LocalizedStringResource: Equatable, Hashable, Sendable {
    public var linuxRaw: String
    public init(_ raw: String) { self.linuxRaw = raw }
}

public struct FocusInteractions: Equatable, Hashable, Sendable {
    public static let automatic = FocusInteractions()
}

public struct Alignment: Equatable, Hashable, Sendable {
    public static let center = Alignment()
}

public struct EdgeInsets: Equatable, Hashable, Sendable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

public enum Edge: Int, Sendable {
    case top = 1
    case leading = 2
    case bottom = 4
    case trailing = 8

    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let all = Set(rawValue: 15)
        public static let top = Set(rawValue: 1)
    }
}

public struct ListSectionSpacing: Equatable, Hashable, Sendable {
    public static let `default` = ListSectionSpacing()
}

public protocol Transferable {}

extension String: Transferable {}

public struct SharePreview<Icon, Label> {
    public init() {}
}

#endif
