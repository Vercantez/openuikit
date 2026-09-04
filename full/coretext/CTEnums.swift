import CoreFoundation
import Foundation

public enum CTCharacterCollection: UInt16, Sendable, Hashable {
    case identityMapping = 0
    case adobeCNS1 = 1
    case adobeGB1 = 2
    case adobeJapan1 = 3
    case adobeJapan2 = 4
    case adobeKorea1 = 5

    public static var kCTIdentityMappingCharacterCollection: CTCharacterCollection { .identityMapping }
    public static var kCTAdobeCNS1CharacterCollection: CTCharacterCollection { .adobeCNS1 }
    public static var kCTAdobeGB1CharacterCollection: CTCharacterCollection { .adobeGB1 }
    public static var kCTAdobeJapan1CharacterCollection: CTCharacterCollection { .adobeJapan1 }
    public static var kCTAdobeJapan2CharacterCollection: CTCharacterCollection { .adobeJapan2 }
    public static var kCTAdobeKorea1CharacterCollection: CTCharacterCollection { .adobeKorea1 }
}

public enum CTFontDescriptorMatchingState: UInt32, Sendable, Hashable {
    case didBegin = 0
    case didFinish = 1
    case willBeginQuerying = 2
    case stalled = 3
    case willBeginDownloading = 4
    case downloading = 5
    case didFinishDownloading = 6
    case didMatch = 7
    case didFailWithError = 8
}

public enum CTFontFormat: UInt32, Sendable, Hashable {
    case unrecognized = 0
    case openTypePostScript = 1
    case openTypeTrueType = 2
    case trueType = 3
    case postScript = 4
    case bitmap = 5
}

public enum CTFontManagerAutoActivationSetting: UInt32, Sendable, Hashable {
    case `default` = 0
    case disabled = 1
    case enabled = 2
}

public enum CTFontOrientation: UInt32, Sendable, Hashable {
    case `default` = 0
    case horizontal = 1
    case vertical = 2

    public static var kCTFontDefaultOrientation: CTFontOrientation { .default }
    public static var kCTFontHorizontalOrientation: CTFontOrientation { .horizontal }
    public static var kCTFontVerticalOrientation: CTFontOrientation { .vertical }
}

public enum CTFontUIFontType: UInt32, Sendable, Hashable {
    case none = 0xFFFF_FFFF
    case user = 0
    case userFixedPitch = 1
    case system = 2
    case emphasizedSystem = 3
    case smallSystem = 4
    case smallEmphasizedSystem = 5
    case miniSystem = 6
    case miniEmphasizedSystem = 7
    case views = 8
    case application = 9
    case label = 10
    case menuTitle = 11
    case menuItem = 12
    case menuItemMark = 13
    case menuItemCmdKey = 14
    case windowTitle = 15
    case pushButton = 16
    case utilityWindowTitle = 17
    case alertHeader = 18
    case systemDetail = 19
    case emphasizedSystemDetail = 20
    case toolbar = 21
    case smallToolbar = 22
    case message = 23
    case palette = 24
    case toolTip = 25
    case controlContent = 26

    public static var kCTFontNoFontType: CTFontUIFontType { .none }
    public static var kCTFontUserFontType: CTFontUIFontType { .user }
    public static var kCTFontUserFixedPitchFontType: CTFontUIFontType { .userFixedPitch }
    public static var kCTFontSystemFontType: CTFontUIFontType { .system }
    public static var kCTFontEmphasizedSystemFontType: CTFontUIFontType { .emphasizedSystem }
    public static var kCTFontSmallSystemFontType: CTFontUIFontType { .smallSystem }
    public static var kCTFontSmallEmphasizedSystemFontType: CTFontUIFontType { .smallEmphasizedSystem }
    public static var kCTFontMiniSystemFontType: CTFontUIFontType { .miniSystem }
    public static var kCTFontMiniEmphasizedSystemFontType: CTFontUIFontType { .miniEmphasizedSystem }
    public static var kCTFontViewsFontType: CTFontUIFontType { .views }
    public static var kCTFontApplicationFontType: CTFontUIFontType { .application }
    public static var kCTFontLabelFontType: CTFontUIFontType { .label }
    public static var kCTFontMenuTitleFontType: CTFontUIFontType { .menuTitle }
    public static var kCTFontMenuItemFontType: CTFontUIFontType { .menuItem }
    public static var kCTFontMenuItemMarkFontType: CTFontUIFontType { .menuItemMark }
    public static var kCTFontMenuItemCmdKeyFontType: CTFontUIFontType { .menuItemCmdKey }
    public static var kCTFontWindowTitleFontType: CTFontUIFontType { .windowTitle }
    public static var kCTFontPushButtonFontType: CTFontUIFontType { .pushButton }
    public static var kCTFontUtilityWindowTitleFontType: CTFontUIFontType { .utilityWindowTitle }
    public static var kCTFontAlertHeaderFontType: CTFontUIFontType { .alertHeader }
    public static var kCTFontSystemDetailFontType: CTFontUIFontType { .systemDetail }
    public static var kCTFontEmphasizedSystemDetailFontType: CTFontUIFontType { .emphasizedSystemDetail }
    public static var kCTFontToolbarFontType: CTFontUIFontType { .toolbar }
    public static var kCTFontSmallToolbarFontType: CTFontUIFontType { .smallToolbar }
    public static var kCTFontMessageFontType: CTFontUIFontType { .message }
    public static var kCTFontPaletteFontType: CTFontUIFontType { .palette }
    public static var kCTFontToolTipFontType: CTFontUIFontType { .toolTip }
    public static var kCTFontControlContentFontType: CTFontUIFontType { .controlContent }
}

public enum CTFramePathFillRule: UInt32, Sendable, Hashable {
    case evenOdd = 0
    case windingNumber = 1
}

public enum CTFrameProgression: UInt32, Sendable, Hashable {
    case topToBottom = 0
    case rightToLeft = 1
    case leftToRight = 2
}

public enum CTLineBreakMode: UInt8, Sendable, Hashable {
    case byWordWrapping = 0
    case byCharWrapping = 1
    case byClipping = 2
    case byTruncatingHead = 3
    case byTruncatingTail = 4
    case byTruncatingMiddle = 5
}

public enum CTLineTruncationType: UInt32, Sendable, Hashable {
    case start = 0
    case end = 1
    case middle = 2
}

public enum CTParagraphStyleSpecifier: UInt32, Sendable, Hashable {
    case alignment = 0
    case firstLineHeadIndent = 1
    case headIndent = 2
    case tailIndent = 3
    case tabStops = 4
    case defaultTabInterval = 5
    case lineBreakMode = 6
    case lineHeightMultiple = 7
    case maximumLineHeight = 8
    case minimumLineHeight = 9
    case paragraphSpacing = 11
    case paragraphSpacingBefore = 12
    case baseWritingDirection = 13
    case maximumLineSpacing = 14
    case minimumLineSpacing = 15
    case lineSpacingAdjustment = 16
    case lineBoundsOptions = 17
    case count = 18
}

public enum CTRubyAlignment: UInt8, Sendable, Hashable {
    case invalid = 255
    case auto = 0
    case start = 1
    case center = 2
    case end = 3
    case distributeLetter = 4
    case distributeSpace = 5
    case lineEdge = 6
}

public enum CTRubyOverhang: UInt8, Sendable, Hashable {
    case invalid = 255
    case auto = 0
    case start = 1
    case end = 2
    case none = 3
}

public enum CTRubyPosition: UInt8, Sendable, Hashable {
    case before = 0
    case after = 1
    case interCharacter = 2
    case inline = 3
    case count = 4
}

public enum CTTextAlignment: UInt8, Sendable, Hashable {
    case left = 0
    case right = 1
    case center = 2
    case justified = 3
    case natural = 4

    public static var kCTLeftTextAlignment: CTTextAlignment { .left }
    public static var kCTRightTextAlignment: CTTextAlignment { .right }
    public static var kCTCenterTextAlignment: CTTextAlignment { .center }
    public static var kCTJustifiedTextAlignment: CTTextAlignment { .justified }
    public static var kCTNaturalTextAlignment: CTTextAlignment { .natural }
}

public enum CTWritingDirection: Int8, Sendable, Hashable {
    case natural = -1
    case leftToRight = 0
    case rightToLeft = 1
}
