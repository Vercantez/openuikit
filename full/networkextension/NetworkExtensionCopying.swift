/// In-memory `NSCopying` helpers for NetworkExtension configuration objects.
///
/// `NSCoding` / `NSSecureCoding` are a named deferred blocker: isolated Linux
/// Foundation does not provide `NSCoder`, `NSKeyedArchiver`, or
/// `NSSecureCoding`. This module never claims archive round-trips. Coverage
/// for those protocol relationships stays deferred at the conformance
/// description; public-surface IDs do not include `copy(with:)`.

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
