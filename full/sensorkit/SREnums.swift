import Foundation

public enum SRAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case authorized = 1
    case denied = 2
}

public enum SRDeletionReason: Int, Hashable, Sendable {
    case userInitiated = 0
    case lowDiskSpace = 1
    case ageLimit = 2
    case noInterestedClients = 3
    case systemInitiated = 4
}

public enum SRMediaEventType: Int, Hashable, Sendable {
    case onScreen = 1
    case offScreen = 2
}
