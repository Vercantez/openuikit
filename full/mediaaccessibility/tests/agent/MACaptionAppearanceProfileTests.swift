import Foundation
import MediaAccessibility

func testCaptionAppearanceDefaultProfile() {
    MAResetProcessLocalStateForTesting()
    let ids = unsafeBitCast(MACaptionAppearanceCopyProfileIDs(), to: NSArray.self) as! [String]
    precondition(ids == ["default"])
    let active = unsafeBitCast(MACaptionAppearanceCopyActiveProfileID(), to: NSString.self) as String
    precondition(active == "default")
    let name = unsafeBitCast(
        MACaptionAppearanceCopyProfileName(unsafeBitCast("default" as NSString, to: CFString.self)),
        to: NSString.self
    ) as String
    precondition(name == "Default")
}

func testCaptionAppearanceSetActiveProfileID() {
    MAResetProcessLocalStateForTesting()
    let identifier = unsafeBitCast("high-contrast" as NSString, to: CFString.self)
    MACaptionAppearanceSetActiveProfileID(identifier)
    let active = unsafeBitCast(MACaptionAppearanceCopyActiveProfileID(), to: NSString.self) as String
    precondition(active == "high-contrast")
    let ids = unsafeBitCast(MACaptionAppearanceCopyProfileIDs(), to: NSArray.self) as! [String]
    precondition(ids.contains("high-contrast"))
    let name = unsafeBitCast(MACaptionAppearanceCopyProfileName(identifier), to: NSString.self) as String
    precondition(name == "high-contrast")
}

func testCaptionAppearanceExecuteBlockForProfileID() {
    MAResetProcessLocalStateForTesting()
    let original = unsafeBitCast(MACaptionAppearanceCopyActiveProfileID(), to: NSString.self) as String
    precondition(original == "default")

    var observed = ""
    let profile = unsafeBitCast("large-text" as NSString, to: CFString.self)
    MACaptionAppearanceExecuteBlockForProfileID(profile) {
        observed = unsafeBitCast(MACaptionAppearanceCopyActiveProfileID(), to: NSString.self) as String
    }
    precondition(observed == "large-text")
    let restored = unsafeBitCast(MACaptionAppearanceCopyActiveProfileID(), to: NSString.self) as String
    precondition(restored == "default")
}
