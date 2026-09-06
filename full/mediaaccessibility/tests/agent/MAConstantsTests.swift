import Foundation
import MediaAccessibility

func testMediaCharacteristicConstantIdentities() {
    let music = unsafeBitCast(
        MAMediaCharacteristicDescribesMusicAndSoundForAccessibility,
        to: NSString.self
    ) as String
    let video = unsafeBitCast(
        MAMediaCharacteristicDescribesVideoForAccessibility,
        to: NSString.self
    ) as String
    let dialog = unsafeBitCast(
        MAMediaCharacteristicTranscribesSpokenDialogForAccessibility,
        to: NSString.self
    ) as String
    precondition(music == "MAMediaCharacteristicDescribesMusicAndSoundForAccessibility")
    precondition(video == "MAMediaCharacteristicDescribesVideoForAccessibility")
    precondition(dialog == "MAMediaCharacteristicTranscribesSpokenDialogForAccessibility")
}

func testSettingsChangedNotificationIdentities() {
    let captions = unsafeBitCast(
        kMACaptionAppearanceSettingsChangedNotification,
        to: NSString.self
    ) as String
    let audible = unsafeBitCast(
        kMAAudibleMediaSettingsChangedNotification,
        to: NSString.self
    ) as String
    let flashing = unsafeBitCast(
        kMADimFlashingLightsChangedNotification,
        to: NSString.self
    ) as String
    precondition(captions == "kMACaptionAppearanceSettingsChangedNotification")
    precondition(audible == "kMAAudibleMediaSettingsChangedNotification")
    precondition(flashing == "kMADimFlashingLightsChangedNotification")
}

func testAudibleMediaPreferredCharacteristicsEmpty() {
    let copied = MAAudibleMediaCopyPreferredCharacteristics().takeRetainedValue()
    let values = unsafeBitCast(copied, to: NSArray.self)
    precondition(values.count == 0)
}

func testDimFlashingLightsEnabledFailClosed() {
    precondition(MADimFlashingLightsEnabled() == false)
}
