import Foundation

/// How file contents should be materialized relative to a parent policy.
public enum NSFileProviderContentPolicy: Int, Hashable, Sendable {
    case inherited = 0
    case downloadLazilyAndEvictOnRemoteUpdate = 2
}

/// Side of a testing operation in Apple's replicated-provider test harness.
public enum NSFileProviderTestingOperationSide: UInt, Hashable, Sendable {
    case disk = 0
    case fileProvider = 1
}

/// Kind of a testing operation in Apple's replicated-provider test harness.
public enum NSFileProviderTestingOperationType: Int, Hashable, Sendable {
    case ingestion = 0
    case lookup = 1
    case creation = 2
    case modification = 3
    case deletion = 4
    case contentFetch = 5
    case childrenEnumeration = 6
    case collisionResolution = 7
}

/// Options for creating an item through a replicated extension.
public struct NSFileProviderCreateItemOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let mayAlreadyExist = NSFileProviderCreateItemOptions(rawValue: 1 << 0)
    public static let deletionConflicted = NSFileProviderCreateItemOptions(rawValue: 1 << 1)
}

/// Options for deleting an item through a replicated extension.
public struct NSFileProviderDeleteItemOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let recursive = NSFileProviderDeleteItemOptions(rawValue: 1 << 0)
}

/// Options for modifying an item through a replicated extension.
public struct NSFileProviderModifyItemOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let mayAlreadyExist = NSFileProviderModifyItemOptions(rawValue: 1 << 0)
    public static let failOnConflict = NSFileProviderModifyItemOptions(rawValue: 1 << 1)
    public static let isImmediateUploadRequestByPresentingApplication =
        NSFileProviderModifyItemOptions(rawValue: 1 << 2)
}

/// POSIX-style flags reported on an item.
public struct NSFileProviderFileSystemFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let userExecutable = NSFileProviderFileSystemFlags(rawValue: 1 << 0)
    public static let userReadable = NSFileProviderFileSystemFlags(rawValue: 1 << 1)
    public static let userWritable = NSFileProviderFileSystemFlags(rawValue: 1 << 2)
    public static let hidden = NSFileProviderFileSystemFlags(rawValue: 1 << 3)
    public static let pathExtensionHidden = NSFileProviderFileSystemFlags(rawValue: 1 << 4)
}

/// Capabilities advertised by an item to the Files UI.
public struct NSFileProviderItemCapabilities: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let allowsReading = NSFileProviderItemCapabilities(rawValue: 1 << 0)
    public static let allowsWriting = NSFileProviderItemCapabilities(rawValue: 1 << 1)
    public static let allowsRenaming = NSFileProviderItemCapabilities(rawValue: 1 << 2)
    public static let allowsReparenting = NSFileProviderItemCapabilities(rawValue: 1 << 3)
    public static let allowsTrashing = NSFileProviderItemCapabilities(rawValue: 1 << 4)
    public static let allowsDeleting = NSFileProviderItemCapabilities(rawValue: 1 << 5)
    public static let allowsEvicting = NSFileProviderItemCapabilities(rawValue: 1 << 6)
    public static let allowsAddingSubItems = allowsWriting
    public static let allowsContentEnumerating = allowsReading
    public static let allowsAll: NSFileProviderItemCapabilities = [
        .allowsReading,
        .allowsWriting,
        .allowsRenaming,
        .allowsReparenting,
        .allowsTrashing,
        .allowsDeleting,
    ]
}

/// Fields that changed on an item during create/modify.
public struct NSFileProviderItemFields: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let contents = NSFileProviderItemFields(rawValue: 1 << 0)
    public static let filename = NSFileProviderItemFields(rawValue: 1 << 1)
    public static let parentItemIdentifier = NSFileProviderItemFields(rawValue: 1 << 2)
    public static let lastUsedDate = NSFileProviderItemFields(rawValue: 1 << 3)
    public static let tagData = NSFileProviderItemFields(rawValue: 1 << 4)
    public static let favoriteRank = NSFileProviderItemFields(rawValue: 1 << 5)
    public static let creationDate = NSFileProviderItemFields(rawValue: 1 << 6)
    public static let contentModificationDate = NSFileProviderItemFields(rawValue: 1 << 7)
    public static let fileSystemFlags = NSFileProviderItemFields(rawValue: 1 << 8)
    public static let extendedAttributes = NSFileProviderItemFields(rawValue: 1 << 9)
    public static let typeAndCreator = NSFileProviderItemFields(rawValue: 1 << 10)
}
