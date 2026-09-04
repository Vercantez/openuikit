// Generated Intents string-wrapper values and nested types.

public struct INPersonRelationship: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct INWorkoutNameIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct INIntentError: Error, Hashable {
    public enum Code: Int, Hashable, Sendable {
        case decodingGeneric
        case deletingAllInteractions
        case deletingInteractionWithGroupIdentifier
        case deletingInteractionWithIdentifiers
        case donatingInteraction
        case encodingFailed
        case encodingGeneric
        case extensionBringUpFailed
        case extensionLaunchingTimeout
        case imageGeneric
        case imageLoadingFailed
        case imageNoServiceAvailable
        case imageProxyInvalid
        case imageProxyLoop
        case imageProxyTimeout
        case imageRetrievalFailed
        case imageScalingFailed
        case imageServiceFailure
        case imageStorageFailed
        case intentSupportedByMultipleExtension
        case interactionOperationNotSupported
        case invalidIntentName
        case invalidUserVocabularyFileLocation
        case missingInformation
        case noAppAvailable
        case noAppIntent
        case noHandlerProvidedForIntent
        case permissionDenied
        case requestTimedOut
        case restrictedIntentsNotSupportedByExtension
        case unableToCreateAppIntentRepresentation
        case voiceShortcutCreationFailed
        case voiceShortcutDeleteFailed
        case voiceShortcutGetFailed
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { INIntentErrorDomain }
    public var errorDomain: String { Self.errorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String {
        "\(Self.errorDomain) \(code.rawValue)"
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    public static func == (lhs: INIntentError, rhs: INIntentError) -> Bool {
        lhs.code == rhs.code
    }
}

extension INIntentError.Code {
    public static func ~= (match: INIntentError.Code, error: any Error) -> Bool {
        (error as? INIntentError)?.code == match
    }
}

extension INIntentError { public static var noAppIntent: Code { .noAppIntent } }
extension INIntentError { public static var imageGeneric: Code { .imageGeneric } }
extension INIntentError { public static var encodingFailed: Code { .encodingFailed } }
extension INIntentError { public static var imageProxyLoop: Code { .imageProxyLoop } }
extension INIntentError { public static var noAppAvailable: Code { .noAppAvailable } }
extension INIntentError { public static var decodingGeneric: Code { .decodingGeneric } }
extension INIntentError { public static var encodingGeneric: Code { .encodingGeneric } }
extension INIntentError { public static var requestTimedOut: Code { .requestTimedOut } }
extension INIntentError { public static var permissionDenied: Code { .permissionDenied } }
extension INIntentError { public static var imageProxyInvalid: Code { .imageProxyInvalid } }
extension INIntentError { public static var imageProxyTimeout: Code { .imageProxyTimeout } }
extension INIntentError { public static var invalidIntentName: Code { .invalidIntentName } }
extension INIntentError { public static var imageLoadingFailed: Code { .imageLoadingFailed } }
extension INIntentError { public static var imageScalingFailed: Code { .imageScalingFailed } }
extension INIntentError { public static var imageStorageFailed: Code { .imageStorageFailed } }
extension INIntentError { public static var missingInformation: Code { .missingInformation } }
extension INIntentError { public static var donatingInteraction: Code { .donatingInteraction } }
extension INIntentError { public static var imageServiceFailure: Code { .imageServiceFailure } }
extension INIntentError { public static var imageRetrievalFailed: Code { .imageRetrievalFailed } }
extension INIntentError { public static var extensionBringUpFailed: Code { .extensionBringUpFailed } }
extension INIntentError { public static var voiceShortcutGetFailed: Code { .voiceShortcutGetFailed } }
extension INIntentError { public static var deletingAllInteractions: Code { .deletingAllInteractions } }
extension INIntentError { public static var imageNoServiceAvailable: Code { .imageNoServiceAvailable } }
extension INIntentError { public static var extensionLaunchingTimeout: Code { .extensionLaunchingTimeout } }
extension INIntentError { public static var voiceShortcutDeleteFailed: Code { .voiceShortcutDeleteFailed } }
extension INIntentError { public static var noHandlerProvidedForIntent: Code { .noHandlerProvidedForIntent } }
extension INIntentError { public static var voiceShortcutCreationFailed: Code { .voiceShortcutCreationFailed } }
extension INIntentError { public static var interactionOperationNotSupported: Code { .interactionOperationNotSupported } }
extension INIntentError { public static var invalidUserVocabularyFileLocation: Code { .invalidUserVocabularyFileLocation } }
extension INIntentError { public static var deletingInteractionWithIdentifiers: Code { .deletingInteractionWithIdentifiers } }
extension INIntentError { public static var intentSupportedByMultipleExtension: Code { .intentSupportedByMultipleExtension } }
extension INIntentError { public static var unableToCreateAppIntentRepresentation: Code { .unableToCreateAppIntentRepresentation } }
extension INIntentError { public static var deletingInteractionWithGroupIdentifier: Code { .deletingInteractionWithGroupIdentifier } }
extension INIntentError { public static var restrictedIntentsNotSupportedByExtension: Code { .restrictedIntentsNotSupportedByExtension } }
extension INPersonRelationship { public static let assistant = INPersonRelationship(rawValue: "assistant") }
extension INPersonRelationship { public static let brother = INPersonRelationship(rawValue: "brother") }
extension INPersonRelationship { public static let child = INPersonRelationship(rawValue: "child") }
extension INPersonRelationship { public static let daughter = INPersonRelationship(rawValue: "daughter") }
extension INPersonRelationship { public static let father = INPersonRelationship(rawValue: "father") }
extension INPersonRelationship { public static let friend = INPersonRelationship(rawValue: "friend") }
extension INPersonRelationship { public static let manager = INPersonRelationship(rawValue: "manager") }
extension INPersonRelationship { public static let mother = INPersonRelationship(rawValue: "mother") }
extension INPersonRelationship { public static let parent = INPersonRelationship(rawValue: "parent") }
extension INPersonRelationship { public static let partner = INPersonRelationship(rawValue: "partner") }
extension INPersonRelationship { public static let sister = INPersonRelationship(rawValue: "sister") }
extension INPersonRelationship { public static let son = INPersonRelationship(rawValue: "son") }
extension INPersonRelationship { public static let spouse = INPersonRelationship(rawValue: "spouse") }
extension INWorkoutNameIdentifier { public static let crosstraining = INWorkoutNameIdentifier(rawValue: "crosstraining") }
extension INWorkoutNameIdentifier { public static let cycle = INWorkoutNameIdentifier(rawValue: "cycle") }
extension INWorkoutNameIdentifier { public static let dance = INWorkoutNameIdentifier(rawValue: "dance") }
extension INWorkoutNameIdentifier { public static let elliptical = INWorkoutNameIdentifier(rawValue: "elliptical") }
extension INWorkoutNameIdentifier { public static let exercise = INWorkoutNameIdentifier(rawValue: "exercise") }
extension INWorkoutNameIdentifier { public static let highIntensityIntervalTraining = INWorkoutNameIdentifier(rawValue: "highIntensityIntervalTraining") }
extension INWorkoutNameIdentifier { public static let hike = INWorkoutNameIdentifier(rawValue: "hike") }
extension INWorkoutNameIdentifier { public static let indoorcycle = INWorkoutNameIdentifier(rawValue: "indoorcycle") }
extension INWorkoutNameIdentifier { public static let indoorrun = INWorkoutNameIdentifier(rawValue: "indoorrun") }
extension INWorkoutNameIdentifier { public static let indoorwalk = INWorkoutNameIdentifier(rawValue: "indoorwalk") }
extension INWorkoutNameIdentifier { public static let move = INWorkoutNameIdentifier(rawValue: "move") }
extension INWorkoutNameIdentifier { public static let other = INWorkoutNameIdentifier(rawValue: "other") }
extension INWorkoutNameIdentifier { public static let rower = INWorkoutNameIdentifier(rawValue: "rower") }
extension INWorkoutNameIdentifier { public static let run = INWorkoutNameIdentifier(rawValue: "run") }
extension INWorkoutNameIdentifier { public static let sit = INWorkoutNameIdentifier(rawValue: "sit") }
extension INWorkoutNameIdentifier { public static let stairs = INWorkoutNameIdentifier(rawValue: "stairs") }
extension INWorkoutNameIdentifier { public static let stand = INWorkoutNameIdentifier(rawValue: "stand") }
extension INWorkoutNameIdentifier { public static let steps = INWorkoutNameIdentifier(rawValue: "steps") }
extension INWorkoutNameIdentifier { public static let swim = INWorkoutNameIdentifier(rawValue: "swim") }
extension INWorkoutNameIdentifier { public static let walk = INWorkoutNameIdentifier(rawValue: "walk") }
extension INWorkoutNameIdentifier { public static let yoga = INWorkoutNameIdentifier(rawValue: "yoga") }
