import Foundation

open class CXHandle: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public enum HandleType: Int, Equatable, Hashable, Sendable {
        case generic = 1
        case phoneNumber = 2
        case emailAddress = 3
    }

    public static var supportsSecureCoding: Bool { true }

    public let type: HandleType
    public let value: String

    public init(type: HandleType, value: String) {
        self.type = type
        self.value = value
        super.init()
    }

    public required init?(coder: NSCoder) {
        let raw = coder.decodeInteger(forKey: "type")
        guard let type = HandleType(rawValue: raw),
              let value = coder.decodeObject(of: NSString.self, forKey: "value") as String?
                ?? coder.decodeObject(forKey: "value") as? String
        else {
            return nil
        }
        self.type = type
        self.value = value
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(value as NSString, forKey: "value")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
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
