import Foundation

/// ImageIO animation OSStatus values corroborated by pinned dotnet/macios
/// `CGImageAnimationStatus`. The graph does not export a success case.
public enum CGImageAnimationStatus: OSStatus, Sendable {
    case parameterError = -22140
    case corruptInputImage = -22141
    case unsupportedFormat = -22142
    case incompleteInputImage = -22143
    case allocationFailure = -22144
}

/// Metadata-manipulation errors corroborated by pinned macios
/// `CGImageMetadataErrors` / `[ErrorDomain("kCFErrorDomainCGImageMetadata")]`.
public enum CGImageMetadataErrors: Int32, Sendable {
    case unknown = 0
    case unsupportedFormat = 1
    case badArgument = 2
    case conflictingArguments = 3
    case prefixConflict = 4
}

/// XMP/IPTC metadata type-forms corroborated by pinned macios
/// `CGImageMetadataType`.
public enum CGImageMetadataType: Int32, Sendable {
    case invalid = -1
    case `default` = 0
    case string = 1
    case arrayUnordered = 2
    case arrayOrdered = 3
    case alternateArray = 4
    case alternateText = 5
    case structure = 6
}

/// TGA compression identities corroborated by pinned macios
/// `CGImagePropertyTgaCompression`.
@frozen
public enum CGImagePropertyTGACompression: UInt32, Sendable {
    case tgaCompressionNone = 0
    case tgaCompressionRLE = 1
}
