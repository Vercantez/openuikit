import Foundation

/// Base class for ClassKit model objects.
///
/// `dateCreated` is stamped at construction. `dateLastModified` advances on
/// documented mutating APIs. Objects are `NSSecureCoding` so a process-local
/// archive round-trip is possible; that is not Apple Schoolwork persistence.
open class CLSObject: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var dateCreated: Date
    public private(set) var dateLastModified: Date

    @available(*, unavailable)
    public override init() {
        fatalError("CLSObject.init is unavailable")
    }

    init(portable: ()) {
        let now = Date()
        dateCreated = now
        dateLastModified = now
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let created = coder.decodeObject(of: NSDate.self, forKey: "dateCreated") as Date?,
            let modified = coder.decodeObject(of: NSDate.self, forKey: "dateLastModified") as Date?
        else {
            return nil
        }
        dateCreated = created
        dateLastModified = modified
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(dateCreated as NSDate, forKey: "dateCreated")
        coder.encode(dateLastModified as NSDate, forKey: "dateLastModified")
    }

    func touch() {
        dateLastModified = Date()
    }
}
