import Foundation

public struct HMError: Error, CustomNSError, Hashable, @unchecked Sendable {
    public enum Code: Int, Sendable, Hashable {
        case accessDenied = 10
        case accessoryCommunicationFailure = 101
        case accessoryDiscoveryFailed = 57
        case accessoryIsBlocked = 61
        case accessoryIsBusy = 14
        case accessoryIsSuspended = 103
        case accessoryNotReachable = 4
        case accessoryOutOfCompliance = 66
        case accessoryOutOfResources = 16
        case accessoryPairingFailed = 18
        case accessoryPoweredOff = 9
        case accessoryResponseError = 59
        case accessorySentInvalidResponse = 50
        case actionInAnotherActionSet = 30
        case actionSetExecutionFailed = 63
        case actionSetExecutionInProgress = 65
        case actionSetExecutionPartialSuccess = 64
        case addAccessoryFailed = 79
        case alreadyExists = 1
        case bridgedAccessoryNotReachable = 88
        case cannotActivateTriggerTooFarInFuture = 71
        case cannotRemoveBuiltinActionSet = 83
        case cannotRemoveNonBridgeAccessory = 34
        case cannotUnblockNonBridgeAccessory = 81
        case clientRequestError = 58
        case cloudDataSyncInProgress = 77
        case communicationFailure = 54
        case dataResetFailure = 67
        case dateMustBeOnSpecifiedBoundaries = 70
        case deviceLocked = 82
        case enterpriseNetworkNotSupported = 99
        case failedToJoinNetwork = 102
        case fireDateInPast = 28
        case genericError = 52
        case homeAccessNotAuthorized = 47
        case homeUpgradeRequired = 105
        case homeWithSimilarNameExists = 32
        case incompatibleAccessory = 93
        case incompatibleNetwork = 90
        case insufficientPrivileges = 17
        case invalidAssociatedServiceType = 62
        case invalidClass = 22
        case invalidDataFormatSpecified = 19
        case invalidMessageSize = 56
        case invalidOrMissingAuthorizationData = 87
        case invalidParameter = 3
        case invalidValueType = 43
        case keychainSyncNotEnabled = 76
        case locationForHomeDisabled = 84
        case maximumAccessoriesOfTypeInHome = 97
        case maximumObjectLimitReached = 49
        case messageAuthenticationFailed = 55
        case missingEntitlement = 80
        case missingParameter = 27
        case nameContainsProhibitedCharacters = 35
        case nameDoesNotEndWithValidCharacters = 60
        case nameDoesNotStartWithValidCharacters = 36
        case networkUnavailable = 78
        case nilParameter = 20
        case noActionsInActionSet = 25
        case noCompatibleHomeHub = 92
        case noHomeHub = 91
        case noRegisteredActionSets = 26
        case notAuthorizedForLocationServices = 85
        case notAuthorizedForMicrophoneAccess = 89
        case notFound = 2
        case notSignedIntoiCloud = 75
        case notificationAlreadyEnabled = 68
        case notificationNotSupported = 7
        case objectAlreadyAssociatedToHome = 13
        case objectAssociatedToAnotherHome = 11
        case objectNotAssociatedToAnyHome = 12
        case objectWithSimilarNameExists = 95
        case objectWithSimilarNameExistsInHome = 31
        case operationCancelled = 23
        case operationInProgress = 15
        case operationNotSupported = 48
        case operationTimedOut = 8
        case ownershipFailure = 96
        case partialCommunicationFailure = 104
        case quotaExceeded = 106
        case readOnlyCharacteristic = 5
        case readWriteFailure = 74
        case readWritePartialSuccess = 73
        case recurrenceMustBeOnSpecifiedBoundaries = 69
        case recurrenceTooLarge = 72
        case recurrenceTooSmall = 42
        case referToUserManual = 86
        case renameWithSimilarName = 33
        case roomForHomeCannotBeInZone = 24
        case roomForHomeCannotBeUpdated = 29
        case securityFailure = 53
        case stringLongerThanMaximum = 46
        case stringShorterThanMinimum = 51
        case timedOutWaitingForAccessory = 100
        case unconfiguredParameter = 21
        case unexpectedError = -1
        case userDeclinedAddingUser = 38
        case userDeclinedInvite = 40
        case userDeclinedRemovingUser = 39
        case userIDNotEmailAddress = 37
        case userManagementFailed = 41
        case valueHigherThanMaximum = 45
        case valueLowerThanMinimum = 44
        case wiFiCredentialGenerationFailed = 98
        case writeOnlyCharacteristic = 6
        public static var incompatibleHomeHub: Code { .noCompatibleHomeHub }
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { HMErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var accessDenied: Code { .accessDenied }
    public static var accessoryCommunicationFailure: Code { .accessoryCommunicationFailure }
    public static var accessoryDiscoveryFailed: Code { .accessoryDiscoveryFailed }
    public static var accessoryIsBlocked: Code { .accessoryIsBlocked }
    public static var accessoryIsBusy: Code { .accessoryIsBusy }
    public static var accessoryIsSuspended: Code { .accessoryIsSuspended }
    public static var accessoryNotReachable: Code { .accessoryNotReachable }
    public static var accessoryOutOfCompliance: Code { .accessoryOutOfCompliance }
    public static var accessoryOutOfResources: Code { .accessoryOutOfResources }
    public static var accessoryPairingFailed: Code { .accessoryPairingFailed }
    public static var accessoryPoweredOff: Code { .accessoryPoweredOff }
    public static var accessoryResponseError: Code { .accessoryResponseError }
    public static var accessorySentInvalidResponse: Code { .accessorySentInvalidResponse }
    public static var actionInAnotherActionSet: Code { .actionInAnotherActionSet }
    public static var actionSetExecutionFailed: Code { .actionSetExecutionFailed }
    public static var actionSetExecutionInProgress: Code { .actionSetExecutionInProgress }
    public static var actionSetExecutionPartialSuccess: Code { .actionSetExecutionPartialSuccess }
    public static var addAccessoryFailed: Code { .addAccessoryFailed }
    public static var alreadyExists: Code { .alreadyExists }
    public static var bridgedAccessoryNotReachable: Code { .bridgedAccessoryNotReachable }
    public static var cannotActivateTriggerTooFarInFuture: Code { .cannotActivateTriggerTooFarInFuture }
    public static var cannotRemoveBuiltinActionSet: Code { .cannotRemoveBuiltinActionSet }
    public static var cannotRemoveNonBridgeAccessory: Code { .cannotRemoveNonBridgeAccessory }
    public static var cannotUnblockNonBridgeAccessory: Code { .cannotUnblockNonBridgeAccessory }
    public static var clientRequestError: Code { .clientRequestError }
    public static var cloudDataSyncInProgress: Code { .cloudDataSyncInProgress }
    public static var communicationFailure: Code { .communicationFailure }
    public static var dataResetFailure: Code { .dataResetFailure }
    public static var dateMustBeOnSpecifiedBoundaries: Code { .dateMustBeOnSpecifiedBoundaries }
    public static var deviceLocked: Code { .deviceLocked }
    public static var enterpriseNetworkNotSupported: Code { .enterpriseNetworkNotSupported }
    public static var failedToJoinNetwork: Code { .failedToJoinNetwork }
    public static var fireDateInPast: Code { .fireDateInPast }
    public static var genericError: Code { .genericError }
    public static var homeAccessNotAuthorized: Code { .homeAccessNotAuthorized }
    public static var homeUpgradeRequired: Code { .homeUpgradeRequired }
    public static var homeWithSimilarNameExists: Code { .homeWithSimilarNameExists }
    public static var incompatibleAccessory: Code { .incompatibleAccessory }
    public static var incompatibleNetwork: Code { .incompatibleNetwork }
    public static var insufficientPrivileges: Code { .insufficientPrivileges }
    public static var invalidAssociatedServiceType: Code { .invalidAssociatedServiceType }
    public static var invalidClass: Code { .invalidClass }
    public static var invalidDataFormatSpecified: Code { .invalidDataFormatSpecified }
    public static var invalidMessageSize: Code { .invalidMessageSize }
    public static var invalidOrMissingAuthorizationData: Code { .invalidOrMissingAuthorizationData }
    public static var invalidParameter: Code { .invalidParameter }
    public static var invalidValueType: Code { .invalidValueType }
    public static var keychainSyncNotEnabled: Code { .keychainSyncNotEnabled }
    public static var locationForHomeDisabled: Code { .locationForHomeDisabled }
    public static var maximumAccessoriesOfTypeInHome: Code { .maximumAccessoriesOfTypeInHome }
    public static var maximumObjectLimitReached: Code { .maximumObjectLimitReached }
    public static var messageAuthenticationFailed: Code { .messageAuthenticationFailed }
    public static var missingEntitlement: Code { .missingEntitlement }
    public static var missingParameter: Code { .missingParameter }
    public static var nameContainsProhibitedCharacters: Code { .nameContainsProhibitedCharacters }
    public static var nameDoesNotEndWithValidCharacters: Code { .nameDoesNotEndWithValidCharacters }
    public static var nameDoesNotStartWithValidCharacters: Code { .nameDoesNotStartWithValidCharacters }
    public static var networkUnavailable: Code { .networkUnavailable }
    public static var nilParameter: Code { .nilParameter }
    public static var noActionsInActionSet: Code { .noActionsInActionSet }
    public static var noCompatibleHomeHub: Code { .noCompatibleHomeHub }
    public static var noHomeHub: Code { .noHomeHub }
    public static var noRegisteredActionSets: Code { .noRegisteredActionSets }
    public static var notAuthorizedForLocationServices: Code { .notAuthorizedForLocationServices }
    public static var notAuthorizedForMicrophoneAccess: Code { .notAuthorizedForMicrophoneAccess }
    public static var notFound: Code { .notFound }
    public static var notSignedIntoiCloud: Code { .notSignedIntoiCloud }
    public static var notificationAlreadyEnabled: Code { .notificationAlreadyEnabled }
    public static var notificationNotSupported: Code { .notificationNotSupported }
    public static var objectAlreadyAssociatedToHome: Code { .objectAlreadyAssociatedToHome }
    public static var objectAssociatedToAnotherHome: Code { .objectAssociatedToAnotherHome }
    public static var objectNotAssociatedToAnyHome: Code { .objectNotAssociatedToAnyHome }
    public static var objectWithSimilarNameExists: Code { .objectWithSimilarNameExists }
    public static var objectWithSimilarNameExistsInHome: Code { .objectWithSimilarNameExistsInHome }
    public static var operationCancelled: Code { .operationCancelled }
    public static var operationInProgress: Code { .operationInProgress }
    public static var operationNotSupported: Code { .operationNotSupported }
    public static var operationTimedOut: Code { .operationTimedOut }
    public static var ownershipFailure: Code { .ownershipFailure }
    public static var partialCommunicationFailure: Code { .partialCommunicationFailure }
    public static var quotaExceeded: Code { .quotaExceeded }
    public static var readOnlyCharacteristic: Code { .readOnlyCharacteristic }
    public static var readWriteFailure: Code { .readWriteFailure }
    public static var readWritePartialSuccess: Code { .readWritePartialSuccess }
    public static var recurrenceMustBeOnSpecifiedBoundaries: Code { .recurrenceMustBeOnSpecifiedBoundaries }
    public static var recurrenceTooLarge: Code { .recurrenceTooLarge }
    public static var recurrenceTooSmall: Code { .recurrenceTooSmall }
    public static var referToUserManual: Code { .referToUserManual }
    public static var renameWithSimilarName: Code { .renameWithSimilarName }
    public static var roomForHomeCannotBeInZone: Code { .roomForHomeCannotBeInZone }
    public static var roomForHomeCannotBeUpdated: Code { .roomForHomeCannotBeUpdated }
    public static var securityFailure: Code { .securityFailure }
    public static var stringLongerThanMaximum: Code { .stringLongerThanMaximum }
    public static var stringShorterThanMinimum: Code { .stringShorterThanMinimum }
    public static var timedOutWaitingForAccessory: Code { .timedOutWaitingForAccessory }
    public static var unconfiguredParameter: Code { .unconfiguredParameter }
    public static var unexpectedError: Code { .unexpectedError }
    public static var userDeclinedAddingUser: Code { .userDeclinedAddingUser }
    public static var userDeclinedInvite: Code { .userDeclinedInvite }
    public static var userDeclinedRemovingUser: Code { .userDeclinedRemovingUser }
    public static var userIDNotEmailAddress: Code { .userIDNotEmailAddress }
    public static var userManagementFailed: Code { .userManagementFailed }
    public static var valueHigherThanMaximum: Code { .valueHigherThanMaximum }
    public static var valueLowerThanMinimum: Code { .valueLowerThanMinimum }
    public static var wiFiCredentialGenerationFailed: Code { .wiFiCredentialGenerationFailed }
    public static var writeOnlyCharacteristic: Code { .writeOnlyCharacteristic }
    public static var incompatibleHomeHub: Code { .noCompatibleHomeHub }

    public static func == (lhs: HMError, rhs: HMError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension HMError.Code {
    public static func ~= (match: HMError.Code, error: any Error) -> Bool {
        if let typed = error as? HMError { return typed.code == match }
        let ns = error as NSError
        return ns.domain == HMErrorDomain && ns.code == match.rawValue
    }
}

func HMMakeError(_ code: HMError.Code, reason: String? = nil) -> HMError {
    var info: [String: Any] = [:]
    if let reason {
        info[NSLocalizedDescriptionKey] = reason
    }
    return HMError(code, userInfo: info)
}

func HMFailClosed(_ code: HMError.Code = .homeAccessNotAuthorized) -> HMError {
    HMMakeError(
        code,
        reason: "HomeKit Apple Home / accessory / daemon APIs are unavailable on this Linux host"
    )
}

public typealias HMErrorBlock = ((any Error)?) -> Void

public struct HMHomeManagerAuthorizationStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let determined = HMHomeManagerAuthorizationStatus(rawValue: 1 << 0)
    public static let restricted = HMHomeManagerAuthorizationStatus(rawValue: 1 << 1)
    public static let authorized = HMHomeManagerAuthorizationStatus(rawValue: 1 << 2)
}

public struct HMSignificantEvent: Hashable, RawRepresentable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.init(rawValue: rawValue) }
    public static let sunrise = HMSignificantEvent(rawValue: "HMSignificantEventSunrise")
    public static let sunset = HMSignificantEvent(rawValue: "HMSignificantEventSunset")
}

