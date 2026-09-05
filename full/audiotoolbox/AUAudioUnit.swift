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

    public override init() {
        count = 0
        super.init()
    }

    internal init(busCount: Int) {
        count = busCount
        super.init()
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

    public init(busType: AUAudioUnitBusType) {
        self.busType = busType
        super.init()
    }
}

open class AUParameterNode: NSObject {
    public var identifier: String = ""
    public var displayName: String = ""

    public override init() {
        super.init()
    }
}

open class AUParameter: AUParameterNode {
    public var address: AUParameterAddress = 0
    public var minValue: AUValue = 0
    public var maxValue: AUValue = 1
    public var value: AUValue = 0
}

open class AUParameterGroup: AUParameterNode {
    public var children: [AUParameterNode] = []
}

open class AUParameterTree: AUParameterGroup {}

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
        inputBusArray = AUAudioUnitBusArray(busCount: inputs)
        outputBusArray = AUAudioUnitBusArray(busCount: 1)
        super.init()
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
}
