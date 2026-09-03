import Foundation

/// Identifier of a File Provider domain.
public struct NSFileProviderDomainIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Identifier of an item in a File Provider hierarchy.
public struct NSFileProviderItemIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let rootContainer = NSFileProviderItemIdentifier(
        "NSFileProviderRootContainerItemIdentifier"
    )
    public static let trashContainer = NSFileProviderItemIdentifier(
        "NSFileProviderTrashContainerItemIdentifier"
    )
    public static let workingSet = NSFileProviderItemIdentifier(
        "NSFileProviderWorkingSetContainerItemIdentifier"
    )
}

/// Identifier of a custom extension action.
public struct NSFileProviderExtensionActionIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Identifier of an item decoration.
public struct NSFileProviderItemDecorationIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Opaque pagination token for enumerators.
public struct NSFileProviderPage: Hashable, Sendable {
    public let rawValue: Data

    public init(rawValue: Data) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Data) {
        self.rawValue = rawValue
    }

    /// ObjC-imported sentinel. Wrap with `NSFileProviderPage(Data(referencing:))`
    /// when calling enumerator APIs.
    public static let initialPageSortedByName: NSData = NSData(
        data: Data("NSFileProviderInitialPageSortedByName".utf8)
    )

    public static let initialPageSortedByDate: NSData = NSData(
        data: Data("NSFileProviderInitialPageSortedByDate".utf8)
    )

    public static var sortedByName: NSFileProviderPage {
        NSFileProviderPage(Data(referencing: initialPageSortedByName))
    }

    public static var sortedByDate: NSFileProviderPage {
        NSFileProviderPage(Data(referencing: initialPageSortedByDate))
    }
}

/// Opaque change-tracking token for enumerators.
public struct NSFileProviderSyncAnchor: Hashable, Sendable {
    public let rawValue: Data

    public init(rawValue: Data) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Data) {
        self.rawValue = rawValue
    }
}

/// User-info dictionary key used with domain-state payloads.
public struct NSFileProviderUserInfoKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let experimentID = NSFileProviderUserInfoKey(
        "NSFileProviderUserInfoExperimentIDKey"
    )
}
