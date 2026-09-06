import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testCameraSettingsControlWiring() {
    func tilt(_ type: String) -> HMCharacteristic {
        HMCharacteristic.host_make(
            type: type,
            properties: [HMCharacteristicPropertyReadable],
            metadata: nil,
            value: NSNumber(value: 0)
        )
    }
    let settings = HMCameraSettingsControl.host_make(
        nightVision: tilt(HMCharacteristicTypeNightVision),
        currentHorizontalTilt: tilt(HMCharacteristicTypeCurrentHorizontalTilt),
        targetHorizontalTilt: tilt(HMCharacteristicTypeTargetHorizontalTilt),
        currentVerticalTilt: tilt(HMCharacteristicTypeCurrentVerticalTilt),
        targetVerticalTilt: tilt(HMCharacteristicTypeTargetVerticalTilt),
        opticalZoom: tilt(HMCharacteristicTypeOpticalZoom),
        digitalZoom: tilt(HMCharacteristicTypeDigitalZoom),
        imageRotation: tilt(HMCharacteristicTypeImageRotation),
        imageMirroring: tilt(HMCharacteristicTypeImageMirroring)
    )
    hmRequire(settings.nightVision?.characteristicType == HMCharacteristicTypeNightVision, "nv")
    hmRequire(
        settings.currentHorizontalTilt?.characteristicType == HMCharacteristicTypeCurrentHorizontalTilt,
        "h current"
    )
    hmRequire(
        settings.targetHorizontalTilt?.characteristicType == HMCharacteristicTypeTargetHorizontalTilt,
        "h target"
    )
    hmRequire(
        settings.currentVerticalTilt?.characteristicType == HMCharacteristicTypeCurrentVerticalTilt,
        "v current"
    )
    hmRequire(
        settings.targetVerticalTilt?.characteristicType == HMCharacteristicTypeTargetVerticalTilt,
        "v target"
    )
    hmRequire(settings.opticalZoom?.characteristicType == HMCharacteristicTypeOpticalZoom, "opt")
    hmRequire(settings.digitalZoom?.characteristicType == HMCharacteristicTypeDigitalZoom, "dig")
    hmRequire(settings.imageRotation?.characteristicType == HMCharacteristicTypeImageRotation, "rot")
    hmRequire(settings.imageMirroring?.characteristicType == HMCharacteristicTypeImageMirroring, "mirror")

    let profile = HMCameraProfile.host_make(
        settingsControl: settings,
        streamControl: HMCameraStreamControl.host_make(),
        snapshotControl: HMCameraSnapshotControl.host_make()
    )
    hmRequire(profile.settingsControl === settings, "settings")
    hmRequire(profile.streamControl != nil, "stream")
    hmRequire(profile.snapshotControl != nil, "snap")

    let accessory = HMAccessory.host_make(name: "Cam")
    accessory.host_setProfiles([], cameraProfiles: [profile])
    hmRequire(accessory.cameraProfiles?.count == 1, "camera profiles")
    hmRequire(accessory.cameraProfiles?.first?.settingsControl === settings, "wired")
}

func testAddAccessoryRequestPayloadParsing() {
    let home = HMHome.host_make(name: "Entry")
    let category = HMAccessoryCategory.host_make(
        categoryType: HMAccessoryCategoryTypeDoorLock,
        localizedDescription: "Lock"
    )
    let needsURL = HMAddAccessoryRequest()
    hmRequire(needsURL.requiresSetupPayloadURL, "default url")
    hmRequire(needsURL.requiresOwnershipToken, "default token")
    hmRequire(needsURL.accessoryName == "", "empty name")
    hmRequire(needsURL.home.name == "", "empty home")

    let request = HMAddAccessoryRequest.host_make(
        home: home,
        accessoryName: "Front Lock",
        accessoryCategory: category,
        requiresSetupPayloadURL: true,
        requiresOwnershipToken: true
    )
    hmRequire(request.home === home, "home")
    hmRequire(request.accessoryName == "Front Lock", "name")
    hmRequire(request.accessoryCategory.categoryType == HMAccessoryCategoryTypeDoorLock, "cat")
    hmRequire(request.requiresSetupPayloadURL, "needs url")
    hmRequire(request.requiresOwnershipToken, "needs token")

    let token = HMAccessoryOwnershipToken(data: Data([0x11, 0x22]))!
    hmRequire(request.makePayload(ownershipToken: token) == nil, "url required")
    hmRequire(request.payload(with: token) == nil, "alias nil")

    let http = URL(string: "https://example.invalid/setup")!
    hmRequire(request.makePayload(url: http, ownershipToken: token) == nil, "bad scheme")
    let url = URL(string: "homekit://ABCDEF")!
    let payload = request.makePayload(url: url, ownershipToken: token)
    hmRequire(payload?.url == url, "parsed")
    let aliased = request.payload(with: url, ownershipToken: token)
    hmRequire(aliased?.url == url, "alias parsed")

    let hap = URL(string: "hap://code")!
    let hapPayload = request.makePayload(url: hap, ownershipToken: token)
    hmRequire(hapPayload?.url == hap, "hap scheme")
}
