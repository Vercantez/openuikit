import Foundation

/// Capability advertised on a context for progress reporting.
open class CLSProgressReportingCapability: CLSObject {
    public enum Kind: Int, Hashable, Sendable {
        case duration = 0
        case percent = 1
        case binary = 2
        case quantity = 3
        case score = 4
    }

    public private(set) var kind: Kind
    public private(set) var details: String?

    public init(kind: Kind, details: String?) {
        self.kind = kind
        self.details = details
        super.init(portable: ())
    }

    public required init?(coder: NSCoder) {
        let raw = coder.decodeInteger(forKey: "kind")
        kind = Kind(rawValue: raw) ?? .duration
        details = coder.decodeObject(of: NSString.self, forKey: "details") as String?
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(kind.rawValue, forKey: "kind")
        if let details {
            coder.encode(details as NSString, forKey: "details")
        }
    }
}
