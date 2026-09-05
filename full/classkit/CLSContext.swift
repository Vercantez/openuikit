import Foundation

/// A node in an app's ClassKit context hierarchy.
///
/// Hierarchy, navigation children, active/resign, progress-reporting
/// capabilities, and `createNewActivity()` are process-local. Thumbnail
/// (`CGImage`) is not declared: CoreGraphics is not a seeded dependency.
open class CLSContext: CLSObject {
    public private(set) var identifier: String
    public private(set) var type: CLSContextType

    public var title: String {
        didSet { touch() }
    }

    public var customTypeName: String? {
        didSet { touch() }
    }

    public var summary: String? {
        didSet { touch() }
    }

    public var topic: CLSContextTopic? {
        didSet { touch() }
    }

    public var universalLinkURL: URL? {
        didSet { touch() }
    }

    public var displayOrder: Int = 0 {
        didSet { touch() }
    }

    public var isAssignable: Bool = false {
        didSet { touch() }
    }

    public var suggestedAge: NSRange = NSRange(location: 0, length: 0) {
        didSet { touch() }
    }

    public var suggestedCompletionTime: NSRange = NSRange(location: 0, length: 0) {
        didSet { touch() }
    }

    public internal(set) var isActive: Bool = false
    public private(set) var currentActivity: CLSActivity?
    public private(set) var progressReportingCapabilities: Set<CLSProgressReportingCapability> = []
    public private(set) var navigationChildContexts: [CLSContext] = []

    public internal(set) weak var parent: CLSContext?
    weak var store: CLSDataStore?
    var isMainAppContext = false
    private var children: [CLSContext] = []

    /// Identifier path from the main app context, excluding the main app
    /// context itself. A parentless non-app context reports `[identifier]`.
    public var identifierPath: [String] {
        var parts: [String] = []
        var node: CLSContext? = self
        while let current = node {
            if current.isMainAppContext { break }
            parts.append(current.identifier)
            node = current.parent
        }
        return parts.reversed()
    }

    public init(type: CLSContextType, identifier: String, title: String) {
        self.type = type
        self.identifier = identifier
        self.title = title
        super.init(portable: ())
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
            let title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        else {
            return nil
        }
        self.identifier = identifier
        self.title = title
        let rawType = coder.decodeInteger(forKey: "type")
        self.type = CLSContextType(rawValue: rawType) ?? .none
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(title as NSString, forKey: "title")
        coder.encode(type.rawValue, forKey: "type")
    }

    public func setType(_ type: CLSContextType) {
        self.type = type
        if type != .custom {
            customTypeName = nil
        }
        touch()
    }

    public func becomeActive() {
        store?.activate(self)
        isActive = true
        touch()
    }

    public func resignActive() {
        isActive = false
        if store?.activeContext === self {
            store?.activeContext = nil
        }
        touch()
    }

    public func addChildContext(_ child: CLSContext) {
        if child.parent === self { return }
        if child.parent != nil { return }
        if child === self { return }
        if nestingDepthFromMain >= 8 { return }
        if children.contains(where: { $0.identifier == child.identifier }) { return }
        child.parent = self
        child.store = store
        children.append(child)
        touch()
    }

    public func removeFromParent() {
        guard let parent else { return }
        parent.children.removeAll { $0 === self }
        if parent.navigationChildContexts.contains(where: { $0 === self }) {
            parent.navigationChildContexts.removeAll { $0 === self }
        }
        self.parent = nil
        parent.touch()
        touch()
    }

    public func addNavigationChildContext(_ child: CLSContext) {
        guard !navigationChildContexts.contains(where: { $0 === child }) else { return }
        navigationChildContexts.append(child)
        touch()
    }

    public func removeNavigationChildContext(_ child: CLSContext) {
        let before = navigationChildContexts.count
        navigationChildContexts.removeAll { $0 === child }
        if navigationChildContexts.count != before {
            touch()
        }
    }

    public func addProgressReportingCapabilities(_ capabilities: Set<CLSProgressReportingCapability>) {
        progressReportingCapabilities.formUnion(capabilities)
        touch()
    }

    public func resetProgressReportingCapabilities() {
        progressReportingCapabilities.removeAll()
        touch()
    }

    public func createNewActivity() -> CLSActivity {
        if let current = currentActivity, current.isStarted {
            current.stop()
        }
        let activity = CLSActivity(portable: ())
        activity.owningContext = self
        currentActivity = activity
        touch()
        return activity
    }

    /// Walk descendants by identifier path. Missing nodes fail with
    /// `invalidArgument`. This is the process-local tree, not Schoolwork.
    public func descendant(matchingIdentifierPath identifierPath: [String]) async throws -> CLSContext {
        try descendantMatchingIdentifierPathSync(identifierPath)
    }

    func descendantMatchingIdentifierPathSync(_ identifierPath: [String]) throws -> CLSContext {
        if identifierPath.isEmpty {
            throw CLSMakeError(.invalidArgument)
        }
        var current = self
        for identifier in identifierPath {
            guard let next = current.children.first(where: { $0.identifier == identifier }) else {
                throw CLSMakeError(.invalidArgument)
            }
            current = next
        }
        return current
    }

    func child(identifiedBy identifier: String) -> CLSContext? {
        children.first(where: { $0.identifier == identifier })
    }

    func collectDescendants() -> [CLSContext] {
        var result: [CLSContext] = []
        var queue = children
        while !queue.isEmpty {
            let node = queue.removeFirst()
            result.append(node)
            queue.append(contentsOf: node.children)
        }
        return result
    }

    func valueForPredicateKey(_ key: String) -> Any? {
        switch key {
        case CLSPredicateKeyPath.dateCreated.rawValue:
            return dateCreated
        case CLSPredicateKeyPath.identifier.rawValue:
            return identifier
        case CLSPredicateKeyPath.parent.rawValue:
            return parent
        case CLSPredicateKeyPath.title.rawValue:
            return title
        case CLSPredicateKeyPath.topic.rawValue:
            return topic?.rawValue
        case CLSPredicateKeyPath.universalLinkURL.rawValue:
            return universalLinkURL
        default:
            return nil
        }
    }

    private var nestingDepthFromMain: Int {
        var depth = 0
        var node: CLSContext? = self
        while let current = node {
            if current.isMainAppContext { return depth }
            depth += 1
            node = current.parent
        }
        return depth
    }
}
