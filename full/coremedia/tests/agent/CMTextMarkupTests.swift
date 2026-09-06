import CoreFoundation
import CoreMedia
import Foundation

private func cmExpectedCFString(_ expected: String) -> CFString {
    expected.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

private func cmAssertKeyPayload(_ key: CFString, _ expected: String) {
    precondition(CFEqual(key, cmExpectedCFString(expected)))
}

func testCMTextMarkupKeyStrings() {
    let pairs: [(CFString, String)] = [
        (kCMTextMarkupAlignmentType_End, "End"),
        (kCMTextMarkupAlignmentType_Left, "Left"),
        (kCMTextMarkupAlignmentType_Middle, "Middle"),
        (kCMTextMarkupAlignmentType_Right, "Right"),
        (kCMTextMarkupAlignmentType_Start, "Start"),
        (kCMTextMarkupAttribute_Alignment, "Alignment"),
        (kCMTextMarkupAttribute_BackgroundColorARGB, "BackgroundColorARGB"),
        (kCMTextMarkupAttribute_BaseFontSizePercentageRelativeToVideoHeight, "BaseFontSizePercentageRelativeToVideoHeight"),
        (kCMTextMarkupAttribute_BoldStyle, "BoldStyle"),
        (kCMTextMarkupAttribute_CharacterBackgroundColorARGB, "CharacterBackgroundColorARGB"),
        (kCMTextMarkupAttribute_CharacterEdgeStyle, "CharacterEdgeStyle"),
        (kCMTextMarkupAttribute_FontFamilyName, "FontFamilyName"),
        (kCMTextMarkupAttribute_FontFamilyNameList, "FontFamilyNameList"),
        (kCMTextMarkupAttribute_ForegroundColorARGB, "ForegroundColorARGB"),
        (kCMTextMarkupAttribute_GenericFontFamilyName, "GenericFontFamilyName"),
        (kCMTextMarkupAttribute_ItalicStyle, "ItalicStyle"),
        (kCMTextMarkupAttribute_OrthogonalLinePositionPercentageRelativeToWritingDirection, "OrthogonalLinePositionPercentageRelativeToWritingDirection"),
        (kCMTextMarkupAttribute_RelativeFontSize, "RelativeFontSize"),
        (kCMTextMarkupAttribute_TextPositionPercentageRelativeToWritingDirection, "TextPositionPercentageRelativeToWritingDirection"),
        (kCMTextMarkupAttribute_UnderlineStyle, "UnderlineStyle"),
        (kCMTextMarkupAttribute_VerticalLayout, "VerticalLayout"),
        (kCMTextMarkupAttribute_WritingDirectionSizePercentage, "WritingDirectionSizePercentage"),
        (kCMTextMarkupCharacterEdgeStyle_Depressed, "Depressed"),
        (kCMTextMarkupCharacterEdgeStyle_DropShadow, "DropShadow"),
        (kCMTextMarkupCharacterEdgeStyle_None, "None"),
        (kCMTextMarkupCharacterEdgeStyle_Raised, "Raised"),
        (kCMTextMarkupCharacterEdgeStyle_Uniform, "Uniform"),
        (kCMTextMarkupGenericFontName_Casual, "Casual"),
        (kCMTextMarkupGenericFontName_Cursive, "Cursive"),
        (kCMTextMarkupGenericFontName_Default, "Default"),
        (kCMTextMarkupGenericFontName_Fantasy, "Fantasy"),
        (kCMTextMarkupGenericFontName_Monospace, "Monospace"),
        (kCMTextMarkupGenericFontName_MonospaceSansSerif, "MonospaceSansSerif"),
        (kCMTextMarkupGenericFontName_MonospaceSerif, "MonospaceSerif"),
        (kCMTextMarkupGenericFontName_ProportionalSansSerif, "ProportionalSansSerif"),
        (kCMTextMarkupGenericFontName_ProportionalSerif, "ProportionalSerif"),
        (kCMTextMarkupGenericFontName_SansSerif, "SansSerif"),
        (kCMTextMarkupGenericFontName_Serif, "Serif"),
        (kCMTextMarkupGenericFontName_SmallCapital, "SmallCapital"),
        (kCMTextVerticalLayout_LeftToRight, "LeftToRight"),
        (kCMTextVerticalLayout_RightToLeft, "RightToLeft"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}

func testCMSampleBufferNotificationKeyStrings() {
    cmAssertKeyPayload(kCMSampleBufferNotificationParameter_OSStatus, "OSStatus")
    cmAssertKeyPayload(kCMSampleBufferNotification_DataBecameReady, "DataBecameReady")
    cmAssertKeyPayload(kCMSampleBufferNotification_DataFailed, "DataFailed")
}
