// SwiftUI S2: state, bindings, and observation for the OpenUIKit host.
//
// The reactive declarations come from exactly one platform Combine identity:
// Apple's first-party module on Darwin, or the package's literal Combine shim
// backed by pinned OpenCombine on Linux. Do not define lookalike
// implementations here.

@_exported import Combine
import OpenUIKit

// These source-facing declarations deliberately are not globally
// @MainActor-isolated. Apple's SwiftUI permits Binding, State, ObservedObject,
// and custom DynamicProperty values to be declared and initialized from
// otherwise nonisolated code. The retained render graph is main-actor-only;
// an attached State storage asserts that boundary when it is mutated.
public protocol _OpenDynamicProperty {
    mutating func update()
}

public extension _OpenDynamicProperty {
    mutating func update() {}
}

public typealias DynamicProperty = _OpenDynamicProperty

@dynamicMemberLookup
@propertyWrapper
public struct _OpenBinding<Value>: _OpenDynamicProperty {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void
    ) {
        getter = get
        setter = set
    }

    public init(projectedValue: _OpenBinding<Value>) {
        self = projectedValue
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: _OpenBinding<Value> { self }

    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> _OpenBinding<Subject> {
        _OpenBinding<Subject>(
            get: { getter()[keyPath: keyPath] },
            set: { newValue in
                var root = getter()
                root[keyPath: keyPath] = newValue
                setter(root)
            }
        )
    }

    public static func constant(_ value: Value) -> _OpenBinding<Value> {
        _OpenBinding(get: { value }, set: { _ in })
    }
}

public typealias Binding<Value> = _OpenBinding<Value>

private protocol _OpenAnyStateStorage: AnyObject {
    func detachFromGraph()
}

private final class _OpenStateStorage<Value>: _OpenAnyStateStorage {
    var value: Value
    var invalidateMountedGraph: (() -> Void)?

    init(value: Value) {
        self.value = value
    }

    func set(_ newValue: Value) {
        // The callback enters MainActor.assumeIsolated before any mutation.
        // Local, not-yet-mounted State intentionally has no callback and may
        // retain system SwiftUI's nonisolated value-container behavior.
        invalidateMountedGraph?()
        value = newValue
    }

    func detachFromGraph() {
        invalidateMountedGraph = nil
    }
}

private final class _OpenStateSeed<Value> {
    let initialValue: Value
    let localStorage: _OpenStateStorage<Value>

    init(_ initialValue: Value) {
        self.initialValue = initialValue
        localStorage = _OpenStateStorage(value: initialValue)
    }
}

private struct _OpenPropertyPathComponent: Hashable {
    let inheritanceDepth: Int
    let fieldIndex: Int
    let label: String?
}

private protocol _OpenGraphProperty {
    @MainActor
    mutating func prepare(
        in graph: _OpenGraphHost,
        propertyPath: [_OpenPropertyPathComponent]
    )
}

@propertyWrapper
public struct _OpenState<Value>: _OpenDynamicProperty, _OpenGraphProperty {
    private let seed: _OpenStateSeed<Value>
    // Graph attachment belongs to this prepared State value, not its shared
    // pre-mount seed. Two structural copies of one View value therefore bind
    // to two state locations even though their initial wrappers share a seed.
    private var graphStorage: _OpenStateStorage<Value>?

    public init(wrappedValue: Value) {
        seed = _OpenStateSeed(wrappedValue)
        graphStorage = nil
    }

    public init(initialValue: Value) {
        seed = _OpenStateSeed(initialValue)
        graphStorage = nil
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.set(newValue) }
    }

    public var projectedValue: _OpenBinding<Value> {
        let storage = storage
        return _OpenBinding(
            get: { storage.value },
            set: { storage.set($0) }
        )
    }

    private var storage: _OpenStateStorage<Value> {
        graphStorage ?? seed.localStorage
    }

    @MainActor
    fileprivate mutating func prepare(
        in graph: _OpenGraphHost,
        propertyPath: [_OpenPropertyPathComponent]
    ) {
        graphStorage = graph.stateStorage(
            propertyPath: propertyPath,
            initialValue: seed.initialValue
        )
    }
}

public typealias State<Value> = _OpenState<Value>

@propertyWrapper
public struct _OpenObservedObject<ObjectType>: _OpenDynamicProperty, _OpenGraphProperty
    where ObjectType: Combine.ObservableObject
{
    @dynamicMemberLookup
    public struct Wrapper {
        private let object: ObjectType

        fileprivate init(_ object: ObjectType) {
            self.object = object
        }

        public subscript<Subject>(
            dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>
        ) -> _OpenBinding<Subject> {
            _OpenBinding(
                get: { object[keyPath: keyPath] },
                set: { object[keyPath: keyPath] = $0 }
            )
        }
    }

    private var object: ObjectType

    public init(wrappedValue: ObjectType) {
        object = wrappedValue
    }

    public init(initialValue: ObjectType) {
        object = initialValue
    }

    public var wrappedValue: ObjectType {
        get { object }
        set { object = newValue }
    }

    public var projectedValue: Wrapper { Wrapper(object) }

    @MainActor
    fileprivate mutating func prepare(
        in graph: _OpenGraphHost,
        propertyPath: [_OpenPropertyPathComponent]
    ) {
        _ = propertyPath
        graph.observe(object)
    }
}

public typealias ObservedObject<ObjectType> = _OpenObservedObject<ObjectType>
    where ObjectType: Combine.ObservableObject

@MainActor
private final class _OpenObservationEntry {
    let cancellation: AnyCancellable

    init(_ cancellation: AnyCancellable) {
        self.cancellation = cancellation
    }
}

// Structural components are typed Hashable values rather than interpolated
// strings. This makes tuple positions, conditional branches, positional
// arrays, and explicit ForEach IDs collision-safe and independently scoped.
enum _OpenGraphStructuralScope: Hashable {
    case tupleElement(Int)
    case optionalSome
    case conditionalTrue
    case conditionalFalse
    case arrayElement(Int)
    case hStackContent
    case vStackContent
    case zStackContent
    case buttonLabel
    case scrollContent
    case tabViewContent
    case formContent
    case forEachContent
    case forEachElement(AnyHashable)
    case navigationContent
    case modifiedContent
    case background
    case overlay
    case toolbar
    case onAppear
}

private enum _OpenGraphPathComponent: Hashable {
    case viewType(ObjectIdentifier)
    case structural(_OpenGraphStructuralScope)
}

private struct _OpenStateKey: Hashable {
    let viewPath: [_OpenGraphPathComponent]
    let propertyPath: [_OpenPropertyPathComponent]
    let valueType: ObjectIdentifier
}

// Swift's public Mirror API can be replaced by CustomReflectable and always
// returns child values as copies. DynamicProperty preparation instead needs
// the real stored-field list plus value-semantic write-back. These runtime
// entry points are the same cross-platform primitives used by the standard
// library's internal Mirror implementation and Reflection SPI. Calling the
// child accessor directly deliberately bypasses a user-supplied customMirror;
// runtime metadata remains the authority for field count, order, type, and
// offset. Every field is validated before writing through an offset.
private typealias _OpenReflectionNameFree = @convention(c) (
    UnsafePointer<CChar>?
) -> Void

private struct _OpenFieldReflectionMetadata {
    var name: UnsafePointer<CChar>?
    var freeFunc: _OpenReflectionNameFree?
    var isStrong: Bool
    var isVar: Bool

    init() {
        name = nil
        freeFunc = nil
        isStrong = false
        isVar = false
    }
}

@_silgen_name("swift_reflectionMirror_recursiveCount")
private func _openRecursiveChildCount(_ type: Any.Type) -> Int

@_silgen_name("swift_reflectionMirror_recursiveChildOffset")
private func _openRecursiveChildOffset(_ type: Any.Type, index: Int) -> Int

@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
private func _openRecursiveChildMetadata(
    _ type: Any.Type,
    index: Int,
    fieldMetadata: UnsafeMutablePointer<_OpenFieldReflectionMetadata>
) -> Any.Type

@_silgen_name("swift_getMetadataKind")
private func _openMetadataKind(_ type: Any.Type) -> UInt

@_silgen_name("swift_reflectionMirror_count")
private func _openDirectChildCount<Container>(
    _ value: Container,
    type: Any.Type
) -> Int

@_silgen_name("swift_reflectionMirror_subscript")
private func _openDirectChild<Container>(
    of value: Container,
    type: Any.Type,
    index: Int,
    outName: UnsafeMutablePointer<UnsafePointer<CChar>?>,
    outFreeFunc: UnsafeMutablePointer<_OpenReflectionNameFree?>
) -> Any

private enum _OpenMetadataKind: UInt {
    case `class` = 0
    case `struct` = 0x200
    case `enum` = 0x201
    case optional = 0x202
    case foreignClass = 0x203
    case tuple = 0x301
    case existential = 0x303
}

private func _openRuntimeChild<Container>(
    of value: Container,
    type: Any.Type,
    index: Int
) -> (label: String?, value: Any) {
    var name: UnsafePointer<CChar>?
    var freeName: _OpenReflectionNameFree?
    let child = _openDirectChild(
        of: value,
        type: type,
        index: index,
        outName: &name,
        outFreeFunc: &freeName
    )
    let label = name.map { String(cString: $0) }
    freeName?(name)
    return (label, child)
}

private struct _OpenWritableReflectedField {
    let value: Any
    let declaredType: Any.Type
    let byteOffset: Int
    let isStrong: Bool
    let propertyPathComponent: _OpenPropertyPathComponent
}

/// Opaque, typed identity for a stable location in one host's rendered graph.
/// The path components stay private so callers cannot manufacture identities
/// from lossy strings or couple themselves to the graph representation.
struct _OpenGraphIdentity: Hashable {
    private let path: [_OpenGraphPathComponent]

    fileprivate init(path: [_OpenGraphPathComponent]) {
        self.path = path
    }
}

private struct _OpenRepresentedControllerKey: Hashable {
    let viewPath: [_OpenGraphPathComponent]
    let controllerType: ObjectIdentifier
}

/// Retained by one hosting controller. It owns dynamic-property locations and
/// subscriptions, but never owns the controller back.
@MainActor
final class _OpenGraphHost {
    private var path: [_OpenGraphPathComponent] = []
    private var state: [_OpenStateKey: any _OpenAnyStateStorage] = [:]
    private var observations: [ObjectIdentifier: _OpenObservationEntry] = [:]
    private var representedControllers: [_OpenRepresentedControllerKey: UIViewController] = [:]
    private var activeStateKeys: Set<_OpenStateKey> = []
    private var activeObservationKeys: Set<ObjectIdentifier> = []
    private var activeRepresentedControllerKeys: Set<_OpenRepresentedControllerKey> = []
    private var invalidationScheduled = false

    var invalidate: (@MainActor () -> Void)?
    private(set) var renderCount = 0
    private(set) var invalidationCount = 0

    var stateCount: Int { state.count }
    var observationCount: Int { observations.count }
    var representedControllerCount: Int { representedControllers.count }

    func evaluate<Content: _OpenView>(_ content: Content) -> _OpenViewNode {
        // A direct root replacement supersedes queued work from the previous
        // value. The already-enqueued task observes this flag and becomes a
        // no-op rather than performing a second render.
        invalidationScheduled = false
        activeStateKeys.removeAll(keepingCapacity: true)
        activeObservationKeys.removeAll(keepingCapacity: true)
        activeRepresentedControllerKeys.removeAll(keepingCapacity: true)
        path.removeAll(keepingCapacity: true)
        renderCount += 1

        let node = _OpenGraphContext.withHost(self) {
            content._makeOpenUIKitNode()
        }

        precondition(path.isEmpty, "unbalanced SwiftUI structural graph scopes")

        let staleStateKeys = state.keys.filter { !activeStateKeys.contains($0) }
        for key in staleStateKeys {
            state.removeValue(forKey: key)?.detachFromGraph()
        }
        let staleObservationKeys = observations.keys.filter {
            !activeObservationKeys.contains($0)
        }
        for key in staleObservationKeys {
            observations.removeValue(forKey: key)?.cancellation.cancel()
        }
        let staleControllerKeys = representedControllers.keys.filter {
            !activeRepresentedControllerKeys.contains($0)
        }
        for key in staleControllerKeys {
            representedControllers.removeValue(forKey: key)
        }
        return node
    }

    func withView<View, Result>(
        _ view: View,
        makeBody: (View) -> Result
    ) -> Result {
        let typeID = ObjectIdentifier(View.self)
        return withPath(.viewType(typeID)) {
            var preparedView = view
            var activeDynamicObjects: Set<ObjectIdentifier> = []
            prepareFields(
                of: &preparedView,
                propertyPath: [],
                activeDynamicObjects: &activeDynamicObjects
            )
            return makeBody(preparedView)
        }
    }

    func withStructuralScope<Result>(
        _ scope: _OpenGraphStructuralScope,
        operation: () -> Result
    ) -> Result {
        withPath(.structural(scope), operation: operation)
    }

    func currentIdentity() -> _OpenGraphIdentity {
        _OpenGraphIdentity(path: path)
    }

    private func withPath<Result>(
        _ component: _OpenGraphPathComponent,
        operation: () -> Result
    ) -> Result {
        path.append(component)
        defer { path.removeLast() }
        return operation()
    }

    private func prepareFields<Container>(
        of value: inout Container,
        propertyPath: [_OpenPropertyPathComponent],
        activeDynamicObjects: inout Set<ObjectIdentifier>
    ) {
        let fields = writableReflectedFields(of: value)
        guard !fields.isEmpty else { return }

        let rootAddress: UnsafeMutableRawPointer
        switch _OpenMetadataKind(rawValue: _openMetadataKind(Container.self)) {
        case .struct, .tuple:
            return withUnsafeMutablePointer(to: &value) { pointer in
                let rawPointer = UnsafeMutableRawPointer(pointer)
                for field in fields {
                    prepareField(
                        field,
                        rootAddress: rawPointer,
                        containerSize: MemoryLayout<Container>.size,
                        propertyPath: propertyPath,
                        activeDynamicObjects: &activeDynamicObjects
                    )
                }
            }
        case .class, .foreignClass:
            // Recursive class-field offsets are relative to the native Swift
            // heap object, including its header. The runtime reports those
            // same offsets on Darwin and Linux.
            rootAddress = Unmanaged.passUnretained(value as AnyObject).toOpaque()
        default:
            fatalError(
                "SwiftUI DynamicProperty reflection supports stored fields "
                    + "in structs, tuples, and classes; got \(Container.self)"
            )
        }

        for field in fields {
            prepareField(
                field,
                rootAddress: rootAddress,
                containerSize: nil,
                propertyPath: propertyPath,
                activeDynamicObjects: &activeDynamicObjects
            )
        }
    }

    private func writableReflectedFields<Container>(
        of value: Container
    ) -> [_OpenWritableReflectedField] {
        let runtimeCount = _openRecursiveChildCount(Container.self)
        guard runtimeCount >= 0 else {
            fatalError(
                "SwiftUI reflection returned an invalid field count for "
                    + "\(Container.self)"
            )
        }

        let reflectedChildren: [(
            inheritanceDepth: Int,
            fieldIndex: Int,
            label: String?,
            value: Any
        )]

        switch _OpenMetadataKind(rawValue: _openMetadataKind(Container.self)) {
        case .struct, .tuple:
            let directCount = _openDirectChildCount(
                value,
                type: Container.self
            )
            guard directCount == runtimeCount else {
                fatalError(
                    "SwiftUI reflection metadata mismatch for \(Container.self): "
                        + "runtime reported \(runtimeCount) stored fields but "
                        + "the runtime child accessor reported \(directCount)"
                )
            }
            reflectedChildren = (0..<runtimeCount).map { index in
                let child = _openRuntimeChild(
                    of: value,
                    type: Container.self,
                    index: index
                )
                return (0, index, child.label, child.value)
            }
        case .class, .foreignClass:
            guard let rootClass = Container.self as? AnyClass else {
                fatalError(
                    "SwiftUI reflection classified \(Container.self) as a class "
                        + "without class metadata"
                )
            }
            var classes: [(inheritanceDepth: Int, type: AnyClass)] = []
            var reflectedClass: AnyClass? = rootClass
            var inheritanceDepth = 0
            while let current = reflectedClass {
                classes.append((inheritanceDepth, current))
                reflectedClass = _getSuperclass(current)
                inheritanceDepth += 1
            }

            // Recursive metadata enumerates base storage first. Query each
            // class's real direct children in that order while keeping the
            // subclass-relative depth used in property-path identity.
            reflectedChildren = classes.reversed().flatMap { entry in
                let directCount = _openDirectChildCount(
                    value,
                    type: entry.type
                )
                guard directCount >= 0 else {
                    fatalError(
                        "SwiftUI reflection returned an invalid field count "
                            + "for \(entry.type)"
                    )
                }
                return (0..<directCount).map { fieldIndex in
                    let child = _openRuntimeChild(
                        of: value,
                        type: entry.type,
                        index: fieldIndex
                    )
                    return (
                        entry.inheritanceDepth,
                        fieldIndex,
                        child.label,
                        child.value
                    )
                }
            }
        default:
            guard runtimeCount == 0 else {
                fatalError(
                    "SwiftUI DynamicProperty reflection supports stored fields "
                        + "in structs, tuples, and classes; got \(Container.self) "
                        + "with \(runtimeCount) runtime fields"
                )
            }
            return []
        }

        guard runtimeCount == reflectedChildren.count else {
            fatalError(
                "SwiftUI reflection metadata mismatch for \(Container.self): "
                    + "runtime reported \(runtimeCount) stored fields but direct "
                    + "runtime traversal reported \(reflectedChildren.count)"
            )
        }

        return reflectedChildren.enumerated().map { index, child in
            var metadata = _OpenFieldReflectionMetadata()
            let declaredType = _openRecursiveChildMetadata(
                Container.self,
                index: index,
                fieldMetadata: &metadata
            )
            let runtimeLabel = metadata.name.map { String(cString: $0) }
            metadata.freeFunc?(metadata.name)

            guard runtimeLabel == child.label else {
                fatalError(
                    "SwiftUI reflection field-order mismatch for \(Container.self) "
                        + "at index \(index)"
                )
            }
            let byteOffset = _openRecursiveChildOffset(
                Container.self,
                index: index
            )
            guard byteOffset >= 0 else {
                fatalError(
                    "SwiftUI reflection returned an invalid field offset for "
                        + "\(Container.self) at index \(index)"
                )
            }

            return _OpenWritableReflectedField(
                value: child.value,
                declaredType: declaredType,
                byteOffset: byteOffset,
                isStrong: metadata.isStrong,
                propertyPathComponent: _OpenPropertyPathComponent(
                    inheritanceDepth: child.inheritanceDepth,
                    fieldIndex: child.fieldIndex,
                    label: child.label
                )
            )
        }
    }

    private func prepareField(
        _ field: _OpenWritableReflectedField,
        rootAddress: UnsafeMutableRawPointer,
        containerSize: Int?,
        propertyPath: [_OpenPropertyPathComponent],
        activeDynamicObjects: inout Set<ObjectIdentifier>
    ) {
        guard let dynamicProperty = field.value as? any _OpenDynamicProperty else {
            return
        }
        guard field.isStrong else {
            fatalError(
                "SwiftUI cannot write back a non-strong DynamicProperty field "
                    + "of type \(field.declaredType)"
            )
        }
        let childPath = propertyPath + [field.propertyPathComponent]
        prepareDynamicProperty(
            dynamicProperty,
            declaredType: field.declaredType,
            address: rootAddress.advanced(by: field.byteOffset),
            availableContainerSize: containerSize.map { $0 - field.byteOffset },
            propertyPath: childPath,
            activeDynamicObjects: &activeDynamicObjects
        )
    }

    private func prepareDynamicProperty<Property: _OpenDynamicProperty>(
        _ property: Property,
        declaredType: Any.Type,
        address: UnsafeMutableRawPointer,
        availableContainerSize: Int?,
        propertyPath: [_OpenPropertyPathComponent],
        activeDynamicObjects: inout Set<ObjectIdentifier>
    ) {
        guard ObjectIdentifier(declaredType) == ObjectIdentifier(Property.self) else {
            fatalError(
                "SwiftUI cannot write back an existentially stored DynamicProperty "
                    + "field (declared \(declaredType), value \(Property.self))"
            )
        }
        guard Int(bitPattern: address) % MemoryLayout<Property>.alignment == 0 else {
            fatalError(
                "SwiftUI reflection returned a misaligned DynamicProperty field "
                    + "for \(Property.self)"
            )
        }
        if let availableContainerSize {
            guard availableContainerSize >= 0,
                  MemoryLayout<Property>.size <= availableContainerSize
            else {
                fatalError(
                    "SwiftUI reflection returned an out-of-bounds DynamicProperty "
                        + "field for \(Property.self)"
                )
            }
        }

        var preparedProperty = property

        if var graphProperty = preparedProperty as? any _OpenGraphProperty {
            graphProperty.prepare(in: self, propertyPath: propertyPath)
            guard let typedGraphProperty = graphProperty as? Property else {
                fatalError(
                    "SwiftUI could not restore a prepared graph property of "
                        + "type \(Property.self)"
                )
            }
            preparedProperty = typedGraphProperty
            preparedProperty.update()
            address.assumingMemoryBound(to: Property.self).pointee = preparedProperty
            return
        }

        // DynamicProperty is normally a value type, but the public protocol
        // does not forbid classes. Track class identities only on the active
        // recursion path: cycles terminate, while two structural fields that
        // alias one class property still each receive update().
        let propertyKind = _OpenMetadataKind(
            rawValue: _openMetadataKind(Property.self)
        )
        var activeObjectIdentifier: ObjectIdentifier?
        if propertyKind == .class || propertyKind == .foreignClass {
            let identifier = ObjectIdentifier(preparedProperty as AnyObject)
            guard activeDynamicObjects.insert(identifier).inserted else {
                return
            }
            activeObjectIdentifier = identifier
        }
        defer {
            if let activeObjectIdentifier {
                activeDynamicObjects.remove(activeObjectIdentifier)
            }
        }

        // Inner DynamicProperty values are prepared and updated before their
        // enclosing custom property. Every prepared value is written back so
        // ordinary stored mutations made by update() are visible to body.
        prepareFields(
            of: &preparedProperty,
            propertyPath: propertyPath,
            activeDynamicObjects: &activeDynamicObjects
        )
        preparedProperty.update()
        address.assumingMemoryBound(to: Property.self).pointee = preparedProperty
    }

    fileprivate func stateStorage<Value>(
        propertyPath: [_OpenPropertyPathComponent],
        initialValue: Value
    ) -> _OpenStateStorage<Value> {
        let key = _OpenStateKey(
            viewPath: path,
            propertyPath: propertyPath,
            valueType: ObjectIdentifier(Value.self)
        )
        activeStateKeys.insert(key)
        if let existing = state[key] {
            guard let typed = existing as? _OpenStateStorage<Value> else {
                preconditionFailure("SwiftUI state type changed at a stable structural location")
            }
            attach(typed)
            return typed
        }
        let storage = _OpenStateStorage(value: initialValue)
        attach(storage)
        state[key] = storage
        return storage
    }

    private func attach<Value>(_ storage: _OpenStateStorage<Value>) {
        storage.invalidateMountedGraph = { [weak self] in
            MainActor.assumeIsolated {
                self?.scheduleInvalidation()
            }
        }
    }

    fileprivate func observe<ObjectType>(_ object: ObjectType)
        where ObjectType: Combine.ObservableObject
    {
        let key = ObjectIdentifier(object)
        activeObservationKeys.insert(key)
        guard observations[key] == nil else { return }

        let cancellation = object.objectWillChange.sink { [weak self] _ in
            // ObservableObject changes which drive a view are UI mutations.
            // Like OpenUIKit target/action, this is an asserted boundary: an
            // off-main publication traps instead of racing the mounted tree.
            MainActor.assumeIsolated {
                self?.scheduleInvalidation()
            }
        }
        observations[key] = _OpenObservationEntry(cancellation)
    }

    fileprivate func representedController<Controller: UIViewController>(
        make: () -> Controller,
        update: (Controller) -> Void
    ) -> Controller {
        let key = _OpenRepresentedControllerKey(
            viewPath: path,
            controllerType: ObjectIdentifier(Controller.self)
        )
        activeRepresentedControllerKeys.insert(key)

        let controller: Controller
        if let existing = representedControllers[key] {
            guard let typed = existing as? Controller else {
                preconditionFailure(
                    "UIViewControllerRepresentable type changed at a stable structural location"
                )
            }
            controller = typed
        } else {
            controller = make()
            representedControllers[key] = controller
        }
        update(controller)
        return controller
    }

    fileprivate func scheduleInvalidation() {
        guard !invalidationScheduled else { return }
        invalidationScheduled = true
        Task { @MainActor [weak self] in
            guard let self, self.invalidationScheduled else { return }
            self.invalidationScheduled = false
            self.invalidationCount += 1
            self.invalidate?()
        }
    }
}

@MainActor
enum _OpenGraphContext {
    private static var currentHost: _OpenGraphHost?

    static func withHost<Result>(_ host: _OpenGraphHost, operation: () -> Result) -> Result {
        let previous = currentHost
        currentHost = host
        defer { currentHost = previous }
        return operation()
    }

    static func withView<View, Result>(
        _ view: View,
        makeBody: (View) -> Result
    ) -> Result {
        guard let currentHost else { return makeBody(view) }
        return currentHost.withView(view, makeBody: makeBody)
    }

    static func withStructuralScope<Result>(
        _ scope: _OpenGraphStructuralScope,
        operation: () -> Result
    ) -> Result {
        guard let currentHost else { return operation() }
        return currentHost.withStructuralScope(scope, operation: operation)
    }

    static func currentIdentity() -> _OpenGraphIdentity? {
        currentHost?.currentIdentity()
    }

    static func representedController<Controller: UIViewController>(
        make: () -> Controller,
        update: (Controller) -> Void
    ) -> Controller {
        guard let currentHost else {
            let controller = make()
            update(controller)
            return controller
        }
        return currentHost.representedController(make: make, update: update)
    }
}
