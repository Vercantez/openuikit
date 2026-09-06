import Foundation

public final class LayerHierarchyHandle: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public static func host_makeInert() -> LayerHierarchyHandle {
        LayerHierarchyHandle()
    }

    private override init() {
        super.init()
    }

    public init(port: mach_port_t, data: Data) throws {
        _ = port
        _ = data
        super.init()
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    public init(xpcRepresentation: xpc_object_t?) throws {
        _ = xpcRepresentation
        super.init()
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func createXPCRepresentation() -> xpc_object_t {
        BEHostXPCObject()
    }

    /// No mach port exists to copy. The block is not invoked.
    public func encode(_ block: (mach_port_t, Data) -> Void) {
        _ = block
    }
}

public final class LayerHierarchy {
    public let handle: LayerHierarchyHandle
    public var layer: CALayer?
    public private(set) var isInvalidated = false

    public static func host_makeInert() -> LayerHierarchy {
        LayerHierarchy(handle: LayerHierarchyHandle.host_makeInert())
    }

    public init() throws {
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    private init(handle: LayerHierarchyHandle) {
        self.handle = handle
    }

    public func invalidate() {
        isInvalidated = true
        layer = nil
    }
}

public final class LayerHierarchyHostingView: UIView, @unchecked Sendable {
    public var handle: LayerHierarchyHandle?

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }
}

public final class LayerHierarchyHostingTransactionCoordinator {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var addedHierarchies: [LayerHierarchy] = []
    public private(set) var addedViews: [LayerHierarchyHostingView] = []
    public private(set) var isCommitted = false

    public static func host_makeInert() -> LayerHierarchyHostingTransactionCoordinator {
        LayerHierarchyHostingTransactionCoordinator(inert: true)
    }

    public init() throws {
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    public init(port: mach_port_t, data: Data) throws {
        _ = port
        _ = data
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    public init(xpcRepresentation: xpc_object_t?) throws {
        _ = xpcRepresentation
        throw BrowserEngineKitHostError.layerHierarchyUnavailable
    }

    public init?(coder: NSCoder) {
        _ = coder
    }

    private init(inert: Bool) {
        _ = inert
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func add(_ layerHierarchy: LayerHierarchy) {
        addedHierarchies.append(layerHierarchy)
    }

    public func add(_ hostingView: LayerHierarchyHostingView) {
        addedViews.append(hostingView)
    }

    public func commit() {
        isCommitted = true
    }

    public func createXPCRepresentation() -> xpc_object_t {
        BEHostXPCObject()
    }

    public func encode(_ block: (mach_port_t, Data) -> Void) {
        _ = block
    }
}
