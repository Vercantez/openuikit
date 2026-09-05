import Foundation

public protocol GCPhysicalInputElement: NSObjectProtocol {
    var aliases: Set<String> { get }
    var localizedName: String? { get }
    var sfSymbolsName: String? { get }
}

public protocol GCPhysicalInputSource: NSObjectProtocol {
    var direction: GCPhysicalInputSourceDirection { get }
    var elementAliases: Set<String> { get }
    var elementLocalizedName: String? { get }
    var sfSymbolsName: String? { get }
}

public protocol GCAxisInput: NSObjectProtocol {
    var isAnalog: Bool { get }
    var canWrap: Bool { get }
    var lastValueLatency: TimeInterval { get }
    var lastValueTimestamp: TimeInterval { get }
    var sources: Set<AnyHashable> { get }
    var value: Float { get }
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCAxisInput, Float) -> Void)? { get set }
}

public protocol GCAxis2DInput: NSObjectProtocol {
    var isAnalog: Bool { get }
    var canWrap: Bool { get }
    var lastValueLatency: TimeInterval { get }
    var lastValueTimestamp: TimeInterval { get }
    var sources: Set<AnyHashable> { get }
    var value: GCPoint2 { get }
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCAxis2DInput, GCPoint2) -> Void)? { get set }
}

public protocol GCRelativeInput: NSObjectProtocol {
    var isAnalog: Bool { get }
    var delta: Float { get }
    var deltaDidChangeHandler: ((any GCPhysicalInputElement, any GCRelativeInput, Float) -> Void)? { get set }
    var lastDeltaLatency: TimeInterval { get }
    var lastDeltaTimestamp: TimeInterval { get }
    var sources: Set<AnyHashable> { get }
}

public protocol GCLinearInput: NSObjectProtocol {
    var isAnalog: Bool { get }
    var canWrap: Bool { get }
    var lastValueLatency: TimeInterval { get }
    var lastValueTimestamp: TimeInterval { get }
    var sources: Set<AnyHashable> { get }
    var value: Float { get }
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCLinearInput, Float) -> Void)? { get set }
}

public protocol GCPressedStateInput: NSObjectProtocol {
    var lastPressedStateLatency: TimeInterval { get }
    var lastPressedStateTimestamp: TimeInterval { get }
    var isPressed: Bool { get }
    var pressedDidChangeHandler: ((any GCPhysicalInputElement, any GCPressedStateInput, Bool) -> Void)? { get set }
    var sources: Set<AnyHashable> { get }
}

public protocol GCTouchedStateInput: NSObjectProtocol {
    var lastTouchedStateLatency: TimeInterval { get }
    var lastTouchedStateTimestamp: TimeInterval { get }
    var sources: Set<AnyHashable> { get }
    var isTouched: Bool { get }
    var touchedDidChangeHandler: ((any GCPhysicalInputElement, any GCTouchedStateInput, Bool) -> Void)? { get set }
}

public protocol GCSwitchPositionInput: NSObjectProtocol {
    var canWrap: Bool { get }
    var lastPositionLatency: TimeInterval { get }
    var lastPositionTimestamp: TimeInterval { get }
    var position: Int { get }
    var positionDidChangeHandler: ((any GCPhysicalInputElement, any GCSwitchPositionInput, Int) -> Void)? { get set }
    var positionRange: NSRange { get }
    var isSequential: Bool { get }
    var sources: Set<AnyHashable> { get }
}

public protocol GCAxisElement: GCPhysicalInputElement {
    var absoluteInput: (any GCAxisInput)? { get }
    var relativeInput: any GCRelativeInput { get }
}

public protocol GCButtonElement: GCPhysicalInputElement {
    var forceInput: (any GCLinearInput)? { get }
    var pressedInput: any GCLinearInput & GCPressedStateInput { get }
    var touchedInput: (any GCTouchedStateInput)? { get }
}

public protocol GCDirectionPadElement: GCPhysicalInputElement {
    var down: any GCLinearInput & GCPressedStateInput { get }
    var left: any GCLinearInput & GCPressedStateInput { get }
    var right: any GCLinearInput & GCPressedStateInput { get }
    var up: any GCLinearInput & GCPressedStateInput { get }
    var xAxis: any GCAxisInput { get }
    var xyAxes: any GCAxis2DInput { get }
    var yAxis: any GCAxisInput { get }
}

public protocol GCSwitchElement: GCPhysicalInputElement {
    var positionInput: any GCSwitchPositionInput { get }
}

public protocol GCPhysicalInputElementTypedName: Hashable, RawRepresentable, Sendable where RawValue == String {
    associatedtype PhysicalInputElement
}

public struct GCAxisElementName: GCPhysicalInputElementTypedName {
    public typealias PhysicalInputElement = GCAxisElement
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct GCButtonElementName: GCPhysicalInputElementTypedName {
    public typealias PhysicalInputElement = GCButtonElement
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let leftBumper = GCButtonElementName(rawValue: "Left Bumper")
    public static let leftTrigger = GCButtonElementName(rawValue: GCInputLeftTrigger)
    public static let rightBumper = GCButtonElementName(rawValue: "Right Bumper")
    public static let leftShoulder = GCButtonElementName(rawValue: GCInputLeftShoulder)
    public static let rightTrigger = GCButtonElementName(rawValue: GCInputRightTrigger)
    public static let rightShoulder = GCButtonElementName(rawValue: GCInputRightShoulder)
    public static let thumbstickButton = GCButtonElementName(rawValue: "Thumbstick Button")
    public static let a = GCButtonElementName(rawValue: GCInputButtonA)
    public static let b = GCButtonElementName(rawValue: GCInputButtonB)
    public static let x = GCButtonElementName(rawValue: GCInputButtonX)
    public static let y = GCButtonElementName(rawValue: GCInputButtonY)
    public static let leftThumbstickButton = GCButtonElementName(rawValue: GCInputLeftThumbstickButton)
    public static let rightThumbstickButton = GCButtonElementName(rawValue: GCInputRightThumbstickButton)
    public static let grip = GCButtonElementName(rawValue: "Grip")
    public static let home = GCButtonElementName(rawValue: GCInputButtonHome)
    public static let menu = GCButtonElementName(rawValue: GCInputButtonMenu)
    public static let share = GCButtonElementName(rawValue: GCInputButtonShare)
    public static let options = GCButtonElementName(rawValue: GCInputButtonOptions)
    public static let trigger = GCButtonElementName(rawValue: "Trigger")
    public static func arcadeButton(row: Int, column: Int) -> GCButtonElementName {
        GCButtonElementName(rawValue: "Arcade Button \(row),\(column)")
    }
    public static func backLeftButton(position: Int) -> GCButtonElementName {
        GCButtonElementName(rawValue: "Back Left Button \(position)")
    }
    public static func backRightButton(position: Int) -> GCButtonElementName {
        GCButtonElementName(rawValue: "Back Right Button \(position)")
    }
}

public struct GCSwitchElementName: GCPhysicalInputElementTypedName {
    public typealias PhysicalInputElement = GCSwitchElement
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct GCDirectionPadElementName: GCPhysicalInputElementTypedName {
    public typealias PhysicalInputElement = GCDirectionPadElement
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let directionPad = GCDirectionPadElementName(rawValue: GCInputDirectionPad)
    public static let thumbstick = GCDirectionPadElementName(rawValue: "Thumbstick")
    public static let leftThumbstick = GCDirectionPadElementName(rawValue: GCInputLeftThumbstick)
    public static let rightThumbstick = GCDirectionPadElementName(rawValue: GCInputRightThumbstick)
}

public struct GCPhysicalInputElementName: GCPhysicalInputElementTypedName {
    public typealias PhysicalInputElement = GCPhysicalInputElement
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

/// Unconstrained so `any` element existentials can be stored. Apple's overlay
/// writes `where T : GCPhysicalInputElement`; Linux Swift cannot form that
/// generic with protocol existentials.
public struct GCPhysicalInputElementCollection<T>: Collection {
    public typealias Element = T
    public typealias SubSequence = Slice<GCPhysicalInputElementCollection<T>>
    public typealias Indices = DefaultIndices<GCPhysicalInputElementCollection<T>>
    public typealias Iterator = IndexingIterator<GCPhysicalInputElementCollection<T>>

    public struct Index: Comparable, Hashable {
        let offset: Int
        public static func < (lhs: Index, rhs: Index) -> Bool { lhs.offset < rhs.offset }
        public static func == (lhs: Index, rhs: Index) -> Bool { lhs.offset == rhs.offset }
        public func hash(into hasher: inout Hasher) { hasher.combine(offset) }
    }

    var storage: [(name: String, element: T)]

    init(_ storage: [(String, T)] = []) {
        self.storage = storage.map { (name: $0.0, element: $0.1) }
    }

    public init() {
        self.storage = []
    }

    public var startIndex: Index { Index(offset: 0) }
    public var endIndex: Index { Index(offset: storage.count) }

    public func index(after i: Index) -> Index {
        Index(offset: i.offset + 1)
    }

    public subscript(position: Index) -> T {
        storage[position.offset].element
    }

    public subscript(elementName: String) -> T? {
        storage.first { $0.name == elementName }?.element
    }

    public subscript(elementName: GCDirectionPadElementName) -> T? {
        self[elementName.rawValue]
    }

    public subscript(elementName: GCAxisElementName) -> T? {
        self[elementName.rawValue]
    }

    public subscript(elementName: GCButtonElementName) -> T? {
        self[elementName.rawValue]
    }

    public subscript(elementName: GCSwitchElementName) -> T? {
        self[elementName.rawValue]
    }

    public subscript(elementName: GCPhysicalInputElementName) -> T? {
        self[elementName.rawValue]
    }

    public subscript<Name: GCPhysicalInputElementTypedName>(elementName: Name) -> T? {
        self[elementName.rawValue]
    }
}

public protocol GCDevicePhysicalInputState: NSObjectProtocol {
    var device: (any GCDevice)? { get }
    var lastEventLatency: TimeInterval { get }
    var lastEventTimestamp: TimeInterval { get }
    var axes: GCPhysicalInputElementCollection<any GCAxisElement> { get }
    var dpads: GCPhysicalInputElementCollection<any GCDirectionPadElement> { get }
    var buttons: GCPhysicalInputElementCollection<any GCButtonElement> { get }
    var elements: GCPhysicalInputElementCollection<any GCPhysicalInputElement> { get }
    var switches: GCPhysicalInputElementCollection<any GCSwitchElement> { get }
    subscript(key: String) -> (any GCPhysicalInputElement)? { get }
}

public protocol GCDevicePhysicalInputStateDiff: NSObjectProtocol {
    func change(for element: any GCPhysicalInputElement) -> GCDevicePhysicalInputElementChange
    func changedElements() -> NSEnumerator?
}

public protocol GCDevicePhysicalInput: GCDevicePhysicalInputState {
    var device: (any GCDevice)? { get }
    var elementValueDidChangeHandler: ((any GCDevicePhysicalInput, any GCPhysicalInputElement) -> Void)? { get set }
    var inputStateAvailableHandler: ((any GCDevicePhysicalInput) -> Void)? { get set }
    var inputStateQueueDepth: Int { get set }
    var queue: DispatchQueue? { get set }
    func capture() -> any GCDevicePhysicalInputState
    func nextInputState() -> (any GCDevicePhysicalInputState & GCDevicePhysicalInputStateDiff)?
}

extension GCControllerElement: GCPhysicalInputElement {}

final class _GCSoftwareInputSource: NSObject, GCPhysicalInputSource {
    var direction: GCPhysicalInputSourceDirection
    var elementAliases: Set<String>
    var elementLocalizedName: String?
    var sfSymbolsName: String?

    init(
        direction: GCPhysicalInputSourceDirection = [],
        aliases: Set<String> = [],
        localizedName: String? = nil,
        sfSymbolsName: String? = nil
    ) {
        self.direction = direction
        self.elementAliases = aliases
        self.elementLocalizedName = localizedName
        self.sfSymbolsName = sfSymbolsName
    }
}

final class _GCAxisInputAdapter: NSObject, GCAxisInput, GCRelativeInput, GCAxisElement {
    let backing: GCControllerAxisInput
    var aliases: Set<String> { backing.aliases }
    var localizedName: String? { backing.localizedName }
    var sfSymbolsName: String? { backing.sfSymbolsName }
    var isAnalog: Bool { backing.isAnalog }
    var canWrap: Bool { false }
    var lastValueLatency: TimeInterval = 0
    var lastValueTimestamp: TimeInterval = 0
    var lastDeltaLatency: TimeInterval = 0
    var lastDeltaTimestamp: TimeInterval = 0
    var sources: Set<AnyHashable> { [] }
    var value: Float { backing.value }
    var delta: Float = 0
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCAxisInput, Float) -> Void)?
    var deltaDidChangeHandler: ((any GCPhysicalInputElement, any GCRelativeInput, Float) -> Void)?
    var absoluteInput: (any GCAxisInput)? { self }
    var relativeInput: any GCRelativeInput { self }

    init(backing: GCControllerAxisInput) {
        self.backing = backing
        super.init()
    }
}

final class _GCAxis2DAdapter: NSObject, GCAxis2DInput {
    let x: GCControllerAxisInput
    let y: GCControllerAxisInput
    var isAnalog: Bool { x.isAnalog && y.isAnalog }
    var canWrap: Bool { false }
    var lastValueLatency: TimeInterval = 0
    var lastValueTimestamp: TimeInterval = 0
    var sources: Set<AnyHashable> { [] }
    var value: GCPoint2 { GCPoint2(x: x.value, y: y.value) }
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCAxis2DInput, GCPoint2) -> Void)?

    init(x: GCControllerAxisInput, y: GCControllerAxisInput) {
        self.x = x
        self.y = y
        super.init()
    }
}

final class _GCButtonElementAdapter: NSObject, GCButtonElement, GCLinearInput, GCPressedStateInput, GCTouchedStateInput {
    let backing: GCControllerButtonInput
    var aliases: Set<String> { backing.aliases }
    var localizedName: String? { backing.localizedName }
    var sfSymbolsName: String? { backing.sfSymbolsName }
    var isAnalog: Bool { backing.isAnalog }
    var canWrap: Bool { false }
    var lastValueLatency: TimeInterval = 0
    var lastValueTimestamp: TimeInterval = 0
    var lastPressedStateLatency: TimeInterval = 0
    var lastPressedStateTimestamp: TimeInterval = 0
    var lastTouchedStateLatency: TimeInterval = 0
    var lastTouchedStateTimestamp: TimeInterval = 0
    var sources: Set<AnyHashable> { [] }
    var value: Float { backing.value }
    var isPressed: Bool { backing.isPressed }
    var isTouched: Bool { backing.isTouched }
    var forceInput: (any GCLinearInput)? { nil }
    var pressedInput: any GCLinearInput & GCPressedStateInput { self }
    var touchedInput: (any GCTouchedStateInput)? { self }
    var valueDidChangeHandler: ((any GCPhysicalInputElement, any GCLinearInput, Float) -> Void)?
    var pressedDidChangeHandler: ((any GCPhysicalInputElement, any GCPressedStateInput, Bool) -> Void)?
    var touchedDidChangeHandler: ((any GCPhysicalInputElement, any GCTouchedStateInput, Bool) -> Void)?

    init(backing: GCControllerButtonInput) {
        self.backing = backing
        super.init()
    }
}

final class _GCDirectionPadElementAdapter: NSObject, GCDirectionPadElement {
    let backing: GCControllerDirectionPad
    let xAdapter: _GCAxisInputAdapter
    let yAdapter: _GCAxisInputAdapter
    let xyAdapter: _GCAxis2DAdapter
    let upAdapter: _GCButtonElementAdapter
    let downAdapter: _GCButtonElementAdapter
    let leftAdapter: _GCButtonElementAdapter
    let rightAdapter: _GCButtonElementAdapter

    var aliases: Set<String> { backing.aliases }
    var localizedName: String? { backing.localizedName }
    var sfSymbolsName: String? { backing.sfSymbolsName }
    var down: any GCLinearInput & GCPressedStateInput { downAdapter }
    var left: any GCLinearInput & GCPressedStateInput { leftAdapter }
    var right: any GCLinearInput & GCPressedStateInput { rightAdapter }
    var up: any GCLinearInput & GCPressedStateInput { upAdapter }
    var xAxis: any GCAxisInput { xAdapter }
    var yAxis: any GCAxisInput { yAdapter }
    var xyAxes: any GCAxis2DInput { xyAdapter }

    init(backing: GCControllerDirectionPad) {
        self.backing = backing
        self.xAdapter = _GCAxisInputAdapter(backing: backing.xAxis)
        self.yAdapter = _GCAxisInputAdapter(backing: backing.yAxis)
        self.xyAdapter = _GCAxis2DAdapter(x: backing.xAxis, y: backing.yAxis)
        self.upAdapter = _GCButtonElementAdapter(backing: backing.up)
        self.downAdapter = _GCButtonElementAdapter(backing: backing.down)
        self.leftAdapter = _GCButtonElementAdapter(backing: backing.left)
        self.rightAdapter = _GCButtonElementAdapter(backing: backing.right)
        super.init()
    }
}

final class _GCSwitchElementAdapter: NSObject, GCSwitchElement, GCSwitchPositionInput {
    var aliases: Set<String>
    var localizedName: String?
    var sfSymbolsName: String?
    var canWrap: Bool = false
    var lastPositionLatency: TimeInterval = 0
    var lastPositionTimestamp: TimeInterval = 0
    var position: Int = 0
    var positionDidChangeHandler: ((any GCPhysicalInputElement, any GCSwitchPositionInput, Int) -> Void)?
    var positionRange: NSRange = NSRange(location: 0, length: 1)
    var isSequential: Bool = true
    var sources: Set<AnyHashable> { [] }
    var positionInput: any GCSwitchPositionInput { self }

    init(name: String) {
        self.aliases = [name]
        self.localizedName = name
        super.init()
    }
}

open class GCControllerInputState: NSObject, GCDevicePhysicalInputState {
    public weak var device: (any GCDevice)?
    open var lastEventLatency: TimeInterval = 0
    open var lastEventTimestamp: TimeInterval = 0
    open var axes = GCPhysicalInputElementCollection<any GCAxisElement>()
    open var dpads = GCPhysicalInputElementCollection<any GCDirectionPadElement>()
    open var buttons = GCPhysicalInputElementCollection<any GCButtonElement>()
    open var elements = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
    open var switches = GCPhysicalInputElementCollection<any GCSwitchElement>()
    var changedNames: Set<String> = []

    public subscript(key: String) -> (any GCPhysicalInputElement)? {
        elements[key]
    }
}

open class GCControllerLiveInput: GCControllerInputState, GCDevicePhysicalInput {
    open var unmapped: GCControllerLiveInput?
    open var elementValueDidChangeHandler: ((any GCDevicePhysicalInput, any GCPhysicalInputElement) -> Void)?
    open var inputStateAvailableHandler: ((any GCDevicePhysicalInput) -> Void)?
    open var inputStateQueueDepth = 16
    open var queue: DispatchQueue?

    private let stateLock = NSLock()
    private var pendingStates: [GCControllerInputState] = []
    private var lastChangedNames: Set<String> = []
    private var boundButtons: [(String, _GCButtonElementAdapter)] = []
    private var boundAxes: [(String, _GCAxisInputAdapter)] = []
    private var boundDpads: [(String, _GCDirectionPadElementAdapter)] = []
    private var boundElements: [(String, any GCPhysicalInputElement)] = []
    private var streamContinuations: [UUID: AsyncStream<GCControllerInputState>.Continuation] = [:]

    func bind(from profile: GCPhysicalInputProfile) {
        var buttons: [(String, _GCButtonElementAdapter)] = []
        var axes: [(String, _GCAxisInputAdapter)] = []
        var dpads: [(String, _GCDirectionPadElementAdapter)] = []
        var elements: [(String, any GCPhysicalInputElement)] = []
        for (name, element) in profile.namedElements.sorted(by: { $0.key < $1.key }) {
            if let dpad = element as? GCControllerDirectionPad {
                let adapter = _GCDirectionPadElementAdapter(backing: dpad)
                dpads.append((name, adapter))
                elements.append((name, adapter))
            } else if let button = element as? GCControllerButtonInput {
                let adapter = _GCButtonElementAdapter(backing: button)
                buttons.append((name, adapter))
                elements.append((name, adapter))
            } else if let axis = element as? GCControllerAxisInput {
                let adapter = _GCAxisInputAdapter(backing: axis)
                axes.append((name, adapter))
                elements.append((name, adapter))
            } else {
                elements.append((name, element))
            }
        }
        boundButtons = buttons
        boundAxes = axes
        boundDpads = dpads
        boundElements = elements
        refreshCollections()
        lastEventTimestamp = profile.lastEventTimestamp
    }

    private func refreshCollections() {
        self.buttons = GCPhysicalInputElementCollection(boundButtons.map { ($0.0, $0.1 as any GCButtonElement) })
        self.axes = GCPhysicalInputElementCollection(boundAxes.map { ($0.0, $0.1 as any GCAxisElement) })
        self.dpads = GCPhysicalInputElementCollection(boundDpads.map { ($0.0, $0.1 as any GCDirectionPadElement) })
        self.elements = GCPhysicalInputElementCollection(boundElements)
        self.switches = GCPhysicalInputElementCollection()
    }

    func recordElementChange(_ element: GCControllerElement) {
        lastEventTimestamp = ProcessInfo.processInfo.systemUptime
        lastEventLatency = 0
        var names: Set<String> = []
        for (name, bound) in boundElements {
            if let button = bound as? _GCButtonElementAdapter, button.backing === element {
                names.insert(name)
            } else if let axis = bound as? _GCAxisInputAdapter, axis.backing === element {
                names.insert(name)
            } else if let dpad = bound as? _GCDirectionPadElementAdapter, dpad.backing === element {
                names.insert(name)
            } else if let controllerElement = bound as? GCControllerElement, controllerElement === element {
                names.insert(name)
            }
        }
        lastChangedNames = names
        changedNames = names
        refreshCollections()
        let snapshot = copyState(changed: names)
        stateLock.lock()
        pendingStates.append(snapshot)
        if pendingStates.count > max(1, inputStateQueueDepth) {
            pendingStates.removeFirst(pendingStates.count - max(1, inputStateQueueDepth))
        }
        let continuations = Array(streamContinuations.values)
        stateLock.unlock()
        let handler = inputStateAvailableHandler
        let elementHandler = elementValueDidChangeHandler
        let live = self
        let dispatchQueue = queue ?? (device?.handlerQueue ?? .main)
        _gcAsync(dispatchQueue) {
            handler?(live)
            if let first = live.elements.first {
                elementHandler?(live, first)
            }
        }
        for continuation in continuations {
            continuation.yield(snapshot)
        }
    }

    private func copyState(changed: Set<String>) -> GCControllerInputState {
        let copy = GCControllerInputState()
        copy.device = device
        copy.lastEventLatency = lastEventLatency
        copy.lastEventTimestamp = lastEventTimestamp
        copy.axes = axes
        copy.dpads = dpads
        copy.buttons = buttons
        copy.elements = elements
        copy.switches = switches
        copy.changedNames = changed
        return copy
    }

    open func capture() -> any GCDevicePhysicalInputState {
        copyState(changed: [])
    }

    open func nextInputState() -> (any GCDevicePhysicalInputState & GCDevicePhysicalInputStateDiff)? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !pendingStates.isEmpty else { return nil }
        let next = pendingStates.removeFirst()
        lastChangedNames = next.changedNames
        changedNames = next.changedNames
        return next
    }

    /// iOS 16-style ordered event stream. Yields captured states as simulated
    /// input mutates the bound profile.
    public var inputStates: AsyncStream<GCControllerInputState> {
        AsyncStream { continuation in
            let id = UUID()
            self.stateLock.lock()
            self.streamContinuations[id] = continuation
            self.stateLock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.stateLock.lock()
                self?.streamContinuations.removeValue(forKey: id)
                self?.stateLock.unlock()
            }
        }
    }
}

extension GCControllerInputState: GCDevicePhysicalInputStateDiff {
    public func change(for element: any GCPhysicalInputElement) -> GCDevicePhysicalInputElementChange {
        let aliases = element.aliases
        if aliases.contains(where: { changedNames.contains($0) }) {
            return .changed
        }
        if let name = element.localizedName, changedNames.contains(name) {
            return .changed
        }
        return changedNames.isEmpty ? .unknownChange : .noChange
    }

    public func changedElements() -> NSEnumerator? {
        let changed = elements.filter { element in
            element.aliases.contains(where: { changedNames.contains($0) })
                || changedNames.contains(element.localizedName ?? "")
        }
        return changed.isEmpty ? nil : NSArray(array: Array(changed).map { $0 as Any }).objectEnumerator()
    }
}
