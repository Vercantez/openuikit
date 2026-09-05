import CoreFoundation

// MIDI thru-connection parameter block. Initialize matches MIDIThruConnection.h:
// identity channel map, note/velocity pass-through, no filters.

public struct MIDIThruConnectionParams {
    public var version: UInt32
    public var numSources: UInt32
    public var sources: (
        MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint,
        MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint
    )
    public var numDestinations: UInt32
    public var destinations: (
        MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint,
        MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint
    )
    public var channelMap: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    public var lowVelocity: UInt8
    public var highVelocity: UInt8
    public var lowNote: UInt8
    public var highNote: UInt8
    public var noteNumber: MIDITransform
    public var velocity: MIDITransform
    public var keyPressure: MIDITransform
    public var channelPressure: MIDITransform
    public var programChange: MIDITransform
    public var pitchBend: MIDITransform
    public var filterOutSysEx: UInt8
    public var filterOutMTC: UInt8
    public var filterOutBeatClock: UInt8
    public var filterOutTuneRequest: UInt8
    public var reserved2: (UInt8, UInt8, UInt8)
    public var filterOutAllControls: UInt8
    public var numControlTransforms: UInt16
    public var numMaps: UInt16
    public var reserved3: (UInt16, UInt16, UInt16, UInt16)

    public init() {
        version = 0
        numSources = 0
        sources = (
            MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(),
            MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint()
        )
        numDestinations = 0
        destinations = (
            MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(),
            MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint(), MIDIThruConnectionEndpoint()
        )
        channelMap = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
        lowVelocity = 0
        highVelocity = 127
        lowNote = 0
        highNote = 127
        noteNumber = MIDITransform(transform: .none, param: 0)
        velocity = MIDITransform(transform: .none, param: 0)
        keyPressure = MIDITransform(transform: .none, param: 0)
        channelPressure = MIDITransform(transform: .none, param: 0)
        programChange = MIDITransform(transform: .none, param: 0)
        pitchBend = MIDITransform(transform: .none, param: 0)
        filterOutSysEx = 0
        filterOutMTC = 0
        filterOutBeatClock = 0
        filterOutTuneRequest = 0
        reserved2 = (0, 0, 0)
        filterOutAllControls = 0
        numControlTransforms = 0
        numMaps = 0
        reserved3 = (0, 0, 0, 0)
    }

    public init(
        version: UInt32,
        numSources: UInt32,
        sources: (
            MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint,
            MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint
        ),
        numDestinations: UInt32,
        destinations: (
            MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint,
            MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint, MIDIThruConnectionEndpoint
        ),
        channelMap: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8),
        lowVelocity: UInt8,
        highVelocity: UInt8,
        lowNote: UInt8,
        highNote: UInt8,
        noteNumber: MIDITransform,
        velocity: MIDITransform,
        keyPressure: MIDITransform,
        channelPressure: MIDITransform,
        programChange: MIDITransform,
        pitchBend: MIDITransform,
        filterOutSysEx: UInt8,
        filterOutMTC: UInt8,
        filterOutBeatClock: UInt8,
        filterOutTuneRequest: UInt8,
        reserved2: (UInt8, UInt8, UInt8),
        filterOutAllControls: UInt8,
        numControlTransforms: UInt16,
        numMaps: UInt16,
        reserved3: (UInt16, UInt16, UInt16, UInt16)
    ) {
        self.version = version
        self.numSources = numSources
        self.sources = sources
        self.numDestinations = numDestinations
        self.destinations = destinations
        self.channelMap = channelMap
        self.lowVelocity = lowVelocity
        self.highVelocity = highVelocity
        self.lowNote = lowNote
        self.highNote = highNote
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.keyPressure = keyPressure
        self.channelPressure = channelPressure
        self.programChange = programChange
        self.pitchBend = pitchBend
        self.filterOutSysEx = filterOutSysEx
        self.filterOutMTC = filterOutMTC
        self.filterOutBeatClock = filterOutBeatClock
        self.filterOutTuneRequest = filterOutTuneRequest
        self.reserved2 = reserved2
        self.filterOutAllControls = filterOutAllControls
        self.numControlTransforms = numControlTransforms
        self.numMaps = numMaps
        self.reserved3 = reserved3
    }
}

public func MIDIThruConnectionParamsInitialize(_ inConnectionParams: UnsafeMutablePointer<MIDIThruConnectionParams>) {
    inConnectionParams.pointee = MIDIThruConnectionParams()
}

public func MIDIThruConnectionParamsSize(_ ptr: UnsafePointer<MIDIThruConnectionParams>) -> Int {
    MemoryLayout<MIDIThruConnectionParams>.size
        + Int(ptr.pointee.numControlTransforms) * MemoryLayout<MIDIControlTransform>.size
        + Int(ptr.pointee.numMaps) * MemoryLayout<MIDIValueMap>.size
}
