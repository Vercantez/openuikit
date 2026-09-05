import Foundation

public typealias AXCustomContentReturnBlock = () -> [AXCustomContent]?

public protocol AXCustomContentProvider: NSObjectProtocol {
    var accessibilityCustomContent: [AXCustomContent]! { get set }
    var accessibilityCustomContentBlock: AXCustomContentReturnBlock? { get set }
}

public class AXCustomContent: NSObject, NSCopying, NSSecureCoding {
    public enum Importance: UInt, Equatable, Hashable, Sendable {
        case `default` = 0
        case high = 1
    }

    public static var supportsSecureCoding: Bool { true }

    public let label: String
    public let value: String
    public let attributedLabel: NSAttributedString
    public let attributedValue: NSAttributedString
    public var importance: Importance

    public convenience init(label: String, value: String) {
        self.init(
            attributedLabel: NSAttributedString(string: label),
            attributedValue: NSAttributedString(string: value)
        )
    }

    public init(attributedLabel label: NSAttributedString, attributedValue value: NSAttributedString) {
        self.attributedLabel = NSAttributedString(attributedString: label)
        self.attributedValue = NSAttributedString(attributedString: value)
        self.label = label.string
        self.value = value.string
        self.importance = .default
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let label = coder.decodeObject(of: NSString.self, forKey: "label") as String?,
            let value = coder.decodeObject(of: NSString.self, forKey: "value") as String?
        else {
            return nil
        }
        self.label = label
        self.value = value
        self.attributedLabel = NSAttributedString(string: label)
        self.attributedValue = NSAttributedString(string: value)
        let raw = coder.decodeInteger(forKey: "importance")
        self.importance = Importance(rawValue: UInt(raw)) ?? .default
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(label as NSString, forKey: "label")
        coder.encode(value as NSString, forKey: "value")
        coder.encode(Int(importance.rawValue), forKey: "importance")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AXCustomContent(attributedLabel: attributedLabel, attributedValue: attributedValue)
        copy.importance = importance
        return copy
    }
}
