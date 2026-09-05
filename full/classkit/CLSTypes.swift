import Foundation

/// Outcome vocabulary for `CLSBinaryItem`.
///
/// Raw values follow the pinned `dotnet/macios` `CLSBinaryValueType` order
/// (`trueFalse = 0` through `correctIncorrect = 3`).
public enum CLSBinaryValueType: Int, Hashable, Sendable {
    case trueFalse = 0
    case passFail = 1
    case yesNo = 2
    case correctIncorrect = 3
}

/// Curriculum node kinds for `CLSContext`.
///
/// Raw values follow the pinned `dotnet/macios` `CLSContextType` order
/// (`none = 0` through `custom = 17`).
public enum CLSContextType: Int, Hashable, Sendable {
    case none = 0
    case app = 1
    case chapter = 2
    case section = 3
    case level = 4
    case page = 5
    case task = 6
    case challenge = 7
    case quiz = 8
    case exercise = 9
    case lesson = 10
    case book = 11
    case game = 12
    case document = 13
    case audio = 14
    case video = 15
    case course = 16
    case custom = 17
}

/// Extensible topic tags for a context.
///
/// String payloads use the ObjC constant names (`CLSContextTopicMath`, …).
/// Those names are the NS_TYPED_EXTENSIBLE_ENUM convention; the Darwin
/// runtime bytes are not in the sealed headers and remain an oracle question.
public struct CLSContextTopic: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let math = CLSContextTopic(rawValue: "CLSContextTopicMath")
    public static let science = CLSContextTopic(rawValue: "CLSContextTopicScience")
    public static let literacyAndWriting = CLSContextTopic(rawValue: "CLSContextTopicLiteracyAndWriting")
    public static let worldLanguage = CLSContextTopic(rawValue: "CLSContextTopicWorldLanguage")
    public static let socialScience = CLSContextTopic(rawValue: "CLSContextTopicSocialScience")
    public static let computerScienceAndEngineering = CLSContextTopic(rawValue: "CLSContextTopicComputerScienceAndEngineering")
    public static let artsAndMusic = CLSContextTopic(rawValue: "CLSContextTopicArtsAndMusic")
    public static let healthAndFitness = CLSContextTopic(rawValue: "CLSContextTopicHealthAndFitness")
}

/// Keys into `CLSError.userInfo`.
///
/// String payloads use the ObjC constant names. Darwin runtime bytes are not
/// in the sealed headers.
public struct CLSErrorUserInfoKey: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let objectKey = CLSErrorUserInfoKey("CLSErrorObjectKey")
    public static let successfulObjectsKey = CLSErrorUserInfoKey("CLSErrorSuccessfulObjectsKey")
    public static let underlyingErrorsKey = CLSErrorUserInfoKey("CLSErrorUnderlyingErrorsKey")
}

/// Key paths used to build `NSPredicate` queries against `CLSContext`.
///
/// Payloads are the public property names so process-local predicate matching
/// can evaluate them. Darwin `CLSPredicateKeyPath*` NSString bytes are not in
/// the sealed headers and remain an oracle question.
public struct CLSPredicateKeyPath: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let dateCreated = CLSPredicateKeyPath("dateCreated")
    public static let identifier = CLSPredicateKeyPath("identifier")
    public static let parent = CLSPredicateKeyPath("parent")
    public static let title = CLSPredicateKeyPath("title")
    public static let topic = CLSPredicateKeyPath("topic")
    public static let universalLinkURL = CLSPredicateKeyPath("universalLinkURL")
}
