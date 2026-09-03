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
    public private(set) var count: Int = 0

    public override init() {
        super.init()
    }

    public var isCountChangeable: Bool { false }

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

/// Swift-only AUAudioUnit surface. Instantiation fails closed: Linux has no
/// Audio Unit plug-in host, hardware I/O, or v3 extension scanner.
open class AUAudioUnit: NSObject {
    public let componentDescription: AudioComponentDescription
    public private(set) var renderResourcesAllocated = false
    public var maximumFramesToRender: AUAudioFrameCount = 0
    public var audioUnitName: String? { nil }
    public var manufacturerName: String? { nil }
    public var componentName: String? { nil }
    public var audioUnitShortName: String? { nil }
    public var componentVersion: UInt32 { 0 }
    public var component: AudioComponent {
        AudioComponent(bitPattern: 1)!
    }

    private let inputBusArray = AUAudioUnitBusArray()
    private let outputBusArray = AUAudioUnitBusArray()

    public var inputBusses: AUAudioUnitBusArray { inputBusArray }
    public var outputBusses: AUAudioUnitBusArray { outputBusArray }

    public init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        _ = options
        self.componentDescription = componentDescription
        super.init()
        throw NSError(
            domain: NSOSStatusErrorDomain,
            code: Int(kAudioUnitErr_ComponentManagerNotSupported),
            userInfo: [
                NSLocalizedDescriptionKey: "Audio Unit plug-ins are unavailable on this Linux host"
            ]
        )
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
        throw AUAudioUnitError.unavailable(kAudioUnitErr_FailedInitialization)
    }

    open func deallocateRenderResources() {
        renderResourcesAllocated = false
    }

    open func reset() {}
}
