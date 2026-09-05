import CoreFoundation

// Universal MIDI Packet constructors. Bit layouts follow the MIDI 2.0 UMP spec
// (message type in bits 31:28, group in 27:24) which Apple's CoreMIDI overlay implements.

private func midiUMP32(type: UInt32, group: UInt8, rest: UInt32) -> MIDIMessage_32 {
    ((type & 0xF) << 28) | (UInt32(group & 0xF) << 24) | (rest & 0x00FF_FFFF)
}

private func midiUMP64(type: UInt32, group: UInt8, status: UInt8, channel: UInt8, byte2: UInt8, byte3: UInt8, word1: UInt32) -> MIDIMessage_64 {
    let word0 =
        ((type & 0xF) << 28)
        | (UInt32(group & 0xF) << 24)
        | (UInt32(status & 0xF) << 20)
        | (UInt32(channel & 0xF) << 16)
        | (UInt32(byte2) << 8)
        | UInt32(byte3)
    return MIDIMessage_64(word0: word0, word1: word1)
}

private func midiUMP128(type: UInt32, group: UInt8, statusHigh: UInt8, data1: UInt16, data2: UInt32, data3: UInt32, data4: UInt32) -> MIDIMessage_128 {
    let word0 =
        ((type & 0xF) << 28)
        | (UInt32(group & 0xF) << 24)
        | (UInt32(statusHigh) << 16)
        | UInt32(data1)
    return MIDIMessage_128(word0: word0, word1: data2, word2: data3, word3: data4)
}

public func MIDI1UPChannelVoiceMessage(_ group: UInt8, _ status: UInt8, _ channel: UInt8, _ data1: UInt8, _ data2: UInt8) -> MIDIMessage_32 {
    midiUMP32(
        type: 0x2,
        group: group,
        rest: (UInt32(status & 0xF) << 20) | (UInt32(channel & 0xF) << 16) | (UInt32(data1) << 8) | UInt32(data2)
    )
}

public func MIDI1UPNoteOff(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ velocity: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0x8, channel, noteNumber, velocity)
}

public func MIDI1UPNoteOn(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ velocity: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0x9, channel, noteNumber, velocity)
}

public func MIDI1UPPolyPressure(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ pressure: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0xA, channel, noteNumber, pressure)
}

public func MIDI1UPControlChange(_ group: UInt8, _ channel: UInt8, _ index: UInt8, _ data: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0xB, channel, index, data)
}

public func MIDI1UPProgramChange(_ group: UInt8, _ channel: UInt8, _ program: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0xC, channel, program, 0)
}

public func MIDI1UPChannelPressure(_ group: UInt8, _ channel: UInt8, _ value: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0xD, channel, value, 0)
}

public func MIDI1UPPitchBend(_ group: UInt8, _ channel: UInt8, _ lsb: UInt8, _ msb: UInt8) -> MIDIMessage_32 {
    MIDI1UPChannelVoiceMessage(group, 0xE, channel, lsb, msb)
}

public func MIDI1UPSystemCommon(_ group: UInt8, _ status: UInt8, _ byte1: UInt8, _ byte2: UInt8) -> MIDIMessage_32 {
    midiUMP32(
        type: 0x1,
        group: group,
        rest: (UInt32(status) << 16) | (UInt32(byte1) << 8) | UInt32(byte2)
    )
}

public func MIDI1UPSysEx(
    _ group: UInt8, _ status: UInt8, _ bytesUsed: UInt8,
    _ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8, _ byte4: UInt8, _ byte5: UInt8, _ byte6: UInt8
) -> MIDIMessage_64 {
    let word0 =
        (UInt32(0x3) << 28)
        | (UInt32(group & 0xF) << 24)
        | (UInt32(status & 0xF) << 20)
        | (UInt32(bytesUsed & 0xF) << 16)
        | (UInt32(byte1) << 8)
        | UInt32(byte2)
    let word1 = (UInt32(byte3) << 24) | (UInt32(byte4) << 16) | (UInt32(byte5) << 8) | UInt32(byte6)
    return MIDIMessage_64(word0: word0, word1: word1)
}

public func MIDI1UPSysExArray(
    _ group: UInt8,
    _ status: UInt8,
    _ begin: UnsafePointer<UInt8>!,
    _ end: UnsafePointer<UInt8>!
) -> MIDIMessage_64 {
    var bytes = [UInt8](repeating: 0, count: 6)
    if let begin, let end {
        let count = min(6, end - begin)
        for i in 0..<count { bytes[i] = begin[i] }
        return MIDI1UPSysEx(group, status, UInt8(count), bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5])
    }
    return MIDI1UPSysEx(group, status, 0, 0, 0, 0, 0, 0, 0)
}

public func MIDI2ChannelVoiceMessage(_ group: UInt8, _ status: UInt8, _ channel: UInt8, _ index: UInt16, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: status, channel: channel, byte2: UInt8(index >> 8), byte3: UInt8(index & 0xFF), word1: value)
}

public func MIDI2NoteOff(
    _ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8,
    _ attributeType: UInt8, _ attributeData: UInt16, _ velocity: UInt16
) -> MIDIMessage_64 {
    midiUMP64(
        type: 0x4, group: group, status: 0x8, channel: channel,
        byte2: noteNumber, byte3: attributeType,
        word1: (UInt32(velocity) << 16) | UInt32(attributeData)
    )
}

public func MIDI2NoteOn(
    _ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8,
    _ attributeType: UInt8, _ attributeData: UInt16, _ velocity: UInt16
) -> MIDIMessage_64 {
    midiUMP64(
        type: 0x4, group: group, status: 0x9, channel: channel,
        byte2: noteNumber, byte3: attributeType,
        word1: (UInt32(velocity) << 16) | UInt32(attributeData)
    )
}

public func MIDI2PolyPressure(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0xA, channel: channel, byte2: noteNumber, byte3: 0, word1: value)
}

public func MIDI2ControlChange(_ group: UInt8, _ channel: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0xB, channel: channel, byte2: index, byte3: 0, word1: value)
}

public func MIDI2ProgramChange(
    _ group: UInt8, _ channel: UInt8, _ bankIsValid: Bool,
    _ program: UInt8, _ bank_msb: UInt8, _ bank_lsb: UInt8
) -> MIDIMessage_64 {
    let options: UInt8 = bankIsValid ? 1 : 0
    let word1 = (UInt32(program) << 24) | (UInt32(bank_msb) << 8) | UInt32(bank_lsb)
    return midiUMP64(type: 0x4, group: group, status: 0xC, channel: channel, byte2: options, byte3: 0, word1: word1)
}

public func MIDI2ChannelPressure(_ group: UInt8, _ channel: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0xD, channel: channel, byte2: 0, byte3: 0, word1: value)
}

public func MIDI2PitchBend(_ group: UInt8, _ channel: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0xE, channel: channel, byte2: 0, byte3: 0, word1: value)
}

public func MIDI2PerNoteManagment(
    _ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8,
    _ detachPNCs: Bool, _ resetPNCsToDefault: Bool
) -> MIDIMessage_64 {
    var flags: UInt8 = 0
    if resetPNCsToDefault { flags |= 1 }
    if detachPNCs { flags |= 2 }
    return midiUMP64(type: 0x4, group: group, status: 0xF, channel: channel, byte2: noteNumber, byte3: flags, word1: 0)
}

public func MIDI2PerNotePitchBend(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x6, channel: channel, byte2: noteNumber, byte3: 0, word1: value)
}

public func MIDI2RegisteredPNC(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x0, channel: channel, byte2: noteNumber, byte3: index, word1: value)
}

public func MIDI2AssignablePNC(_ group: UInt8, _ channel: UInt8, _ noteNumber: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x1, channel: channel, byte2: noteNumber, byte3: index, word1: value)
}

public func MIDI2RegisteredControl(_ group: UInt8, _ channel: UInt8, _ bank: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x2, channel: channel, byte2: bank, byte3: index, word1: value)
}

public func MIDI2AssignableControl(_ group: UInt8, _ channel: UInt8, _ bank: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x3, channel: channel, byte2: bank, byte3: index, word1: value)
}

public func MIDI2RelRegisteredControl(_ group: UInt8, _ channel: UInt8, _ bank: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x4, channel: channel, byte2: bank, byte3: index, word1: value)
}

public func MIDI2RelAssignableControl(_ group: UInt8, _ channel: UInt8, _ bank: UInt8, _ index: UInt8, _ value: UInt32) -> MIDIMessage_64 {
    midiUMP64(type: 0x4, group: group, status: 0x5, channel: channel, byte2: bank, byte3: index, word1: value)
}

public func MIDINoOpMessage() -> MIDIMessage_32 {
    midiUMP32(type: 0x0, group: 0, rest: 0)
}

public func MIDIJitterReductionClockMessage(_ senderClockTime: UInt16) -> MIDIMessage_32 {
    midiUMP32(type: 0x0, group: 0, rest: (UInt32(1) << 20) | UInt32(senderClockTime))
}

public func MIDIJitterReductionTimestampMessage(_ senderClockTimestamp: UInt16) -> MIDIMessage_32 {
    midiUMP32(type: 0x0, group: 0, rest: (UInt32(2) << 20) | UInt32(senderClockTimestamp))
}

public func MIDIDeltaClockstampTicksPerQuarterNoteMessage(_ ticksPerQuarterNote: UInt16) -> MIDIMessage_32 {
    midiUMP32(type: 0x0, group: 0, rest: (UInt32(3) << 20) | UInt32(ticksPerQuarterNote))
}

public func MIDITicksSinceLastEventMessage(_ ticksSinceLastEvent: UInt32) -> MIDIMessage_32 {
    midiUMP32(type: 0x0, group: 0, rest: (UInt32(4) << 20) | (ticksSinceLastEvent & 0x000F_FFFF))
}

public func MIDIMessageTypeForUPWord(_ word: UInt32) -> MIDIMessageType {
    MIDIMessageType(rawValue: (word >> 28) & 0xF) ?? .invalid
}

public func MIDI2StreamMessage(
    _ format: UMPStreamMessageFormat,
    _ status: UMPStreamMessageStatus,
    _ data1: UInt16,
    _ data2: UInt32,
    _ data3: UInt32,
    _ data4: UInt32
) -> MIDIMessage_128 {
    midiUMP128(type: 0xF, group: 0, statusHigh: (format.rawValue << 4) | UInt8(status.rawValue & 0xFF), data1: data1, data2: data2, data3: data3, data4: data4)
}

public func MIDI2StreamMessageFromData(
    _ format: UMPStreamMessageFormat,
    _ status: UMPStreamMessageStatus,
    _ data: UnsafePointer<UInt8>!,
    _ length: Int
) -> MIDIMessage_128 {
    var packed: [UInt32] = [0, 0, 0]
    if let data {
        var bytes = [UInt8](repeating: 0, count: 12)
        let n = min(12, max(0, length))
        for i in 0..<n { bytes[i] = data[i] }
        packed[0] = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
        packed[1] = (UInt32(bytes[4]) << 24) | (UInt32(bytes[5]) << 16) | (UInt32(bytes[6]) << 8) | UInt32(bytes[7])
        packed[2] = (UInt32(bytes[8]) << 24) | (UInt32(bytes[9]) << 16) | (UInt32(bytes[10]) << 8) | UInt32(bytes[11])
    }
    return MIDI2StreamMessage(format, status, 0, packed[0], packed[1], packed[2])
}

public func MIDI2EndpointDiscoveryMessage(
    _ versionMajor: UInt8, _ versionMinor: UInt8,
    _ endpointInfoRequest: Bool, _ deviceIdentityRequest: Bool,
    _ endpointNameRequest: Bool, _ productInstanceIDRequest: Bool,
    _ streamConfigurationRequest: Bool
) -> MIDIMessage_128 {
    var filter: UInt8 = 0
    if endpointInfoRequest { filter |= 1 }
    if deviceIdentityRequest { filter |= 2 }
    if endpointNameRequest { filter |= 4 }
    if productInstanceIDRequest { filter |= 8 }
    if streamConfigurationRequest { filter |= 16 }
    let data1 = (UInt16(versionMajor) << 8) | UInt16(versionMinor)
    return MIDI2StreamMessage(.complete, .endpointDiscovery, data1, UInt32(filter) << 24, 0, 0)
}

public func MIDI2EndpointInfoNotificationMessage(
    _ versionMajor: UInt8, _ versionMinor: UInt8,
    _ staticFunctionBlocks: Bool, _ numberOfFunctionBlocks: UInt8,
    _ m1: Bool, _ m2: Bool, _ receiveJRTimestamp: Bool, _ transmitJRTimestamp: Bool
) -> MIDIMessage_128 {
    var flags: UInt8 = 0
    if staticFunctionBlocks { flags |= 0x80 }
    flags |= numberOfFunctionBlocks & 0x7F
    var proto: UInt8 = 0
    if m1 { proto |= 1 }
    if m2 { proto |= 2 }
    if receiveJRTimestamp { proto |= 4 }
    if transmitJRTimestamp { proto |= 8 }
    let data1 = (UInt16(versionMajor) << 8) | UInt16(versionMinor)
    return MIDI2StreamMessage(.complete, .endpointInfoNotification, data1, (UInt32(flags) << 24) | (UInt32(proto) << 16), 0, 0)
}

public func MIDI2EndpointDeviceIdentityNotificationMessage(
    _ deviceManufacturer1: MIDIUInteger7, _ deviceManufacturer2: MIDIUInteger7, _ deviceManufacturer3: MIDIUInteger7,
    _ deviceFamily: MIDIUInteger14, _ deviceFamilyModel: MIDIUInteger14, _ revisionLevel: MIDIUInteger28
) -> MIDIMessage_128 {
    let word1 = (UInt32(deviceManufacturer1) << 16) | (UInt32(deviceManufacturer2) << 8) | UInt32(deviceManufacturer3)
    let word2 = (UInt32(deviceFamily) << 16) | UInt32(deviceFamilyModel)
    return MIDI2StreamMessage(.complete, .deviceIdentityNotification, 0, word1, word2, revisionLevel)
}

public func MIDI2EndpointNameNotificationMessage(_ format: UMPStreamMessageFormat, _ data: UnsafePointer<CChar>!, _ length: Int) -> MIDIMessage_128 {
    MIDI2StreamMessageFromData(format, .endpointNameNotification, data.map { UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self) }, length)
}

public func MIDI2EndpointProductInstanceIDNotificationMessage(_ format: UMPStreamMessageFormat, _ data: UnsafePointer<CChar>!, _ length: Int) -> MIDIMessage_128 {
    MIDI2StreamMessageFromData(format, .productInstanceIDNotification, data.map { UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self) }, length)
}

public func MIDI2StreamConfigurationRequestMessage(_ protocol: UInt8, _ receiveJRTimestamp: Bool, _ transmitJRTimestamp: Bool) -> MIDIMessage_128 {
    var flags: UInt8 = `protocol`
    if receiveJRTimestamp { flags |= 0x02 }
    if transmitJRTimestamp { flags |= 0x04 }
    return MIDI2StreamMessage(.complete, .streamConfigurationRequest, UInt16(flags) << 8, 0, 0, 0)
}

public func MIDI2StreamConfigurationNotificationMessage(_ protocol: UInt8, _ receiveJRTimestamp: Bool, _ transmitJRTimestamp: Bool) -> MIDIMessage_128 {
    var flags: UInt8 = `protocol`
    if receiveJRTimestamp { flags |= 0x02 }
    if transmitJRTimestamp { flags |= 0x04 }
    return MIDI2StreamMessage(.complete, .streamConfigurationNotification, UInt16(flags) << 8, 0, 0, 0)
}

public func MIDI2FunctionBlockDiscoveryMessage(_ functionBlockNumber: UInt8, _ infoRequest: Bool, _ nameRequest: Bool) -> MIDIMessage_128 {
    var filter: UInt8 = 0
    if infoRequest { filter |= 1 }
    if nameRequest { filter |= 2 }
    let data1 = (UInt16(functionBlockNumber) << 8) | UInt16(filter)
    return MIDI2StreamMessage(.complete, .functionBlockDiscovery, data1, 0, 0, 0)
}

public func MIDI2FunctionBlockInfoNotificationMessage(
    _ active: Bool, _ blockNumber: MIDIUInteger7,
    _ UIHint: MIDIUMPFunctionBlockUIHint, _ MIDI1: MIDIUMPFunctionBlockMIDI1Info,
    _ direction: MIDIUMPFunctionBlockDirection,
    _ firstGroup: UInt8, _ numberOfGroupsSpanned: UInt8,
    _ CIVersion: UInt8, _ maxSysex8Streams: UInt8
) -> MIDIMessage_128 {
    var first: UInt8 = blockNumber
    if active { first |= 0x80 }
    let data1 = (UInt16(first) << 8)
        | UInt16((UInt32(direction.rawValue) << 6) | (UInt32(MIDI1.rawValue) << 4) | UInt32(UIHint.rawValue))
    let word1 = (UInt32(firstGroup) << 24) | (UInt32(numberOfGroupsSpanned) << 16) | (UInt32(CIVersion) << 8) | UInt32(maxSysex8Streams)
    return MIDI2StreamMessage(.complete, .functionBlockInfoNotification, data1, word1, 0, 0)
}

public func MIDI2FunctionBlockNameNotificationMessage(
    _ format: UMPStreamMessageFormat, _ blockNumber: UInt8, _ data: UnsafePointer<CChar>!, _ length: Int
) -> MIDIMessage_128 {
    var message = MIDI2StreamMessageFromData(format, .functionBlockNameNotification, data.map { UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self) }, length)
    message.word0 = (message.word0 & 0xFFFF_0000) | (UInt32(blockNumber) << 8) | (message.word0 & 0xFF)
    return message
}

public func MIDI2StartOfClipMessage() -> MIDIMessage_128 {
    MIDI2StreamMessage(.complete, .startOfClip, 0, 0, 0, 0)
}

public func MIDI2EndOfClipMessage() -> MIDIMessage_128 {
    MIDI2StreamMessage(.complete, .endOfClip, 0, 0, 0, 0)
}

public func MIDI2FlexDataMessage(
    _ group: MIDIUInteger4, _ format: MIDIUInteger2, _ address: MIDIUInteger2,
    _ channel: MIDIUInteger4, _ statusBank: UInt8, _ status: UInt8,
    _ data1: UInt32, _ data2: UInt32, _ data3: UInt32
) -> MIDIMessage_128 {
    let word0 =
        (UInt32(0xD) << 28)
        | (UInt32(group & 0xF) << 24)
        | (UInt32(format & 0x3) << 22)
        | (UInt32(address & 0x3) << 20)
        | (UInt32(channel & 0xF) << 16)
        | (UInt32(statusBank) << 8)
        | UInt32(status)
    return MIDIMessage_128(word0: word0, word1: data1, word2: data2, word3: data3)
}

public func MIDIEventPacketSysexBytesForGroup(
    _ pkt: UnsafePointer<MIDIEventPacket>,
    _ groupIndex: UInt8,
    _ outData: UnsafeMutablePointer<Unmanaged<CFData>?>
) -> OSStatus {
    _ = pkt
    _ = groupIndex
    outData.pointee = nil
    return kMIDINotPermitted
}
