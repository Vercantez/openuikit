import Foundation

/// An item in the contact database.
///
/// Linux stores a `CNMutableContact` payload (Contacts type or isolation
/// stand-in) plus the app's identifier. Equality and hashing use the item
/// identifier and the contact's `identifier` string. Darwin equality of the
/// mutable contact graph is unobserved.
public enum ContactItem: Equatable, Hashable {
    /// An item that represents a person or organization.
    case contact(CNMutableContact, Identifier)

    public static func == (a: ContactItem, b: ContactItem) -> Bool {
        switch (a, b) {
        case (.contact(let leftContact, let leftID), .contact(let rightContact, let rightID)):
            return leftID == rightID && leftContact.identifier == rightContact.identifier
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .contact(let contact, let identifier):
            hasher.combine(identifier)
            hasher.combine(contact.identifier)
        }
    }

    /// The app's identifier for an item in the contact database.
    public struct Identifier: Equatable, Hashable, Sendable {
        /// The value of the identifier.
        public let value: String

        /// Creates an identifier with the given value.
        public init(_ value: String) {
            self.value = value
        }

        /// The top-level container, containing the user’s contacts.
        ///
        /// Darwin's exact string is unobserved. Linux uses the stable sentinel
        /// `rootContainer`; see `oracle-questions.tsv`.
        public static let rootContainer = Identifier(ContactProviderLinux.rootContainerValue)

        public static func == (a: Identifier, b: Identifier) -> Bool {
            a.value == b.value
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
}

/// A fixed offset into enumerating all contact items.
///
/// `generationMarker` must stay stable for a content enumeration in progress.
/// `offset` tracks how many items have been delivered for that generation.
public struct ContactItemPage: Equatable, Codable, Sendable {
    /// A value specific to your data source identifying the database generation
    /// when enumeration of content started.
    public var generationMarker: Data

    /// An offset from the page's generation marker.
    public var offset: Int

    /// Creates a contact item page with the given generation marker and offset.
    public init(generationMarker: Data, offset: Int) {
        self.generationMarker = generationMarker
        self.offset = offset
    }

    /// A static value the system uses to indicate the start of a new content
    /// enumeration. Linux uses empty `Data` and offset `0`.
    public static let initialPage = ContactItemPage(generationMarker: Data(), offset: 0)

    public static func == (a: ContactItemPage, b: ContactItemPage) -> Bool {
        a.generationMarker == b.generationMarker && a.offset == b.offset
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(generationMarker, forKey: .generationMarker)
        try container.encode(offset, forKey: .offset)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generationMarker = try container.decode(Data.self, forKey: .generationMarker)
        offset = try container.decode(Int.self, forKey: .offset)
    }

    private enum CodingKeys: String, CodingKey {
        case generationMarker
        case offset
    }
}

/// A snapshot point into enumerating changed contact items.
public struct ContactItemSyncAnchor: Equatable, Codable, Sendable {
    /// A value specific to your data source identifying the database generation
    /// you're enumerating for changes.
    public var generationMarker: Data

    /// An offset from the anchor's generation marker.
    public var offset: Int

    /// Creates a sync anchor with the given generation marker and offset.
    public init(generationMarker: Data, offset: Int) {
        self.generationMarker = generationMarker
        self.offset = offset
    }

    public static func == (a: ContactItemSyncAnchor, b: ContactItemSyncAnchor) -> Bool {
        a.generationMarker == b.generationMarker && a.offset == b.offset
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(generationMarker, forKey: .generationMarker)
        try container.encode(offset, forKey: .offset)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generationMarker = try container.decode(Data.self, forKey: .generationMarker)
        offset = try container.decode(Int.self, forKey: .offset)
    }

    private enum CodingKeys: String, CodingKey {
        case generationMarker
        case offset
    }
}
