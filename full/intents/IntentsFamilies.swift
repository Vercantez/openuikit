// Operational Intents families: NSSecureCoding overlays, parameter identity,
// relevant-shortcut store, and documented NSUserActivity bridging keys.
//
// Apple's keyed-archive field names are not in the pinned public inputs
// (oracle: INIntent/INImage encode keys). Linux uses the OpenUIKit overlay
// identifiers below. INImage named:/imageData: store bytes or a catalog
// name and never decode a bitmap (fail-closed rendering).

/// Linux overlay keyed-archive identifiers. Apple's NSSecureCoding keys are
/// not in `reference/public-surface.tsv`.
enum INPortableArchive {
    static let versionKey = "OpenUIKit.Intents.archiveVersion"
    static let kindKey = "OpenUIKit.Intents.archiveKind"
    static let version: Int32 = 1
}

/// Documented Linux overlay keys for NSUserActivity Siri bridging.
/// Apple's userInfo keys are not in the pinned public inputs.
public enum INUserActivityOverlayKey {
    public static let suggestedInvocationPhrase = "OpenUIKit.Intents.suggestedInvocationPhrase"
    public static let persistentIdentifier = "OpenUIKit.Intents.persistentIdentifier"
    public static let interaction = "OpenUIKit.Intents.interaction"
    public static let eligibleForPrediction = "OpenUIKit.Intents.isEligibleForPrediction"
}

func inDecodeString(_ coder: NSCoder, _ key: String) -> String? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: NSString.self, forKey: key) as String?
}

func inDecodeData(_ coder: NSCoder, _ key: String) -> Data? {
    guard coder.containsValue(forKey: key) else { return nil }
    return coder.decodeObject(of: NSData.self, forKey: key) as Data?
}

extension INIntent: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode("INIntent", forKey: INPortableArchive.kindKey)
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(suggestedInvocationPhrase as NSString?, forKey: "suggestedInvocationPhrase")
        coder.encode(intentDescription as NSString?, forKey: "intentDescription")
    }
}

extension INIntentResponse: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode("INIntentResponse", forKey: INPortableArchive.kindKey)
    }
}

extension INInteraction: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(intent, forKey: "intent")
        coder.encode(intentResponse, forKey: "intentResponse")
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(Int64(direction.rawValue), forKey: "direction")
        coder.encode(groupIdentifier as NSString?, forKey: "groupIdentifier")
    }
}

extension INImage: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode("INImage", forKey: INPortableArchive.kindKey)
        coder.encode(imageData as NSData?, forKey: "imageData")
        coder.encode(namedImage as NSString?, forKey: "namedImage")
        coder.encode(imageURL?.absoluteString as NSString?, forKey: "imageURL")
    }
}

extension INSpeakableString: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(spokenPhrase as NSString, forKey: "spokenPhrase")
        coder.encode(pronunciationHint as NSString?, forKey: "pronunciationHint")
        coder.encode(vocabularyIdentifier as NSString?, forKey: "vocabularyIdentifier")
    }
}

extension INPersonHandle: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(value as NSString?, forKey: "value")
        coder.encode(Int64(type.rawValue), forKey: "type")
        coder.encode(label?.rawValue as NSString?, forKey: "label")
    }
}

extension INPerson: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(personHandle, forKey: "personHandle")
        coder.encode(displayName as NSString, forKey: "displayName")
        coder.encode(image, forKey: "image")
        coder.encode(contactIdentifier as NSString?, forKey: "contactIdentifier")
        coder.encode(customIdentifier as NSString?, forKey: "customIdentifier")
    }
}

extension INMediaItem: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(title as NSString?, forKey: "title")
        coder.encode(Int64(type.rawValue), forKey: "type")
        coder.encode(artwork, forKey: "artwork")
        coder.encode(artist as NSString?, forKey: "artist")
    }
}

extension INShortcut: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(intent, forKey: "intent")
    }
}
