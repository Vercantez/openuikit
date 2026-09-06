import CoreMIDI
import CoreFoundation
import Foundation

func testErrorAndLimitConstants() {
    midiExpect(kMIDIInvalidClient == -10830, "kMIDIInvalidClient")
    midiExpect(kMIDIInvalidPort == -10831, "kMIDIInvalidPort")
    midiExpect(kMIDIWrongEndpointType == -10832, "kMIDIWrongEndpointType")
    midiExpect(kMIDINoConnection == -10833, "kMIDINoConnection")
    midiExpect(kMIDIUnknownEndpoint == -10834, "kMIDIUnknownEndpoint")
    midiExpect(kMIDIUnknownProperty == -10835, "kMIDIUnknownProperty")
    midiExpect(kMIDIWrongPropertyType == -10836, "kMIDIWrongPropertyType")
    midiExpect(kMIDINoCurrentSetup == -10837, "kMIDINoCurrentSetup")
    midiExpect(kMIDIMessageSendErr == -10838, "kMIDIMessageSendErr")
    midiExpect(kMIDIServerStartErr == -10839, "kMIDIServerStartErr")
    midiExpect(kMIDISetupFormatErr == -10840, "kMIDISetupFormatErr")
    midiExpect(kMIDIWrongThread == -10841, "kMIDIWrongThread")
    midiExpect(kMIDIObjectNotFound == -10842, "kMIDIObjectNotFound")
    midiExpect(kMIDIIDNotUnique == -10843, "kMIDIIDNotUnique")
    midiExpect(kMIDINotPermitted == -10844, "kMIDINotPermitted")
    midiExpect(kMIDIUnknownError == -10845, "kMIDIUnknownError")
    midiExpect(kMIDIUInteger2Max == 0x3, "u2")
    midiExpect(kMIDIUInteger4Max == 0xF, "u4")
    midiExpect(kMIDIUInteger7Max == 0x7F, "u7")
    midiExpect(kMIDIUInteger14Max == 0x3FFF, "u14")
    midiExpect(kMIDIUInteger28Max == 0x0FFF_FFFF, "u28")
    midiExpect(kMIDI1UPMaxSysexSize == 6, "sysex max")
    midiExpect(kMIDIDeviceIDFunctionBlock == 0x7F, "device id fb")
    midiExpect(kMIDIDeviceIDUMPGroup == 0x7E, "device id group")
    midiExpect(MIDIChannelsWholePort == 0xFF, "whole port")
    midiExpect(kMIDIInvalidUniqueID == 0, "invalid unique")
    midiExpect(kMIDIThruConnection_MaxEndpoints == 8, "thru max")
    midiExpect(kMIDINoteAttributeNone == 0, "note attr none")
    midiExpect(kMIDINoteAttributeManufacturerSpecific == 1, "note attr mfr")
    midiExpect(kMIDINoteAttributeProfileSpecific == 2, "note attr profile")
    midiExpect(kMIDINoteAttributePitch == 3, "note attr pitch")
    midiExpect(kMIDIObjectType_ExternalMask == MIDIObjectType(rawValue: 0x10), "external mask")
}

func testPropertyKeys() {
    let name = CFStringCreateWithCString(nil, "name", CFStringBuiltInEncodings.UTF8.rawValue)!
    midiExpect(CFStringCompare(kMIDIPropertyName, name, []) == .compareEqualTo, "name")
    _ = kMIDIPropertyDeviceID
    _ = kMIDIPropertyImage
    _ = kMIDIPropertyDriverOwner
    _ = kMIDIPropertyDriverVersion
    _ = kMIDIPropertyDriverDeviceEditorApp
    _ = kMIDIPropertyConnectionUniqueID
    _ = kMIDIPropertyOffline
    _ = kMIDIPropertyPrivate
    _ = kMIDIPropertyAdvanceScheduleTimeMuSec
    _ = kMIDIPropertyCanRoute
    _ = kMIDIPropertyIsEmbeddedEntity
    _ = kMIDIPropertyIsBroadcast
    _ = kMIDIPropertySingleRealtimeEntity
    _ = kMIDIPropertyMaxSysExSpeed
    _ = kMIDIPropertySupportsGeneralMIDI
    _ = kMIDIPropertySupportsMMC
    _ = kMIDIPropertySupportsShowControl
    _ = kMIDIPropertyReceivesClock
    _ = kMIDIPropertyReceivesMTC
    _ = kMIDIPropertyReceivesNotes
    _ = kMIDIPropertyReceivesProgramChanges
    _ = kMIDIPropertyReceivesBankSelectMSB
    _ = kMIDIPropertyReceivesBankSelectLSB
    _ = kMIDIPropertyTransmitsClock
    _ = kMIDIPropertyTransmitsMTC
    _ = kMIDIPropertyTransmitsNotes
    _ = kMIDIPropertyTransmitsProgramChanges
    _ = kMIDIPropertyTransmitsBankSelectMSB
    _ = kMIDIPropertyTransmitsBankSelectLSB
    _ = kMIDIPropertyPanDisruptsStereo
    _ = kMIDIPropertyIsSampler
    _ = kMIDIPropertyIsDrumMachine
    _ = kMIDIPropertyIsMixer
    _ = kMIDIPropertyIsEffectUnit
    _ = kMIDIPropertyMaxReceiveChannels
    _ = kMIDIPropertyMaxTransmitChannels
    _ = kMIDIPropertyReceiveChannels
    _ = kMIDIPropertyTransmitChannels
    _ = kMIDIPropertyNameConfiguration
    _ = kMIDIPropertyNameConfigurationDictionary
    _ = kMIDIPropertyAssociatedEndpoint
    _ = kMIDIPropertyProtocolID
    _ = kMIDIPropertyUMPActiveGroupBitmap
    _ = kMIDIPropertyUMPCanTransmitGroupless
    midiExpect(MIDINetworkBonjourServiceType == "_apple-midi._udp", "bonjour type")
    midiExpect(MIDINetworkNotificationContactsDidChange.contains("Contacts"), "contacts note")
    midiExpect(MIDINetworkNotificationSessionDidChange.contains("Session"), "session note")
}

func testEnumRawValues() {
    midiExpect(MIDIProtocolID._1_0.rawValue == 1 && MIDIProtocolID._2_0.rawValue == 2, "protocol")
    midiExpect(MIDIObjectType.other.rawValue == -1, "other")
    midiExpect(MIDIObjectType.device.rawValue == 0, "device")
    midiExpect(MIDIObjectType.entity.rawValue == 1, "entity")
    midiExpect(MIDIObjectType.source.rawValue == 2, "source")
    midiExpect(MIDIObjectType.destination.rawValue == 3, "dest")
    midiExpect(MIDIObjectType.externalDevice.rawValue == 0x10, "ext device")
    midiExpect(MIDIObjectType.externalEntity.rawValue == 0x11, "ext entity")
    midiExpect(MIDIObjectType.externalSource.rawValue == 0x12, "ext source")
    midiExpect(MIDIObjectType.externalDestination.rawValue == 0x13, "ext dest")
    midiExpect(MIDINotificationMessageID.msgSetupChanged.rawValue == 1, "setup")
    midiExpect(MIDINotificationMessageID.msgObjectAdded.rawValue == 2, "added")
    midiExpect(MIDINotificationMessageID.msgObjectRemoved.rawValue == 3, "removed")
    midiExpect(MIDINotificationMessageID.msgPropertyChanged.rawValue == 4, "prop")
    midiExpect(MIDINotificationMessageID.msgThruConnectionsChanged.rawValue == 5, "thru")
    midiExpect(MIDINotificationMessageID.msgSerialPortOwnerChanged.rawValue == 6, "serial")
    midiExpect(MIDINotificationMessageID.msgIOError.rawValue == 7, "io")
    midiExpect(MIDINotificationMessageID.msgInternalStart.rawValue == 8, "internal")
    midiExpect(MIDINetworkConnectionPolicy.noOne.rawValue == 0, "noOne")
    midiExpect(MIDINetworkConnectionPolicy.hostsInContactList.rawValue == 1, "contacts")
    midiExpect(MIDINetworkConnectionPolicy.anyone.rawValue == 2, "anyone")
    midiExpect(MIDITransformType.none.rawValue == 0, "xform none")
    midiExpect(MIDITransformType.filterOut.rawValue == 1, "filterOut")
    midiExpect(MIDITransformType.mapControl.rawValue == 2, "mapControl")
    midiExpect(MIDITransformType.add.rawValue == 8, "add")
    midiExpect(MIDITransformType.scale.rawValue == 9, "scale")
    midiExpect(MIDITransformType.minValue.rawValue == 10, "min")
    midiExpect(MIDITransformType.maxValue.rawValue == 11, "max")
    midiExpect(MIDITransformType.mapValue.rawValue == 12, "mapValue")
    midiExpect(MIDITransformControlType.controlType_7Bit.rawValue == 0, "7bit")
    midiExpect(MIDITransformControlType.controlType_14Bit.rawValue == 1, "14bit")
    midiExpect(MIDITransformControlType.controlType_7BitRPN.rawValue == 2, "7rpn")
    midiExpect(MIDITransformControlType.controlType_14BitRPN.rawValue == 3, "14rpn")
    midiExpect(MIDITransformControlType.controlType_7BitNRPN.rawValue == 4, "7nrpn")
    midiExpect(MIDITransformControlType.controlType_14BitNRPN.rawValue == 5, "14nrpn")
    midiExpect(MIDIMessageType.utility.rawValue == 0, "utility")
    midiExpect(MIDIMessageType.system.rawValue == 1, "system")
    midiExpect(MIDIMessageType.channelVoice1.rawValue == 2, "cv1")
    midiExpect(MIDIMessageType.sysEx.rawValue == 3, "sysex")
    midiExpect(MIDIMessageType.channelVoice2.rawValue == 4, "cv2")
    midiExpect(MIDIMessageType.data128.rawValue == 5, "data128")
    midiExpect(MIDIMessageType.flexData.rawValue == 0xD, "flex")
    midiExpect(MIDIMessageType.unknownF.rawValue == 0xF, "unknownF")
    midiExpect(MIDIMessageType.invalid.rawValue == 0xFF, "invalid")
    midiExpect(MIDIMessageType.stream == .unknownF, "stream alias")
    midiExpect(MIDICVStatus.noteOff.rawValue == 8, "noteOff")
    midiExpect(MIDICVStatus.noteOn.rawValue == 9, "noteOn")
    midiExpect(MIDICVStatus.polyPressure.rawValue == 10, "poly")
    midiExpect(MIDICVStatus.controlChange.rawValue == 11, "cc")
    midiExpect(MIDICVStatus.programChange.rawValue == 12, "pc")
    midiExpect(MIDICVStatus.channelPressure.rawValue == 13, "cp")
    midiExpect(MIDICVStatus.pitchBend.rawValue == 14, "pb")
    midiExpect(MIDICVStatus.perNoteMgmt.rawValue == 15, "pnm")
    midiExpect(MIDICVStatus.registeredPNC.rawValue == 0, "rpnc")
    midiExpect(MIDICVStatus.assignablePNC.rawValue == 1, "apnc")
    midiExpect(MIDICVStatus.registeredControl.rawValue == 2, "rc")
    midiExpect(MIDICVStatus.assignableControl.rawValue == 3, "ac")
    midiExpect(MIDICVStatus.relRegisteredControl.rawValue == 4, "relrc")
    midiExpect(MIDICVStatus.relAssignableControl.rawValue == 5, "relac")
    midiExpect(MIDICVStatus.perNotePitchBend.rawValue == 6, "pnpb")
    midiExpect(MIDISysExStatus.complete.rawValue == 0, "sx complete")
    midiExpect(MIDISysExStatus.start.rawValue == 1, "sx start")
    midiExpect(MIDISysExStatus.continue.rawValue == 2, "sx continue")
    midiExpect(MIDISysExStatus.end.rawValue == 3, "sx end")
    midiExpect(MIDISysExStatus.mixedDataSetHeader.rawValue == 8, "mds header")
    midiExpect(MIDISysExStatus.mixedDataSetPayload.rawValue == 9, "mds payload")
    midiExpect(MIDISystemStatus.statusStartOfExclusive.rawValue == 240, "sox")
    midiExpect(MIDISystemStatus.statusMTC.rawValue == 241, "mtc")
    midiExpect(MIDISystemStatus.statusSongPosPointer.rawValue == 242, "spp")
    midiExpect(MIDISystemStatus.statusSongSelect.rawValue == 243, "ss")
    midiExpect(MIDISystemStatus.statusTuneRequest.rawValue == 246, "tune")
    midiExpect(MIDISystemStatus.statusEndOfExclusive.rawValue == 247, "eox")
    midiExpect(MIDISystemStatus.statusTimingClock.rawValue == 248, "clock")
    midiExpect(MIDISystemStatus.statusStart.rawValue == 250, "start")
    midiExpect(MIDISystemStatus.statusContinue.rawValue == 251, "continue")
    midiExpect(MIDISystemStatus.statusStop.rawValue == 252, "stop")
    midiExpect(MIDISystemStatus.statusActiveSending.rawValue == 254, "active sending")
    midiExpect(MIDISystemStatus.statusSystemReset.rawValue == 255, "reset")
    midiExpect(MIDISystemStatus.statusActiveSensing == .statusActiveSending, "active sensing alias")
    midiExpect(MIDINoteAttribute.none.rawValue == 0, "note none")
    midiExpect(MIDINoteAttribute.manufacturerSpecific.rawValue == 1, "note mfr")
    midiExpect(MIDINoteAttribute.profileSpecific.rawValue == 2, "note profile")
    midiExpect(MIDINoteAttribute.pitch.rawValue == 3, "note pitch")
    midiExpect(MIDIUtilityStatus.NOOP.rawValue == 0, "noop")
    midiExpect(MIDIUtilityStatus.jitterReductionClock.rawValue == 1, "jr clock")
    midiExpect(MIDIUtilityStatus.jitterReductionTimestamp.rawValue == 2, "jr ts")
    midiExpect(MIDIUtilityStatus.deltaClockstampTicksPerQuarterNote.rawValue == 3, "dc ticked")
    midiExpect(MIDIUtilityStatus.ticksSinceLastEvent.rawValue == 4, "ticks")
    midiExpect(UMPStreamMessageStatus.endpointDiscovery.rawValue == 0x00, "ep disc")
    midiExpect(UMPStreamMessageStatus.endpointInfoNotification.rawValue == 0x01, "ep info")
    midiExpect(UMPStreamMessageStatus.deviceIdentityNotification.rawValue == 0x02, "dev id")
    midiExpect(UMPStreamMessageStatus.endpointNameNotification.rawValue == 0x03, "ep name")
    midiExpect(UMPStreamMessageStatus.productInstanceIDNotification.rawValue == 0x04, "prod id")
    midiExpect(UMPStreamMessageStatus.streamConfigurationRequest.rawValue == 0x05, "stream req")
    midiExpect(UMPStreamMessageStatus.streamConfigurationNotification.rawValue == 0x06, "stream note")
    midiExpect(UMPStreamMessageStatus.functionBlockDiscovery.rawValue == 0x10, "fb disc")
    midiExpect(UMPStreamMessageStatus.functionBlockInfoNotification.rawValue == 0x11, "fb info")
    midiExpect(UMPStreamMessageStatus.functionBlockNameNotification.rawValue == 0x12, "fb name")
    midiExpect(UMPStreamMessageStatus.startOfClip.rawValue == 0x20, "start clip")
    midiExpect(UMPStreamMessageStatus.endOfClip.rawValue == 0x21, "end clip")
    midiExpect(UMPStreamMessageFormat.complete.rawValue == 0, "fmt complete")
    midiExpect(UMPStreamMessageFormat.start.rawValue == 1, "fmt start")
    midiExpect(UMPStreamMessageFormat.continuing.rawValue == 2, "fmt cont")
    midiExpect(UMPStreamMessageFormat.end.rawValue == 3, "fmt end")
    midiExpect(MIDIUMPFunctionBlockMIDI1Info.notMIDI1.rawValue == 0, "not midi1")
    midiExpect(MIDIUMPFunctionBlockMIDI1Info.unrestrictedBandwidth.rawValue == 1, "unrestricted")
    midiExpect(MIDIUMPFunctionBlockMIDI1Info.restrictedBandwidth.rawValue == 2, "restricted")
    midiExpect(MIDIUMPFunctionBlockUIHint.unknown.rawValue == 0, "ui unknown")
    midiExpect(MIDIUMPFunctionBlockUIHint.receiver.rawValue == 1, "ui rx")
    midiExpect(MIDIUMPFunctionBlockUIHint.sender.rawValue == 2, "ui tx")
    midiExpect(MIDIUMPFunctionBlockUIHint.senderReceiver.rawValue == 3, "ui both")
    midiExpect(MIDIUMPFunctionBlockDirection.unknown.rawValue == 0, "dir unknown")
    midiExpect(MIDIUMPFunctionBlockDirection.input.rawValue == 1, "dir in")
    midiExpect(MIDIUMPFunctionBlockDirection.output.rawValue == 2, "dir out")
    midiExpect(MIDIUMPFunctionBlockDirection.bidirectional.rawValue == 3, "dir bi")
    midiExpect(MIDICIDeviceType.unknown.rawValue == 0, "ci unknown")
    midiExpect(MIDICIDeviceType.legacyMIDI1.rawValue == 1, "ci legacy")
    midiExpect(MIDICIDeviceType.virtual.rawValue == 2, "ci virtual")
    midiExpect(MIDICIDeviceType.usbMIDI.rawValue == 3, "ci usb")
    midiExpect(MIDICIProfileMessageType.profileInquiry.rawValue == 0x20, "profile inquiry")
    midiExpect(MIDICIProfileMessageType.replyToProfileInquiry.rawValue == 0x21, "reply inquiry")
    midiExpect(MIDICIProfileMessageType.setProfileOn.rawValue == 0x22, "set on")
    midiExpect(MIDICIProfileMessageType.setProfileOff.rawValue == 0x23, "set off")
    midiExpect(MIDICIProfileMessageType.profileEnabledReport.rawValue == 0x24, "enabled")
    midiExpect(MIDICIProfileMessageType.profileDisabledReport.rawValue == 0x25, "disabled")
    midiExpect(MIDICIProfileMessageType.profileAdded.rawValue == 0x26, "added")
    midiExpect(MIDICIProfileMessageType.profileRemoved.rawValue == 0x27, "removed")
    midiExpect(MIDICIProfileMessageType.detailsInquiry.rawValue == 0x28, "details")
    midiExpect(MIDICIProfileMessageType.replyToDetailsInquiry.rawValue == 0x29, "reply details")
    midiExpect(MIDICIProfileMessageType.profileSpecificData.rawValue == 0x2F, "psd")
    midiExpect(MIDICIPropertyExchangeMessageType.inquiryPropertyExchangeCapabilities.rawValue == 0x30, "pe cap")
    midiExpect(MIDICIPropertyExchangeMessageType.replyToPropertyExchangeCapabilities.rawValue == 0x31, "pe cap reply")
    midiExpect(MIDICIPropertyExchangeMessageType.inquiryHasPropertyData_Reserved.rawValue == 0x32, "pe has")
    midiExpect(MIDICIPropertyExchangeMessageType.inquiryReplyToHasPropertyData_Reserved.rawValue == 0x33, "pe has reply")
    midiExpect(MIDICIPropertyExchangeMessageType.inquiryGetPropertyData.rawValue == 0x34, "pe get")
    midiExpect(MIDICIPropertyExchangeMessageType.replyToGetProperty.rawValue == 0x35, "pe get reply")
    midiExpect(MIDICIPropertyExchangeMessageType.inquirySetPropertyData.rawValue == 0x36, "pe set")
    midiExpect(MIDICIPropertyExchangeMessageType.replyToSetPropertyData.rawValue == 0x37, "pe set reply")
    midiExpect(MIDICIPropertyExchangeMessageType.subscription.rawValue == 0x38, "pe sub")
    midiExpect(MIDICIPropertyExchangeMessageType.replyToSubscription.rawValue == 0x39, "pe sub reply")
    midiExpect(MIDICIPropertyExchangeMessageType.notify.rawValue == 0x3F, "pe notify")
    midiExpect(MIDICIProcessInquiryMessageType.inquiryProcessInquiryCapabilities.rawValue == 0x40, "pi cap")
    midiExpect(MIDICIProcessInquiryMessageType.replyToProcessInquiryCapabilities.rawValue == 0x41, "pi cap reply")
    midiExpect(MIDICIProcessInquiryMessageType.inquiryMIDIMessageReport.rawValue == 0x42, "pi report")
    midiExpect(MIDICIProcessInquiryMessageType.replyToMIDIMessageReport.rawValue == 0x43, "pi report reply")
    midiExpect(MIDICIProcessInquiryMessageType.endOfMIDIMessageReport.rawValue == 0x44, "pi end")
    midiExpect(MIDICIManagementMessageType.discovery.rawValue == 0x70, "mgmt disc")
    midiExpect(MIDICIManagementMessageType.replyToDiscovery.rawValue == 0x71, "mgmt disc reply")
    midiExpect(MIDICIManagementMessageType.inquiryEndpointInformation.rawValue == 0x72, "mgmt ep")
    midiExpect(MIDICIManagementMessageType.replyToEndpointInformation.rawValue == 0x73, "mgmt ep reply")
    midiExpect(MIDICIManagementMessageType.midiCIACK.rawValue == 0x7D, "ack")
    midiExpect(MIDICIManagementMessageType.invalidateMUID.rawValue == 0x7E, "invalidate")
    midiExpect(MIDICIManagementMessageType.midiNAK.rawValue == 0x7F, "nak")
    midiExpect(MIDICIProfileType.singleChannel.rawValue == 1, "profile single")
    midiExpect(MIDICIProfileType.group.rawValue == 2, "profile group")
    midiExpect(MIDICIProfileType.functionBlock.rawValue == 3, "profile fb")
    midiExpect(MIDICIProfileType.multichannel.rawValue == 4, "profile multi")
    midiExpect(MIDIUMPCIObjectBackingType.unknown.rawValue == 0, "backing unknown")
    midiExpect(MIDIUMPCIObjectBackingType.virtual.rawValue == 1, "backing virtual")
    midiExpect(MIDIUMPCIObjectBackingType.driverDevice.rawValue == 2, "backing driver")
    midiExpect(MIDIUMPCIObjectBackingType.usbMIDI.rawValue == 3, "backing usb")
    midiExpect(MIDICIPropertyExchangeRequestID.badRequestID.rawValue == 0xFF, "bad request")
    midiExpect(MIDIProtocolID(rawValue: 1) == ._1_0, "protocol init")
    midiExpect(MIDIObjectType(rawValue: 0) == .device, "object type init")
}
