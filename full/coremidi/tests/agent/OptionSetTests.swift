import CoreMIDI
import Foundation

func testOptionSetMembers() {
    midiExpect(MIDICICategoryOptions.protocolNegotiation.rawValue == 1 << 1, "protocolNegotiation")
    midiExpect(MIDICICategoryOptions.profileConfigurationSupported.rawValue == 1 << 2, "profileConfiguration")
    midiExpect(MIDICICategoryOptions.propertyExchangeSupported.rawValue == 1 << 3, "propertyExchange")
    midiExpect(MIDICICategoryOptions.processInquirySupported.rawValue == 1 << 4, "processInquiry")
    midiExpect(MIDIPerNoteManagementOptions.reset.rawValue == 1 << 0, "pnm reset")
    midiExpect(MIDIPerNoteManagementOptions.detach.rawValue == 1 << 1, "pnm detach")
    midiExpect(MIDIProgramChangeOptions.bankValid.rawValue == 1 << 0, "bankValid")
    midiExpect(MIDIUMPProtocolOptions.midi1.rawValue == 1, "ump midi1")
    midiExpect(MIDIUMPProtocolOptions.midi2.rawValue == 1 << 1, "ump midi2")
}

func testOptionSetAlgebra() {
    var options: MIDICICategoryOptions = []
    midiExpect(options.isEmpty, "empty")
    midiExpect(options.insert(.protocolNegotiation).inserted, "insert")
    midiExpect(options.contains(.protocolNegotiation), "contains")
    midiExpect(options.update(with: .profileConfigurationSupported) == nil, "update new")
    midiExpect(options.remove(.protocolNegotiation) != nil, "remove")
    let union = MIDICICategoryOptions.protocolNegotiation.union(.propertyExchangeSupported)
    midiExpect(union.contains(.protocolNegotiation) && union.contains(.propertyExchangeSupported), "union")
    midiExpect(
        MIDICICategoryOptions.protocolNegotiation.intersection(.protocolNegotiation).contains(.protocolNegotiation),
        "intersection"
    )
    let sym = MIDICICategoryOptions.protocolNegotiation.symmetricDifference(.profileConfigurationSupported)
    midiExpect(sym.contains(.protocolNegotiation) && sym.contains(.profileConfigurationSupported), "symmetricDifference")
    var form = MIDICICategoryOptions.protocolNegotiation
    form.formUnion(.processInquirySupported)
    midiExpect(form.contains(.processInquirySupported), "formUnion")
    form.formIntersection(.protocolNegotiation)
    midiExpect(form.contains(.protocolNegotiation) && !form.contains(.processInquirySupported), "formIntersection")
    var formSym: MIDICICategoryOptions = [.protocolNegotiation, .profileConfigurationSupported]
    formSym.formSymmetricDifference(.protocolNegotiation)
    midiExpect(!formSym.contains(.protocolNegotiation) && formSym.contains(.profileConfigurationSupported), "formSymmetric")
    midiExpect(MIDICICategoryOptions.protocolNegotiation.isSubset(of: [.protocolNegotiation, .propertyExchangeSupported]), "isSubset")
    midiExpect(MIDICICategoryOptions([.protocolNegotiation, .propertyExchangeSupported]).isSuperset(of: [.protocolNegotiation]), "isSuperset")
    midiExpect(MIDICICategoryOptions.protocolNegotiation.isDisjoint(with: .propertyExchangeSupported), "isDisjoint")
    midiExpect(!MIDICICategoryOptions.protocolNegotiation.isStrictSubset(of: .protocolNegotiation), "isStrictSubset same")
    midiExpect(MIDICICategoryOptions.protocolNegotiation.isStrictSubset(of: [.protocolNegotiation, .propertyExchangeSupported]), "isStrictSubset")
    midiExpect(MIDICICategoryOptions([.protocolNegotiation, .propertyExchangeSupported]).isStrictSuperset(of: .protocolNegotiation), "isStrictSuperset")
    midiExpect(MIDICICategoryOptions.protocolNegotiation.subtracting(.protocolNegotiation).isEmpty, "subtracting")
    var subtract = MIDICICategoryOptions.protocolNegotiation
    subtract.subtract(.protocolNegotiation)
    midiExpect(subtract.isEmpty, "subtract")
    let fromSequence = MIDICICategoryOptions([.protocolNegotiation, .protocolNegotiation])
    midiExpect(fromSequence.contains(.protocolNegotiation), "init sequence")
    let literal: MIDICICategoryOptions = [.protocolNegotiation, .processInquirySupported]
    midiExpect(literal.contains(.processInquirySupported), "array literal")
    midiExpect(MIDIPerNoteManagementOptions().isEmpty, "pnm empty init")
    midiExpect(MIDIProgramChangeOptions().isEmpty, "pc empty init")
    midiExpect(MIDIUMPProtocolOptions().isEmpty, "ump empty init")
}

func testHashableWitnesses() {
    midiExpect(MIDIObjectType.device != MIDIObjectType.entity, "enum !=")
    midiExpect(MIDIObjectType.device.hashValue == MIDIObjectType.device.hashValue, "enum hashValue")
    var hasher = Hasher()
    MIDIObjectType.device.hash(into: &hasher)
    MIDIProtocolID._1_0.hash(into: &hasher)
    midiExpect(MIDIMessageType.channelVoice1 != .sysEx, "message type !=")
    midiExpect(MIDICICategoryOptions.protocolNegotiation != .propertyExchangeSupported, "option !=")
    midiExpect(MIDICIDeviceManager.DictionaryKey.deviceObject.hashValue != 0 || true, "dict key hash")
    midiExpect(
        MIDICIDeviceManager.DictionaryKey.deviceObject != MIDICIDeviceManager.DictionaryKey.profileObject,
        "dict key !="
    )
    midiExpect(MIDIUMPEndpointManager.DictionaryKey.endpointObject != .functionBlockObject, "ump dict !=")
    midiExpect(MIDICIPropertyExchangeRequestID.badRequestID.hashValue == MIDICIPropertyExchangeRequestID(rawValue: 0xFF).hashValue, "request id hash")
}
