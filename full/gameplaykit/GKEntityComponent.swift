import Foundation

open class GKComponent: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public weak var entity: GKEntity?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder) else { return nil }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        GKLinuxArchive.encodeMarker(coder)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        GKComponent()
    }

    open func didAddToEntity() {}

    open func willRemoveFromEntity() {}

    open func update(deltaTime seconds: TimeInterval) {}
}

open class GKEntity: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private var storage: [GKComponent] = []

    public var components: [GKComponent] { storage }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder) else { return nil }
        super.init()
        let decoded = GKLinuxArchive.decodeObjectArray(
            coder,
            key: GKLinuxArchive.componentsKey,
            classes: [GKComponent.self]
        ) as [GKComponent]?
        guard let decoded else { return nil }
        for component in decoded {
            addComponent(component)
        }
    }

    open func encode(with coder: NSCoder) {
        GKLinuxArchive.encodeMarker(coder)
        coder.encode(storage as NSArray, forKey: GKLinuxArchive.componentsKey)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = GKEntity()
        for component in storage {
            if let cloned = component.copy() as? GKComponent {
                copy.addComponent(cloned)
            }
        }
        return copy
    }

    open func addComponent(_ component: GKComponent) {
        if let old = component.entity, old !== self {
            old.detach(component)
        }
        let componentType = type(of: component)
        let replaced = storage.filter { type(of: $0) == componentType && $0 !== component }
        for existing in replaced {
            detach(existing)
        }
        if !storage.contains(where: { $0 === component }) {
            storage.append(component)
        }
        component.entity = self
        component.didAddToEntity()
    }

    fileprivate func detach(_ component: GKComponent) {
        let present = storage.contains { $0 === component }
        storage.removeAll { $0 === component }
        if present {
            component.willRemoveFromEntity()
            if component.entity === self {
                component.entity = nil
            }
        }
    }

    open func removeComponent<ComponentType: GKComponent>(ofType componentClass: ComponentType.Type) {
        let matches = storage.compactMap { $0 as? ComponentType }
        for existing in matches {
            detach(existing)
        }
    }

    open func component<ComponentType: GKComponent>(ofType componentClass: ComponentType.Type) -> ComponentType? {
        storage.first { $0 is ComponentType } as? ComponentType
    }

    open func update(deltaTime seconds: TimeInterval) {
        for component in storage {
            component.update(deltaTime: seconds)
        }
    }
}

open class GKComponentSystem<ComponentType: GKComponent>: NSObject {
    public let componentClass: AnyClass
    private var storage: [ComponentType] = []

    public var components: [ComponentType] { storage }

    public init(componentClass cls: AnyClass) {
        self.componentClass = cls
        super.init()
    }

    open func addComponent(_ component: ComponentType) {
        if !storage.contains(where: { $0 === component }) {
            storage.append(component)
        }
    }

    open func addComponent(foundIn entity: GKEntity) {
        for component in entity.components {
            if let typed = component as? ComponentType {
                addComponent(typed)
            }
        }
    }

    open func removeComponent(_ component: ComponentType) {
        storage.removeAll { $0 === component }
    }

    open func removeComponent(foundIn entity: GKEntity) {
        storage.removeAll { component in
            entity.components.contains { $0 === component }
        }
    }

    open func update(deltaTime seconds: TimeInterval) {
        for component in storage {
            component.update(deltaTime: seconds)
        }
    }

    open subscript(idx: Int) -> ComponentType {
        storage[idx]
    }

    open func classForGenericArgument(at index: Int) -> AnyClass {
        componentClass
    }
}

open class GKState: NSObject {
    public internal(set) weak var stateMachine: GKStateMachine?

    public override init() {
        super.init()
    }

    open func isValidNextState(_ stateClass: AnyClass) -> Bool {
        true
    }

    open func didEnter(from previousState: GKState?) {}

    open func willExit(to nextState: GKState) {}

    open func update(deltaTime seconds: TimeInterval) {}
}

open class GKStateMachine: NSObject {
    private let states: [GKState]
    public private(set) var currentState: GKState?

    public init(states: [GKState]) {
        self.states = states
        super.init()
        for state in states {
            state.stateMachine = self
        }
    }

    open func state<StateType: GKState>(forClass stateClass: StateType.Type) -> StateType? {
        states.first { $0 is StateType } as? StateType
    }

    open func canEnterState(_ stateClass: AnyClass) -> Bool {
        guard states.contains(where: { type(of: $0) == stateClass }) else {
            return false
        }
        if let current = currentState {
            return current.isValidNextState(stateClass)
        }
        return true
    }

    open func enter(_ stateClass: AnyClass) -> Bool {
        guard let next = states.first(where: { type(of: $0) == stateClass }) else {
            return false
        }
        if let current = currentState {
            guard current.isValidNextState(stateClass) else { return false }
            if current === next { return true }
            current.willExit(to: next)
            let previous = current
            currentState = next
            next.didEnter(from: previous)
            return true
        }
        currentState = next
        next.didEnter(from: nil)
        return true
    }

    open func update(deltaTime sec: TimeInterval) {
        currentState?.update(deltaTime: sec)
    }
}

public protocol GKSceneRootNodeType: NSObjectProtocol {}

open class GKScene: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private var entityStorage: [GKEntity] = []
    private var graphStorage: [String: GKGraph] = [:]

    public var entities: [GKEntity] { entityStorage }
    public var graphs: [String: GKGraph] { graphStorage }
    public var rootNode: (any GKSceneRootNodeType)?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder) else { return nil }
        super.init()
        let decodedEntities = GKLinuxArchive.decodeObjectArray(
            coder,
            key: GKLinuxArchive.entitiesKey,
            classes: [GKEntity.self, GKComponent.self]
        ) as [GKEntity]?
        guard let decodedEntities else { return nil }
        entityStorage = decodedEntities
        let names = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: GKLinuxArchive.graphNamesKey) as? [NSString]
        let decodedGraphs = GKLinuxArchive.decodeObjectArray(
            coder,
            key: GKLinuxArchive.graphsKey,
            classes: [GKGraph.self, GKGraphNode.self, GKGraphNode2D.self, GKGraphNode3D.self, GKGridGraphNode.self]
        ) as [GKGraph]?
        if let names, let decodedGraphs, names.count == decodedGraphs.count {
            for (name, graph) in zip(names, decodedGraphs) {
                graphStorage[name as String] = graph
            }
        } else if names != nil || decodedGraphs != nil {
            return nil
        }
    }

    open func encode(with coder: NSCoder) {
        GKLinuxArchive.encodeMarker(coder)
        coder.encode(entityStorage as NSArray, forKey: GKLinuxArchive.entitiesKey)
        let names = graphStorage.keys.sorted().map { $0 as NSString }
        let graphs = names.compactMap { graphStorage[$0 as String] }
        coder.encode(names as NSArray, forKey: GKLinuxArchive.graphNamesKey)
        coder.encode(graphs as NSArray, forKey: GKLinuxArchive.graphsKey)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = GKScene()
        for entity in entityStorage {
            if let cloned = entity.copy() as? GKEntity {
                copy.entityStorage.append(cloned)
            }
        }
        for (name, graph) in graphStorage {
            if let cloned = graph.copy() as? GKGraph {
                copy.graphStorage[name] = cloned
            }
        }
        copy.rootNode = rootNode
        return copy
    }

    public convenience init?(fileNamed filename: String) {
        // Apple `.gkscene` archives are not documented in the pinned corpus.
        nil
    }

    public convenience init?(fileNamed filename: String, rootNode: any GKSceneRootNodeType) {
        nil
    }

    open func addEntity(_ entity: GKEntity) {
        if !entityStorage.contains(where: { $0 === entity }) {
            entityStorage.append(entity)
        }
    }

    open func removeEntity(_ entity: GKEntity) {
        entityStorage.removeAll { $0 === entity }
    }

    open func addGraph(_ graph: GKGraph, name: String) {
        graphStorage[name] = graph
    }

    open func removeGraph(_ name: String) {
        graphStorage.removeValue(forKey: name)
    }
}
