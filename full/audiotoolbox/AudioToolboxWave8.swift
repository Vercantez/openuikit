import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// Value-only C records used by the v2 graph and MusicSequence APIs.  These
// records deliberately contain no device or service behavior.

@frozen
public struct AUNodeRenderCallback {
    public var destNode: AUNode
    public var destInputNumber: AudioUnitElement
    public var cback: AURenderCallbackStruct

    public init() {
        destNode = 0
        destInputNumber = 0
        cback = AURenderCallbackStruct()
    }

    public init(destNode: AUNode, destInputNumber: AudioUnitElement, cback: AURenderCallbackStruct) {
        self.destNode = destNode
        self.destInputNumber = destInputNumber
        self.cback = cback
    }
}

@frozen
public struct AudioUnitConnection {
    public var sourceAudioUnit: AudioUnit?
    public var sourceOutputNumber: UInt32
    public var destInputNumber: UInt32

    public init() {
        sourceAudioUnit = nil
        sourceOutputNumber = 0
        destInputNumber = 0
    }

    public init(sourceAudioUnit: AudioUnit?, sourceOutputNumber: UInt32, destInputNumber: UInt32) {
        self.sourceAudioUnit = sourceAudioUnit
        self.sourceOutputNumber = sourceOutputNumber
        self.destInputNumber = destInputNumber
    }
}

@frozen
public struct AudioUnitProperty {
    public var mAudioUnit: AudioUnit
    public var mPropertyID: AudioUnitPropertyID
    public var mScope: AudioUnitScope
    public var mElement: AudioUnitElement

    public init(mAudioUnit: AudioUnit, mPropertyID: AudioUnitPropertyID, mScope: AudioUnitScope, mElement: AudioUnitElement) {
        self.mAudioUnit = mAudioUnit
        self.mPropertyID = mPropertyID
        self.mScope = mScope
        self.mElement = mElement
    }
}

@frozen
public struct MixerDistanceParams {
    public var mReferenceDistance: Float32
    public var mMaxDistance: Float32
    public var mMaxAttenuation: Float32

    public init() {
        mReferenceDistance = 0
        mMaxDistance = 0
        mMaxAttenuation = 0
    }

    public init(mReferenceDistance: Float32, mMaxDistance: Float32, mMaxAttenuation: Float32) {
        self.mReferenceDistance = mReferenceDistance
        self.mMaxDistance = mMaxDistance
        self.mMaxAttenuation = mMaxAttenuation
    }
}

@frozen
public struct NoteParamsControlValue {
    public var mID: AudioUnitParameterID
    public var mValue: AudioUnitParameterValue

    public init() {
        mID = 0
        mValue = 0
    }

    public init(mID: AudioUnitParameterID, mValue: AudioUnitParameterValue) {
        self.mID = mID
        self.mValue = mValue
    }
}

@frozen
public struct AudioUnitExternalBuffer {
    public var buffer: UnsafeMutablePointer<UInt8>
    public var size: UInt32

    public init(buffer: UnsafeMutablePointer<UInt8>, size: UInt32) {
        self.buffer = buffer
        self.size = size
    }
}

@frozen
public struct ExtendedTempoEvent {
    public var bpm: Float64

    public init() { bpm = 0 }
    public init(bpm: Float64) { self.bpm = bpm }
}

@frozen
public struct MusicTrackLoopInfo {
    public var loopDuration: MusicTimeStamp
    public var numberOfLoops: Int32

    public init() {
        loopDuration = 0
        numberOfLoops = 0
    }

    public init(loopDuration: MusicTimeStamp, numberOfLoops: Int32) {
        self.loopDuration = loopDuration
        self.numberOfLoops = numberOfLoops
    }
}

#if canImport(CoreFoundation)
@frozen
public struct AUPresetEvent {
    public var scope: AudioUnitScope
    public var element: AudioUnitElement
    public var preset: Unmanaged<CFPropertyList>

    public init(scope: AudioUnitScope, element: AudioUnitElement, preset: Unmanaged<CFPropertyList>) {
        self.scope = scope
        self.element = element
        self.preset = preset
    }
}
#endif
