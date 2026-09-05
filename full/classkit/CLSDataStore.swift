import Foundation

/// Creates missing contexts while resolving an identifier path.
public protocol CLSDataStoreDelegate: NSObjectProtocol {
    func createContext(
        forIdentifier identifier: String,
        parentContext: CLSContext,
        parentIdentifierPath: [String]
    ) -> CLSContext?
}

/// Supplies descendant contexts for an existing parent.
public protocol CLSContextProvider {
    func updateDescendants(of context: CLSContext) async throws
}

/// Process-local ClassKit data store.
///
/// The in-memory hierarchy, active context, and running activity are real.
/// `save` fail-closes: Linux has no ClassKit daemon, Schoolwork account, or
/// education entitlement. `fetchActivity(for:)` likewise fail-closes.
open class CLSDataStore: NSObject {
    private static var sharedStorage = CLSDataStore()

    public class var shared: CLSDataStore { sharedStorage }

    public let mainAppContext: CLSContext
    public internal(set) weak var activeContext: CLSContext?
    public internal(set) weak var runningActivity: CLSActivity?
    public weak var delegate: (any CLSDataStoreDelegate)?

    private override init() {
        let identifier = Bundle.main.bundleIdentifier ?? "main"
        mainAppContext = CLSContext(type: .app, identifier: identifier, title: identifier)
        mainAppContext.isMainAppContext = true
        super.init()
        mainAppContext.store = self
    }

    /// Replace the process-local shared store. Not an Apple API.
    public static func portableResetShared() {
        sharedStorage = CLSDataStore()
    }

    func activate(_ context: CLSContext) {
        if let current = activeContext, current !== context {
            current.isActive = false
        }
        activeContext = context
        context.store = self
    }

    public func completeAllAssignedActivities(matching contextPath: [String]) {
        // No Schoolwork assignment graph exists on Linux. Completing nothing
        // is the honest no-op; success of an Apple assignment is not invented.
        _ = contextPath
    }

    /// Process-local identifier-path walk. Missing components ask the delegate
    /// to create them. This is not Apple Schoolwork lookup.
    public func portableContexts(matchingIdentifierPath identifierPath: [String]) throws -> [CLSContext] {
        try contextsMatchingIdentifierPathSync(identifierPath)
    }

    public func contexts(matchingIdentifierPath identifierPath: [String]) async throws -> [CLSContext] {
        try contextsMatchingIdentifierPathSync(identifierPath)
    }

    public func contexts(matching predicate: NSPredicate) async throws -> [CLSContext] {
        contextsMatchingPredicateSync(predicate)
    }

    public func fetchActivity(for url: URL) async throws -> CLSActivity {
        _ = url
        throw CLSMakeError(.classKitUnavailable)
    }

    public func remove(_ context: CLSContext) {
        if context.isMainAppContext { return }
        context.removeFromParent()
        if activeContext === context {
            context.resignActive()
        }
    }

    /// Fail-closed: there is no ClassKit daemon to persist into.
    /// The completion runs before this method returns.
    public func save(completion: (((any Error)?) -> Void)? = nil) {
        completion?(CLSMakeError(.classKitUnavailable))
    }

    func contextsMatchingIdentifierPathSync(_ identifierPath: [String]) throws -> [CLSContext] {
        if identifierPath.isEmpty {
            return [mainAppContext]
        }
        var current = mainAppContext
        var resolved: [CLSContext] = []
        var parentPath: [String] = []
        for identifier in identifierPath {
            if let existing = current.child(identifiedBy: identifier) {
                current = existing
                resolved.append(current)
                parentPath.append(identifier)
                continue
            }
            if let created = delegate?.createContext(
                forIdentifier: identifier,
                parentContext: current,
                parentIdentifierPath: parentPath
            ) {
                current.addChildContext(created)
                guard let attached = current.child(identifiedBy: identifier) else {
                    throw CLSMakeError(.invalidCreate)
                }
                current = attached
                resolved.append(current)
                parentPath.append(identifier)
                continue
            }
            throw CLSMakeError(.invalidArgument)
        }
        return resolved
    }

    func contextsMatchingPredicateSync(_ predicate: NSPredicate) -> [CLSContext] {
        let nodes = [mainAppContext] + mainAppContext.collectDescendants()
        return nodes.filter { predicate.evaluate(with: $0) }
    }
}
