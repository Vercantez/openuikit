import Foundation
import HomeKit

private func requireWave9(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit wave 9 test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testBaseActionsEventsAndProfiles() {
    let action = HMAction()
    requireWave9(!action.uniqueIdentifier.uuidString.isEmpty, "action identifier")
    requireWave9(action !== HMAction.new(), "action new instance")

    let event = HMEvent()
    requireWave9(!event.uniqueIdentifier.uuidString.isEmpty, "event identifier")
    requireWave9(event !== HMEvent.new(), "event new instance")

    let profile = HMAccessoryProfile()
    requireWave9(profile.accessory == nil, "detached profile")
    requireWave9(profile.services.isEmpty, "empty profile services")
    requireWave9(!profile.uniqueIdentifier.uuidString.isEmpty, "profile identifier")

    let network = HMNetworkConfigurationProfile()
    requireWave9(network.delegate == nil, "network delegate")
    requireWave9(network.isNetworkAccessRestricted, "network fail closed")
}

func testCharacteristicEventStateAndFailure() {
    let characteristic = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [HMCharacteristicPropertyReadable],
        metadata: nil,
        value: NSNumber(value: false)
    )
    let event = HMCharacteristicEvent<NSNumber>(
        characteristic: characteristic,
        triggerValue: NSNumber(value: true)
    )
    requireWave9(event.characteristic === characteristic, "event characteristic")
    requireWave9(event.triggerValue?.boolValue == true, "event value")
    var error: (any Error)?
    event.updateTriggerValue(NSNumber(value: false)) { error = $0 }
    requireWave9((error as NSError?)?.code == HMError.Code.operationNotSupported.rawValue, "update fails closed")

    let mutable = HMMutableCharacteristicEvent<NSNumber>(characteristic: characteristic, triggerValue: nil)
    let replacement = HMCharacteristic.host_make(
        type: HMCharacteristicTypeBrightness,
        properties: [],
        metadata: nil,
        value: nil
    )
    mutable.characteristic = replacement
    mutable.triggerValue = NSNumber(value: 42)
    requireWave9(mutable.characteristic === replacement, "mutable characteristic")
    requireWave9(mutable.triggerValue?.intValue == 42, "mutable trigger")
}

func testCameraAndSetupValueState() {
    let source = HMCameraSource()
    let stream = HMCameraStream()
    requireWave9(stream.audioStreamSetting == .muted, "stream defaults muted")
    let snapshot = HMCameraSnapshot()
    requireWave9(snapshot.captureDate == Date(timeIntervalSince1970: 0), "snapshot epoch")
    requireWave9(source !== stream && source !== snapshot, "camera source identities")

    let audio = HMCameraAudioControl()
    requireWave9(audio.mute == nil && audio.volume == nil, "audio controls absent")
    let streamControl = HMCameraStreamControl()
    let snapshotControl = HMCameraSnapshotControl()
    requireWave9(streamControl.delegate == nil && snapshotControl.delegate == nil, "camera delegates absent")

    let payload = HMAccessorySetupPayload(url: URL(string: "homekit://wave9")!)!
    let homeID = UUID()
    let roomID = UUID()
    let request = HMAccessorySetupRequest()
    request.payload = payload
    request.homeUniqueIdentifier = homeID
    request.suggestedRoomUniqueIdentifier = roomID
    requireWave9(request.payload === payload, "request payload")
    requireWave9(request.homeUniqueIdentifier == homeID, "request home")
    requireWave9(request.suggestedRoomUniqueIdentifier == roomID, "request room")
}
