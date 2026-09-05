import Foundation

public protocol AXBrailleMapRenderer: NSObjectProtocol {
    var accessibilityBrailleMapRenderRegion: CGRect { get set }
    var accessibilityBrailleMapRenderer: (AXBrailleMap) -> Void { get set }
}

public class AXBrailleMap: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let dimensions: CGSize
    private var heights: [String: Float]

    public init(dimensions: CGSize) {
        self.dimensions = dimensions
        self.heights = [:]
        super.init()
    }

    public required init?(coder: NSCoder) {
        let width = coder.decodeDouble(forKey: "width")
        let height = coder.decodeDouble(forKey: "height")
        self.dimensions = CGSize(width: width, height: height)
        if let stored = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: "heights")
            as? [String: NSNumber]
        {
            var decoded: [String: Float] = [:]
            for (key, value) in stored {
                decoded[key] = value.floatValue
            }
            self.heights = decoded
        } else {
            self.heights = [:]
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Double(dimensions.width), forKey: "width")
        coder.encode(Double(dimensions.height), forKey: "height")
        var boxed: [String: NSNumber] = [:]
        for (key, value) in heights {
            boxed[key] = NSNumber(value: value)
        }
        coder.encode(boxed as NSDictionary, forKey: "heights")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AXBrailleMap(dimensions: dimensions)
        copy.heights = heights
        return copy
    }

    public func height(at point: CGPoint) -> Float {
        heights[Self.key(point)] ?? 0
    }

    public func setHeight(_ status: Float, at point: CGPoint) {
        heights[Self.key(point)] = status
    }

    public subscript(point: CGPoint) -> Float {
        get { height(at: point) }
        set { setHeight(newValue, at: point) }
    }

    /// No CoreGraphics bitmap decoder is available. Presenting an image is a
    /// no-op and does not invent cell heights.
    public func present(_ image: CGImage) {
        _ = image
    }

    private static func key(_ point: CGPoint) -> String {
        "\(point.x),\((point.y))"
    }
}

public class AXBrailleTable: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let identifier: String
    public let localizedName: String
    public let providerIdentifier: String
    public let localizedProviderName: String
    public let language: Locale.Language
    public let locales: Set<Locale>
    public let isEightDot: Bool

    public init?(identifier: String) {
        guard !identifier.isEmpty else { return nil }
        self.identifier = identifier
        self.localizedName = identifier
        self.providerIdentifier = ""
        self.localizedProviderName = ""
        self.language = Locale.Language(identifier: "und")
        self.locales = []
        self.isEightDot = false
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? else {
            return nil
        }
        self.identifier = identifier
        self.localizedName = (coder.decodeObject(of: NSString.self, forKey: "localizedName") as String?) ?? identifier
        self.providerIdentifier = (coder.decodeObject(of: NSString.self, forKey: "providerIdentifier") as String?) ?? ""
        self.localizedProviderName =
            (coder.decodeObject(of: NSString.self, forKey: "localizedProviderName") as String?) ?? ""
        let languageCode = (coder.decodeObject(of: NSString.self, forKey: "language") as String?) ?? "und"
        self.language = Locale.Language(identifier: languageCode)
        if let localeIds = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "locales") as? [String] {
            self.locales = Set(localeIds.map { Locale(identifier: $0) })
        } else {
            self.locales = []
        }
        self.isEightDot = coder.decodeBool(forKey: "isEightDot")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(localizedName as NSString, forKey: "localizedName")
        coder.encode(providerIdentifier as NSString, forKey: "providerIdentifier")
        coder.encode(localizedProviderName as NSString, forKey: "localizedProviderName")
        coder.encode((language.minimalIdentifier) as NSString, forKey: "language")
        coder.encode(Array(locales.map(\.identifier)) as NSArray, forKey: "locales")
        coder.encode(isEightDot, forKey: "isEightDot")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AXBrailleTable(identifier: identifier) ?? self
    }

    /// Apple's catalog of liblouis tables is not shipped. Empty set.
    public class func languageAgnosticTables() -> Set<AXBrailleTable> { [] }

    public class func supportedLocales() -> Set<Locale> { [] }

    public class func defaultTable(for locale: Locale) -> AXBrailleTable? {
        _ = locale
        return nil
    }

    public class func tables(for locale: Locale) -> Set<AXBrailleTable> {
        _ = locale
        return []
    }
}

public class AXBrailleTranslationResult: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let resultString: String
    private let locationMap: [Int]

    public init(resultString: String, locationMap: [Int] = []) {
        self.resultString = resultString
        self.locationMap = locationMap
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.resultString = (coder.decodeObject(of: NSString.self, forKey: "resultString") as String?) ?? ""
        if let numbers = coder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: "locationMap") as? [NSNumber] {
            self.locationMap = numbers.map(\.intValue)
        } else {
            self.locationMap = []
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(resultString as NSString, forKey: "resultString")
        coder.encode(locationMap.map { NSNumber(value: $0) } as NSArray, forKey: "locationMap")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        AXBrailleTranslationResult(resultString: resultString, locationMap: locationMap)
    }

    public func inputIndex(forResultIndex resultIndex: String.Index) -> String.Index? {
        let offset = resultString.distance(from: resultString.startIndex, to: resultIndex)
        guard offset >= 0, offset < locationMap.count else { return nil }
        let inputOffset = locationMap[offset]
        guard inputOffset >= 0 else { return nil }
        return resultString.startIndex
    }
}

public class AXBrailleTranslator: NSObject {
    public let brailleTable: AXBrailleTable

    public init(brailleTable: AXBrailleTable) {
        self.brailleTable = brailleTable
        super.init()
    }

    /// No liblouis tables are bundled. Translation does not invent braille.
    public func translatePrintText(_ printText: String) -> AXBrailleTranslationResult {
        _ = printText
        return AXBrailleTranslationResult(resultString: "")
    }

    public func backTranslateBraille(_ braille: String) -> AXBrailleTranslationResult {
        _ = braille
        return AXBrailleTranslationResult(resultString: "")
    }
}
