import Foundation
import MediaAccessibility

func testCaptionAppearanceSelectedLanguagesRoundTrip() {
    MAResetProcessLocalStateForTesting()
    let empty = unsafeBitCast("" as NSString, to: CFString.self)
    precondition(MACaptionAppearanceAddSelectedLanguage(.user, empty) == false)

    let french = unsafeBitCast("fr-FR" as NSString, to: CFString.self)
    precondition(MACaptionAppearanceAddSelectedLanguage(.user, french))
    precondition(MACaptionAppearanceAddSelectedLanguage(.user, french))

    let english = unsafeBitCast("en" as NSString, to: CFString.self)
    precondition(MACaptionAppearanceAddSelectedLanguage(.user, english))

    let copied = MACaptionAppearanceCopySelectedLanguages(.user).takeRetainedValue()
    let values = unsafeBitCast(copied, to: NSArray.self) as! [String]
    precondition(values == ["fr-FR", "en"])

    let defaultCopied = MACaptionAppearanceCopySelectedLanguages(.default).takeRetainedValue()
    let defaultValues = unsafeBitCast(defaultCopied, to: NSArray.self) as! [String]
    precondition(defaultValues.isEmpty)
}

func testCaptionAppearanceDisplayTypeRoundTrip() {
    MAResetProcessLocalStateForTesting()
    precondition(MACaptionAppearanceGetDisplayType(.user) == .forcedOnly)
    MACaptionAppearanceSetDisplayType(.user, .alwaysOn)
    precondition(MACaptionAppearanceGetDisplayType(.user) == .alwaysOn)
    precondition(MACaptionAppearanceGetDisplayType(.default) == .forcedOnly)
    MACaptionAppearanceSetDisplayType(.default, .automatic)
    precondition(MACaptionAppearanceGetDisplayType(.default) == .automatic)
}

func testCaptionAppearanceIsCustomizedAndNotification() {
    MAResetProcessLocalStateForTesting()
    precondition(MACaptionAppearanceIsCustomized(.user) == false)

    final class Counter: @unchecked Sendable {
        var value = 0
    }
    let posted = Counter()
    let name = Notification.Name("kMACaptionAppearanceSettingsChangedNotification")
    let token = NotificationCenter.default.addObserver(
        forName: name,
        object: nil,
        queue: nil
    ) { _ in
        posted.value += 1
    }
    MACaptionAppearanceSetDisplayType(.user, .alwaysOn)
    NotificationCenter.default.removeObserver(token)
    precondition(posted.value == 1)
    precondition(MACaptionAppearanceIsCustomized(.user))
    precondition(MACaptionAppearanceIsCustomized(.default) == false)
}

func testCaptionAppearancePreferredMediaCharacteristics() {
    MAResetProcessLocalStateForTesting()
    let forced = MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(.user)
        .takeRetainedValue()
    let forcedValues = unsafeBitCast(forced, to: NSArray.self)
    precondition(forcedValues.count == 0)

    MACaptionAppearanceSetDisplayType(.user, .alwaysOn)
    let always = MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(.user)
        .takeRetainedValue()
    let alwaysValues = unsafeBitCast(always, to: NSArray.self) as! [String]
    precondition(alwaysValues == ["MAMediaCharacteristicTranscribesSpokenDialogForAccessibility"])
}

func testCaptionAppearanceDidDisplayCaptions() {
    MAResetProcessLocalStateForTesting()
    let captions = ["Hello", "World"] as NSArray
    MACaptionAppearanceDidDisplayCaptions(unsafeBitCast(captions, to: CFArray.self))
    precondition(MALastDisplayedCaptionsForTesting() == ["Hello", "World"])
}
