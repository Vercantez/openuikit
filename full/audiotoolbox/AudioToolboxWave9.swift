import Foundation

// Pure value records from AudioToolbox's format-property and Audio Unit APIs.
// They perform no device I/O and retain no pointed-to storage.

@frozen
public struct AudioUnitMeterClipping: Sendable {
    public var peakValueSinceLastCall: Float32
    public var sawInfinity: UInt8
    public var sawNotANumber: UInt8

    public init(peakValueSinceLastCall: Float32, sawInfinity: UInt8, sawNotANumber: UInt8) {
        self.peakValueSinceLastCall = peakValueSinceLastCall
        self.sawInfinity = sawInfinity
        self.sawNotANumber = sawNotANumber
    }

    public init() { self.init(peakValueSinceLastCall: 0, sawInfinity: 0, sawNotANumber: 0) }
}

@frozen
public struct MusicEventUserData: Sendable {
    public var length: UInt32
    public var data: UInt8

    public init(length: UInt32, data: UInt8) {
        self.length = length
        self.data = data
    }

    public init() { self.init(length: 0, data: 0) }
}
