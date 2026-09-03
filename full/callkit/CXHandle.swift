import Foundation

public enum CXCallEndedReason: Int, Hashable, Sendable {
    case failed = 1
    case remoteEnded = 2
    case unanswered = 3
    case answeredElsewhere = 4
    case declinedElsewhere = 5
}

public enum CXTranslationEngine: Int, Hashable, Sendable {
    case `default` = 0
    case custom = 1
}

open class CXHandle: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public enum HandleType: Int, Hashable, Sendable {
        case generic = 1
        case phoneNumber = 2
        case emailAddress = 3
    }

    public let type: HandleType
    public let value: String

    public init(type: HandleType, value: String) {
        self.type = type
        self.value = value
        super.init()
    }

    public required init?(coder: NSCoder) {
        let raw = coder.decodeInteger(forKey: "type")
        guard let decodedType = HandleType(rawValue: raw) else { return nil }
        guard let decodedValue = coder.decodeObject(of: NSString.self, forKey: "value") as String? else {
            return nil
        }
        self.type = decodedType
        self.value = decodedValue
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(value as NSString, forKey: "value")
    }

    public static var supportsSecureCoding: Bool { true }

    open func copy(with zone: NSZone? = nil) -> Any {
        CXHandle(type: type, value: value)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CXHandle else { return false }
        return type == other.type && value == other.value
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(type)
        hasher.combine(value)
        return hasher.finalize()
    }
}

open class CXCallUpdate: NSObject, NSCopying, @unchecked Sendable {
    @NSCopying public var remoteHandle: CXHandle?
    public var localizedCallerName: String?
    public var hasVideo = false
    public var supportsDTMF = true
    public var supportsGrouping = true
    public var supportsHolding = true
    public var supportsUngrouping = true

    public override init() {
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXCallUpdate()
        copy.remoteHandle = remoteHandle?.copy() as? CXHandle
        copy.localizedCallerName = localizedCallerName
        copy.hasVideo = hasVideo
        copy.supportsDTMF = supportsDTMF
        copy.supportsGrouping = supportsGrouping
        copy.supportsHolding = supportsHolding
        copy.supportsUngrouping = supportsUngrouping
        return copy
    }
}
