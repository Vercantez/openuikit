import Foundation

internal enum AUAudioUnitError: Error, Sendable {
    case unavailable(Int32)
}

open class AUAudioUnitPreset: NSObject {
    public var number: Int = 0
    public var name: String = ""

    public override init() {
        super.init()
    }
}

open class AUAudioUnitBusArray: NSObject {
    public private(set) var count: Int
    public var isCountChangeable: Bool { false }
    public private(set) var busType: AUAudioUnitBusType
    public internal(set) weak var ownerAudioUnit: AUAudioUnit?
    private var busses: [AUAudioUnitBus]

    public override init() {
        count = 0
        busType = .output
        busses = []
        super.init()
    }

    internal init(busCount: Int, busType: AUAudioUnitBusType = .output, owner: AUAudioUnit? = nil) {
        count = busCount
        self.busType = busType
        ownerAudioUnit = owner
        busses = (0..<busCount).map { index in
            let bus = AUAudioUnitBus(busType: busType)
            bus.index = index
            return bus
        }
        super.init()
        for bus in busses {
            bus.ownerAudioUnit = owner
        }
    }

    public init(audioUnit: AUAudioUnit, busType: AUAudioUnitBusType) {
        count = 0
        self.busType = busType
        ownerAudioUnit = audioUnit
        busses = []
        super.init()
    }

    public init(audioUnit: AUAudioUnit, busType: AUAudioUnitBusType, busses: [AUAudioUnitBus]) {
        count = busses.count
        self.busType = busType
        ownerAudioUnit = audioUnit
        self.busses = busses
        super.init()
        for (index, bus) in busses.enumerated() {
            bus.index = index
            bus.ownerAudioUnit = audioUnit
        }
    }

    open subscript(index: Int) -> AUAudioUnitBus {
        busses[index]
    }

    open func setBusCount(_ count: Int) throws {
        _ = count
        throw AUAudioUnitError.unavailable(kAudioUnitErr_PropertyNotWritable)
    }
}

open class AUAudioUnitBus: NSObject {
    public private(set) var busType: AUAudioUnitBusType
    public var isEnabled: Bool = false
    public var name: String?
    public var index: Int = 0
    public var shouldAllocateBuffer = true
    public var maximumChannelCount: AUAudioChannelCount = 2
    public var contextPresentationLatency: TimeInterval = 0
    public weak var ownerAudioUnit: AUAudioUnit?
    public var supportedChannelCounts: [NSNumber]? { [1, 2] }
    public var supportedChannelLayoutTags: [NSNumber]? { nil }

    public init(busType: AUAudioUnitBusType) {
        self.busType = busType
        super.init()
    }
}

open class AUParameterNode: NSObject {
    public var identifier: String = ""
    public var displayName: String = ""
    public var keyPath: String { identifier }
    public var implementorValueObserver: AUImplementorValueObserver = { _, _ in }
    public var implementorValueProvider: AUImplementorValueProvider = { parameter in parameter.value }
    public var implementorStringFromValueCallback: AUImplementorStringFromValueCallback = { parameter, pointer in
        let observed = pointer?.pointee ?? parameter.value
        return String(observed)
    }
    public var implementorValueFromStringCallback: AUImplementorValueFromStringCallback = { _, string in
        AUValue(string) ?? 0
    }
    public var implementorDisplayNameWithLengthCallback: AUImplementorDisplayNameWithLengthCallback = { node, maximumLength in
        String(node.displayName.prefix(max(maximumLength, 0)))
    }

    private var observerTokens: [UnsafeMutableRawPointer] = []

    public override init() {
        super.init()
    }

    open func displayName(withLength maximumLength: Int) -> String {
        implementorDisplayNameWithLengthCallback(self, maximumLength)
    }

    open func token(byAddingParameterObserver observer: @escaping AUParameterObserver) -> AUParameterObserverToken {
        _ = observer
        let token = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
        observerTokens.append(token)
        return token
    }

    open func token(byAddingParameterAutomationObserver observer: @escaping AUParameterAutomationObserver) -> AUParameterObserverToken {
        _ = observer
        let token = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
        observerTokens.append(token)
        return token
    }

    open func token(byAddingParameterRecordingObserver observer: @escaping AUParameterRecordingObserver) -> AUParameterObserverToken {
        _ = observer
        let token = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
        observerTokens.append(token)
        return token
    }

    open func removeParameterObserver(_ token: AUParameterObserverToken) {
        if let index = observerTokens.firstIndex(of: token) {
            observerTokens.remove(at: index)
            token.deallocate()
        }
    }

    deinit {
        for token in observerTokens {
            token.deallocate()
        }
    }
}

open class AUParameter: AUParameterNode {
    public var address: AUParameterAddress = 0
    public var minValue: AUValue = 0
    public var maxValue: AUValue = 1
    public var value: AUValue = 0 {
        didSet {
            implementorValueObserver(self, value)
        }
    }
    public var unit: AudioUnitParameterUnit = .generic
    public var unitName: String?
    public var flags: AudioUnitParameterOptions = []
    public var valueStrings: [String]?
    public var dependentParameters: [NSNumber]?

    public func setValue(_ value: AUValue, originator: AUParameterObserverToken?) {
        _ = originator
        self.value = min(max(value, minValue), maxValue)
    }

    public func setValue(_ value: AUValue, originator: AUParameterObserverToken?, atHostTime hostTime: UInt64) {
        _ = hostTime
        setValue(value, originator: originator)
    }

    public func setValue(
        _ value: AUValue,
        originator: AUParameterObserverToken?,
        atHostTime hostTime: UInt64,
        eventType: AUParameterAutomationEventType
    ) {
        _ = eventType
        setValue(value, originator: originator, atHostTime: hostTime)
    }

    public func string(fromValue value: UnsafePointer<AUValue>?) -> String {
        implementorStringFromValueCallback(self, value)
    }

    public func value(from string: String) -> AUValue {
        implementorValueFromStringCallback(self, string)
    }
}

open class AUParameterGroup: AUParameterNode {
    public var children: [AUParameterNode] = []
    public var allParameters: [AUParameter] {
        children.flatMap { node -> [AUParameter] in
            if let parameter = node as? AUParameter {
                return [parameter]
            }
            if let group = node as? AUParameterGroup {
                return group.allParameters
            }
            return []
        }
    }
}

open class AUParameterTree: AUParameterGroup {
    open class func createParameter(
        withIdentifier identifier: String,
        name: String,
        address: AUParameterAddress,
        min: AUValue,
        max: AUValue,
        unit: AudioUnitParameterUnit,
        unitName: String?,
        flags: AudioUnitParameterOptions = [],
        valueStrings: [String]?,
        dependentParameters: [NSNumber]?
    ) -> AUParameter {
        let parameter = AUParameter()
        parameter.identifier = identifier
        parameter.displayName = name
        parameter.address = address
        parameter.minValue = min
        parameter.maxValue = max
        parameter.unit = unit
        parameter.unitName = unitName
        parameter.flags = flags
        parameter.valueStrings = valueStrings
        parameter.dependentParameters = dependentParameters
        return parameter
    }

    open class func createGroup(
        withIdentifier identifier: String,
        name: String,
        children: [AUParameterNode]
    ) -> AUParameterGroup {
        let group = AUParameterGroup()
        group.identifier = identifier
        group.displayName = name
        group.children = children
        return group
    }

    open class func createGroupTemplate(_ children: [AUParameterNode]) -> AUParameterGroup {
        createGroup(withIdentifier: "", name: "", children: children)
    }

    open class func createGroup(
        fromTemplate templateGroup: AUParameterGroup,
        identifier: String,
        name: String,
        addressOffset: AUParameterAddress
    ) -> AUParameterGroup {
        _ = addressOffset
        return createGroup(withIdentifier: identifier, name: name, children: templateGroup.children)
    }

    open class func createTree(withChildren children: [AUParameterNode]) -> AUParameterTree {
        let tree = AUParameterTree()
        tree.children = children
        return tree
    }

    open func parameter(withAddress address: AUParameterAddress) -> AUParameter? {
        allParameters.first { $0.address == address }
    }

    open func parameter(withID paramID: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement) -> AUParameter? {
        _ = scope
        _ = element
        return parameter(withAddress: AUParameterAddress(paramID))
    }
}

/// Swift-only AUAudioUnit surface. Software mixer / generator / generic output
/// units instantiate in-process. RemoteIO, VoiceProcessingIO, and empty
/// descriptions fail closed: Linux has no hardware I/O or plug-in host.
open class AUAudioUnit: NSObject {
    public let componentDescription: AudioComponentDescription
    public private(set) var renderResourcesAllocated = false
    public var maximumFramesToRender: AUAudioFrameCount = 512
    public var renderQuality: Int = 0
    public var shouldBypassEffect = false
    public var renderingOffline = true
    public private(set) var running = false
    public var audioUnitName: String?
    public var manufacturerName: String? = "Apple"
    public var componentName: String?
    public var audioUnitShortName: String?
    public var componentVersion: UInt32 { 0 }
    public var latency: TimeInterval { 0 }
    public var tailTime: TimeInterval { 0 }
    public var canPerformInput: Bool { false }
    public var canPerformOutput: Bool {
        componentDescription.componentType == kAudioUnitType_Output
    }
    public var canProcessInPlace: Bool { true }
    public var inputEnabled = false
    public var outputEnabled = true
    public var component: AudioComponent {
        var description = componentDescription
        return AudioComponentFindNext(nil, &description) ?? AudioComponent(bitPattern: 1)!
    }

    private let inputBusArray: AUAudioUnitBusArray
    private let outputBusArray: AUAudioUnitBusArray
    public let parameterTree = AUParameterTree()

    public var inputBusses: AUAudioUnitBusArray { inputBusArray }
    public var outputBusses: AUAudioUnitBusArray { outputBusArray }

    public var contextName: String?
    public var channelMap: [NSNumber]?
    public var currentPreset: AUAudioUnitPreset?
    public var factoryPresets: [AUAudioUnitPreset]? { nil }
    public var userPresets: [AUAudioUnitPreset] { [] }
    public var fullState: [String: Any]?
    public var fullStateForDocument: [String: Any]?
    public var allParameterValues: Bool { true }
    public var musicDeviceOrEffect: Bool {
        componentDescription.componentType == kAudioUnitType_MusicDevice
            || componentDescription.componentType == kAudioUnitType_MusicEffect
    }
    public var providesUserInterface: Bool { false }
    public var supportsMPE: Bool { false }
    public var supportsUserPresets: Bool { false }
    public var channelCapabilities: [NSNumber]? { nil }
    public var MIDIOutputNames: [String] { [] }
    public var virtualMIDICableCount: Int { 0 }
    public var MIDIOutputBufferSizeHint: Int = 0
    public var migrateFromPlugin: [String] { [] }

    private var renderObserverTokens: [Int] = []
    private var nextRenderObserverToken = 1

    public static func isHostedSoftwareUnit(_ description: AudioComponentDescription) -> Bool {
        if description.componentSubType == kAudioUnitSubType_RemoteIO
            || description.componentSubType == kAudioUnitSubType_VoiceProcessingIO
        {
            return false
        }
        if description.componentType == 0 && description.componentSubType == 0 {
            return false
        }
        return description.componentType == kAudioUnitType_Output
            || description.componentType == kAudioUnitType_Mixer
            || description.componentType == kAudioUnitType_Generator
            || description.componentSubType == kAudioUnitSubType_GenericOutput
            || description.componentSubType == kAudioUnitSubType_MultiChannelMixer
            || description.componentSubType == kAudioUnitSubType_ScheduledSoundPlayer
    }

    public init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        _ = options
        self.componentDescription = componentDescription
        let inputs = (componentDescription.componentType == kAudioUnitType_Mixer) ? 2 : 1
        inputBusArray = AUAudioUnitBusArray(busCount: inputs, busType: .input)
        outputBusArray = AUAudioUnitBusArray(busCount: 1, busType: .output)
        super.init()
        inputBusArray.ownerAudioUnit = self
        outputBusArray.ownerAudioUnit = self
        for bus in 0..<inputBusArray.count {
            inputBusArray[bus].ownerAudioUnit = self
        }
        outputBusArray[0].ownerAudioUnit = self
        guard Self.isHostedSoftwareUnit(componentDescription) else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(kAudioUnitErr_ComponentManagerNotSupported),
                userInfo: [
                    NSLocalizedDescriptionKey: "Audio Unit plug-ins are unavailable on this Linux host"
                ]
            )
        }
        switch componentDescription.componentSubType {
        case kAudioUnitSubType_GenericOutput:
            audioUnitName = "GenericOutput"
            componentName = "GenericOutput"
            audioUnitShortName = "genr"
        case kAudioUnitSubType_MultiChannelMixer:
            audioUnitName = "MultiChannelMixer"
            componentName = "MultiChannelMixer"
            audioUnitShortName = "mcmx"
        case kAudioUnitSubType_ScheduledSoundPlayer:
            audioUnitName = "ScheduledSoundPlayer"
            componentName = "ScheduledSoundPlayer"
            audioUnitShortName = "sspl"
        default:
            audioUnitName = "SoftwareAudioUnit"
            componentName = "SoftwareAudioUnit"
        }
    }

    public convenience init(componentDescription: AudioComponentDescription) throws {
        try self.init(componentDescription: componentDescription, options: [])
    }

    open class func instantiate(
        with componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) async throws -> AUAudioUnit {
        try AUAudioUnit(componentDescription: componentDescription, options: options)
    }

    open func allocateRenderResources() throws {
        guard Self.isHostedSoftwareUnit(componentDescription) else {
            throw AUAudioUnitError.unavailable(kAudioUnitErr_FailedInitialization)
        }
        renderResourcesAllocated = true
    }

    open func deallocateRenderResources() {
        renderResourcesAllocated = false
    }

    open func reset() {
        running = false
    }

    open func startHardware() throws {
        throw AUAudioUnitError.unavailable(kAudioUnitErr_FailedInitialization)
    }

    open func stopHardware() {
        running = false
    }

    open func setRenderResourcesAllocated(_ flag: Bool) {
        renderResourcesAllocated = flag
    }

    open func parametersForOverview(withCount count: Int) -> [NSNumber] {
        Array(parameterTree.children.prefix(count).compactMap { node in
            (node as? AUParameter).map { NSNumber(value: $0.address) }
        })
    }

    open func tokenByAddingRenderObserver(_ observer: @escaping (Int) -> Void) -> Int {
        _ = observer
        let token = nextRenderObserverToken
        nextRenderObserverToken += 1
        renderObserverTokens.append(token)
        return token
    }

    open func removeRenderObserver(_ token: Int) {
        renderObserverTokens.removeAll { $0 == token }
    }

    open func saveUserPreset(_ preset: AUAudioUnitPreset) throws {
        _ = preset
        throw AUAudioUnitError.unavailable(kAudioUnitErr_PropertyNotInUse)
    }

    open func deleteUserPreset(_ preset: AUAudioUnitPreset) throws {
        _ = preset
        throw AUAudioUnitError.unavailable(kAudioUnitErr_PropertyNotInUse)
    }
}
