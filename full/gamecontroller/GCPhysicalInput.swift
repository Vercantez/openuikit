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

open class GCControllerInputState: NSObject, GCDevicePhysicalInputState {
    public weak var device: (any GCDevice)?
    open var lastEventLatency: TimeInterval = 0
    open var lastEventTimestamp: TimeInterval = 0
    open var axes = GCPhysicalInputElementCollection<any GCAxisElement>()
    open var dpads = GCPhysicalInputElementCollection<any GCDirectionPadElement>()
    open var buttons = GCPhysicalInputElementCollection<any GCButtonElement>()
    open var elements = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
    open var switches = GCPhysicalInputElementCollection<any GCSwitchElement>()

    public subscript(key: String) -> (any GCPhysicalInputElement)? {
        elements[key]
    }
}

open class GCControllerLiveInput: GCControllerInputState, GCDevicePhysicalInput, GCDevicePhysicalInputStateDiff {
    open var unmapped: GCControllerLiveInput?
    open var elementValueDidChangeHandler: ((any GCDevicePhysicalInput, any GCPhysicalInputElement) -> Void)?
    open var inputStateAvailableHandler: ((any GCDevicePhysicalInput) -> Void)?
    open var inputStateQueueDepth = 0
    open var queue: DispatchQueue?

    open func capture() -> any GCDevicePhysicalInputState {
        let copy = GCControllerInputState()
        copy.device = device
        copy.lastEventLatency = lastEventLatency
        copy.lastEventTimestamp = lastEventTimestamp
        return copy
    }

    open func nextInputState() -> (any GCDevicePhysicalInputState & GCDevicePhysicalInputStateDiff)? {
        nil
    }

    open func change(for element: any GCPhysicalInputElement) -> GCDevicePhysicalInputElementChange {
        _ = element
        return .unknownChange
    }

    open func changedElements() -> NSEnumerator? {
        nil
    }
}
