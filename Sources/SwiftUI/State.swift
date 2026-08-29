// SwiftUI S2: state, bindings, and observation for the OpenUIKit host.
//
// The reactive declarations come from exactly one platform Combine identity:
// Apple's first-party module on Darwin, or the package's literal Combine shim
// backed by pinned OpenCombine on Linux. Do not define lookalike
// implementations here.

@_exported import Combine

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
    var graphStorage: _OpenStateStorage<Value>?

    init(_ initialValue: Value) {
        self.initialValue = initialValue
        localStorage = _OpenStateStorage(value: initialValue)
    }

    var storage: _OpenStateStorage<Value> {
        graphStorage ?? localStorage
    }
}

private struct _OpenPropertyPathComponent: Hashable {
    let inheritanceDepth: Int
    let fieldIndex: Int
    let label: String?
}

private protocol _OpenGraphProperty {
    @MainActor
    func prepare(
        in graph: _OpenGraphHost,
        propertyPath: [_OpenPropertyPathComponent]
    )
}

@propertyWrapper
public struct _OpenState<Value>: _OpenDynamicProperty, _OpenGraphProperty {
    private let seed: _OpenStateSeed<Value>

    public init(wrappedValue: Value) {
        seed = _OpenStateSeed(wrappedValue)
    }

    public init(initialValue: Value) {
        seed = _OpenStateSeed(initialValue)
    }

    public var wrappedValue: Value {
        get { seed.storage.value }
        nonmutating set { seed.storage.set(newValue) }
    }

    public var projectedValue: _OpenBinding<Value> {
        _OpenBinding(
            get: { seed.storage.value },
            set: { seed.storage.set($0) }
        )
    }

    @MainActor
    fileprivate func prepare(
        in graph: _OpenGraphHost,
        propertyPath: [_OpenPropertyPathComponent]
    ) {
        seed.graphStorage = graph.stateStorage(
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
    fileprivate func prepare(
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
    case formContent
    case forEachContent
    case forEachElement(AnyHashable)
    case navigationContent
    case modifiedContent
    case background
    case overlay
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

// Swift's public Mirror API intentionally returns child values as copies. A
// DynamicProperty update, however, has value semantics: body must see the
// mutated property in the prepared copy of its View. These runtime entry
// points are the same cross-platform primitives used by the standard
// library's Reflection SPI to pair stored fields with their byte offsets.
// We keep the ABI declarations private and validate every reflected field
// before writing through an offset.
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

private struct _OpenWritableReflectedField {
    let value: Any
    let declaredType: Any.Type
    let byteOffset: Int
    let propertyPathComponent: _OpenPropertyPathComponent
}

/// Retained by one hosting controller. It owns dynamic-property locations and
/// subscriptions, but never owns the controller back.
@MainActor
final class _OpenGraphHost {
    private var path: [_OpenGraphPathComponent] = []
    private var state: [_OpenStateKey: any _OpenAnyStateStorage] = [:]
    private var observations: [ObjectIdentifier: _OpenObservationEntry] = [:]
    private var activeStateKeys: Set<_OpenStateKey> = []
    private var activeObservationKeys: Set<ObjectIdentifier> = []
    private var invalidationScheduled = false

    var invalidate: (@MainActor () -> Void)?
    private(set) var renderCount = 0
    private(set) var invalidationCount = 0

    var stateCount: Int { state.count }
    var observationCount: Int { observations.count }

    func evaluate<Content: _OpenView>(_ content: Content) -> _OpenViewNode {
        // A direct root replacement supersedes queued work from the previous
        // value. The already-enqueued task observes this flag and becomes a
        // no-op rather than performing a second render.
        invalidationScheduled = false
        activeStateKeys.removeAll(keepingCapacity: true)
        activeObservationKeys.removeAll(keepingCapacity: true)
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
        return node
    }

    func withView<View, Result>(
        _ view: View,
        makeBody: (View) -> Result
    ) -> Result {
        let typeID = ObjectIdentifier(View.self)
        return withPath(.viewType(typeID)) {
            var preparedView = view
            var visitedDynamicObjects: Set<ObjectIdentifier> = []
            prepareFields(
                of: &preparedView,
                propertyPath: [],
                visitedDynamicObjects: &visitedDynamicObjects
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
        visitedDynamicObjects: inout Set<ObjectIdentifier>
    ) {
        let fields = writableReflectedFields(of: value)
        guard !fields.isEmpty else { return }

        let rootAddress: UnsafeMutableRawPointer
        switch Mirror(reflecting: value).displayStyle {
        case .struct, .tuple:
            return withUnsafeMutablePointer(to: &value) { pointer in
                let rawPointer = UnsafeMutableRawPointer(pointer)
                for field in fields {
                    prepareField(
                        field,
                        rootAddress: rawPointer,
                        containerSize: MemoryLayout<Container>.size,
                        propertyPath: propertyPath,
                        visitedDynamicObjects: &visitedDynamicObjects
                    )
                }
            }
        case .class:
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
                visitedDynamicObjects: &visitedDynamicObjects
            )
        }
    }

    private func writableReflectedFields<Container>(
        of value: Container
    ) -> [_OpenWritableReflectedField] {
        let rootMirror = Mirror(reflecting: value)
        let reflectedChildren: [(
            inheritanceDepth: Int,
            fieldIndex: Int,
            label: String?,
            value: Any
        )]

        switch rootMirror.displayStyle {
        case .struct, .tuple:
            reflectedChildren = rootMirror.children.enumerated().map {
                (0, $0.offset, $0.element.label, $0.element.value)
            }
        case .class:
            var mirrors: [(inheritanceDepth: Int, mirror: Mirror)] = []
            var mirror: Mirror? = rootMirror
            var inheritanceDepth = 0
            while let current = mirror {
                mirrors.append((inheritanceDepth, current))
                mirror = current.superclassMirror
                inheritanceDepth += 1
            }
            // The runtime's recursive class-field APIs enumerate base-class
            // storage first. Mirror exposes the subclass first, so normalize
            // it here while retaining the old depth/index identity.
            reflectedChildren = mirrors.reversed().flatMap { entry in
                entry.mirror.children.enumerated().map {
                    (
                        entry.inheritanceDepth,
                        $0.offset,
                        $0.element.label,
                        $0.element.value
                    )
                }
            }
        default:
            let dynamicChildren = rootMirror.children.filter {
                $0.value is any _OpenDynamicProperty
            }
            guard dynamicChildren.isEmpty else {
                fatalError(
                    "SwiftUI cannot prepare DynamicProperty fields in unsupported "
                        + "container \(Container.self)"
                )
            }
            return []
        }

        let runtimeCount = _openRecursiveChildCount(Container.self)
        guard runtimeCount == reflectedChildren.count else {
            fatalError(
                "SwiftUI reflection metadata mismatch for \(Container.self): "
                    + "runtime reported \(runtimeCount) fields but Mirror reported "
                    + "\(reflectedChildren.count)"
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
        visitedDynamicObjects: inout Set<ObjectIdentifier>
    ) {
        guard let dynamicProperty = field.value as? any _OpenDynamicProperty else {
            return
        }
        let childPath = propertyPath + [field.propertyPathComponent]
        prepareDynamicProperty(
            dynamicProperty,
            declaredType: field.declaredType,
            address: rootAddress.advanced(by: field.byteOffset),
            availableContainerSize: containerSize.map { $0 - field.byteOffset },
            propertyPath: childPath,
            visitedDynamicObjects: &visitedDynamicObjects
        )
    }

    private func prepareDynamicProperty<Property: _OpenDynamicProperty>(
        _ property: Property,
        declaredType: Any.Type,
        address: UnsafeMutableRawPointer,
        availableContainerSize: Int?,
        propertyPath: [_OpenPropertyPathComponent],
        visitedDynamicObjects: inout Set<ObjectIdentifier>
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

        if let graphProperty = preparedProperty as? any _OpenGraphProperty {
            graphProperty.prepare(in: self, propertyPath: propertyPath)
            preparedProperty.update()
            address.assumingMemoryBound(to: Property.self).pointee = preparedProperty
            return
        }

        // DynamicProperty is normally a value type, but the public protocol
        // does not forbid classes. Track class identities so a pathological
        // self-referential custom property cannot recurse forever.
        let dynamicMirror = Mirror(reflecting: preparedProperty)
        if dynamicMirror.displayStyle == .class {
            let identifier = ObjectIdentifier(preparedProperty as AnyObject)
            guard visitedDynamicObjects.insert(identifier).inserted else {
                return
            }
        }

        // Inner DynamicProperty values are prepared and updated before their
        // enclosing custom property. Every prepared value is written back so
        // ordinary stored mutations made by update() are visible to body.
        prepareFields(
            of: &preparedProperty,
            propertyPath: propertyPath,
            visitedDynamicObjects: &visitedDynamicObjects
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
}
