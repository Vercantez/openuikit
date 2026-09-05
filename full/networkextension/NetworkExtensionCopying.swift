/// In-memory `NSCopying` helpers and a Linux overlay for `NSSecureCoding`.
///
/// Archive keys are OpenUIKit identifiers. They are not Apple's undocumented
/// NetworkExtension keyed-archive layout; an oracle probe is recorded for that.

func _NECopiedObject<T: NSCopying>(_ value: T?) -> T? {
    guard let value else { return nil }
    return value.copy(with: nil) as? T
}

func _NECopiedArray<T: NSCopying>(_ values: [T]?) -> [T]? {
    guard let values else { return nil }
    return values.map { value in
        guard let copied = value.copy(with: nil) as? T else {
            return value
        }
        return copied
    }
}

func _NECopiedDictionary(_ values: [String: Any]?) -> [String: Any]? {
    guard let values else { return nil }
    return values
}

enum _NEPortableArchive {
    static let versionKey = "OpenUIKit.NetworkExtension.archiveVersion"
    static let kindKey = "OpenUIKit.NetworkExtension.archiveKind"
    static let version: Int32 = 1

    static let plistClasses: [AnyClass] = [
        NSDictionary.self,
        NSArray.self,
        NSString.self,
        NSNumber.self,
        NSData.self,
        NSURL.self,
    ]
}

func _NEEncodeString(_ coder: NSCoder, _ key: String, _ value: String?) {
    if let value {
        coder.encode(value as NSString, forKey: key)
    }
}

func _NEEncodeData(_ coder: NSCoder, _ key: String, _ value: Data?) {
    if let value {
        coder.encode(value as NSData, forKey: key)
    }
}

func _NEEncodeURL(_ coder: NSCoder, _ key: String, _ value: URL?) {
    if let value {
        coder.encode(value as NSURL, forKey: key)
    }
}

func _NEEncodeBool(_ coder: NSCoder, _ key: String, _ value: Bool) {
    coder.encode(value, forKey: key)
}

func _NEEncodeInt64(_ coder: NSCoder, _ key: String, _ value: Int64) {
    coder.encode(value, forKey: key)
}

func _NEEncodeObject(_ coder: NSCoder, _ key: String, _ value: (any NSCoding)?) {
    if let value {
        coder.encode(value, forKey: key)
    }
}

func _NEDecodeString(_ coder: NSCoder, _ key: String) -> String? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: NSString.self, forKey: key) as String?
}

func _NEDecodeData(_ coder: NSCoder, _ key: String) -> Data? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: NSData.self, forKey: key) as Data?
}

func _NEDecodeURL(_ coder: NSCoder, _ key: String) -> URL? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: NSURL.self, forKey: key) as URL?
}

func _NEDecodeObject<T: NSObject & NSCoding>(_ type: T.Type, _ coder: NSCoder, _ key: String) -> T? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: type, forKey: key)
}

func _NEDecodePlistDictionary(_ coder: NSCoder, _ key: String) -> [String: Any]? {
    guard coder.containsValue(forKey: key) else { return nil }
    guard
        let object = coder.decodeObject(of: _NEPortableArchive.plistClasses, forKey: key)
            as? NSDictionary
    else {
        return nil
    }
    return object as? [String: Any]
}

func _NEEncodePlistDictionary(_ coder: NSCoder, _ key: String, _ value: [String: Any]?) {
    guard let value else { return }
    coder.encode(value as NSDictionary, forKey: key)
}

func _NEDecodeTypedArray(_ classes: [AnyClass], _ coder: NSCoder, _ key: String) -> Any? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: classes, forKey: key)
}

func _NEDecodeStringArray(_ coder: NSCoder, _ key: String) -> [String]? {
    guard coder.containsValue(forKey: key) else { return nil }
    guard
        let object = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: key)
            as? [String]
    else {
        return nil
    }
    return object
}

func _NEEncodeStringArray(_ coder: NSCoder, _ key: String, _ value: [String]?) {
    guard let value else { return }
    coder.encode(value as NSArray, forKey: key)
}

func _NERoundTripArchive<T: NSObject & NSSecureCoding>(_ value: T) throws -> T {
    let data = try NSKeyedArchiver.archivedData(
        withRootObject: value,
        requiringSecureCoding: true
    )
    guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
        throw _NEHostBoundary.vpnError(.configurationInvalid)
    }
    return restored
}

func _NERoundTripArchive(
    _ value: NSObject & NSSecureCoding,
    allowed: [AnyClass]
) throws -> Any {
    let data = try NSKeyedArchiver.archivedData(
        withRootObject: value,
        requiringSecureCoding: true
    )
    guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data)
    else {
        throw _NEHostBoundary.vpnError(.configurationInvalid)
    }
    return restored
}

enum _NESettingsValidation {
    static func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let number = Int(part) else { return false }
            return (0...255).contains(number)
        }
    }

    static func isIPv6(_ value: String) -> Bool {
        !value.isEmpty && value.contains(":")
    }

    static func requireMatchingCount(_ left: Int, _ right: Int) throws {
        guard left == right else {
            throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
        }
    }
}
