import Foundation

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#endif

@_exported import CoreFoundation

#if canImport(CoreText)
import CoreText
#endif

// Linux starting point for Apple's public MediaAccessibility module.
// Caption appearance, selected languages, and profile IDs are a
// process-local state machine. System caption preferences, flashing-light
// IOSurface processing, Music Haptics, and IPTC image-caption I/O fail closed.

// MARK: - CF bridging (Linux Foundation does not toll-free-bridge with `as`)

@inline(__always)
func _maCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

@inline(__always)
func _maString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

@inline(__always)
func _maCFArray(_ array: NSArray) -> CFArray {
    unsafeBitCast(array, to: CFArray.self)
}

@inline(__always)
func _maNSArray(_ array: CFArray) -> NSArray {
    unsafeBitCast(array, to: NSArray.self)
}

@inline(__always)
func _maURL(_ value: CFURL) -> URL {
    unsafeBitCast(value, to: NSURL.self) as URL
}

@inline(__always)
func _maCFError(_ error: NSError) -> CFError {
    unsafeBitCast(error, to: CFError.self)
}

@inline(__always)
func _maPassArray(_ strings: [String]) -> Unmanaged<CFArray> {
    Unmanaged.passRetained(_maCFArray(strings as NSArray))
}

@inline(__always)
func _maPassCFArray(_ array: NSArray) -> CFArray {
    _maCFArray(array)
}

// MARK: - Host lookalikes for declared CoreGraphics / undeclared CoreText types

#if !canImport(CoreGraphics)
public final class CGColor: @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public final class IOSurfaceRef: @unchecked Sendable {
    public init() {}
}
#endif

#if !canImport(CoreText)
public final class CTFontDescriptor: @unchecked Sendable {
    public let fontStyle: MACaptionAppearanceFontStyle

    init(fontStyle: MACaptionAppearanceFontStyle) {
        self.fontStyle = fontStyle
    }
}
#endif

func _maMakeColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> CGColor {
#if canImport(CoreGraphics)
    let space = CGColorSpaceCreateDeviceRGB()
    var components: [CGFloat] = [red, green, blue, alpha]
    return components.withUnsafeMutableBufferPointer { buffer in
        CGColor(colorSpace: space, components: buffer.baseAddress!)!
    }
#else
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
#endif
}

// MARK: - Caption appearance enums
// Raw values match pinned dotnet-macios `MAEnums.cs` (`[Native]` = CFIndex).

public enum MACaptionAppearanceBehavior: CFIndex, Sendable, Hashable {
    case useValue = 0
    case useContentIfAvailable = 1
}

public enum MACaptionAppearanceDisplayType: CFIndex, Sendable, Hashable {
    case forcedOnly = 0
    case automatic = 1
    case alwaysOn = 2
}

public enum MACaptionAppearanceDomain: CFIndex, Sendable, Hashable {
    case `default` = 0
    case user = 1
}

public enum MACaptionAppearanceFontStyle: CFIndex, Sendable, Hashable {
    case `default` = 0
    case monospacedWithSerif = 1
    case proportionalWithSerif = 2
    case monospacedWithoutSerif = 3
    case proportionalWithoutSerif = 4
    case casual = 5
    case cursive = 6
    case smallCapital = 7
}

public enum MACaptionAppearanceTextEdgeStyle: CFIndex, Sendable, Hashable {
    case undefined = 0
    case none = 1
    case raised = 2
    case depressed = 3
    case uniform = 4
    case dropShadow = 5
}

// MARK: - Exported CFString identities
// Payloads equal the C identifier. Darwin string bytes are unobserved.

public let MAMediaCharacteristicDescribesMusicAndSoundForAccessibility: CFString =
    _maCFString("MAMediaCharacteristicDescribesMusicAndSoundForAccessibility")
public let MAMediaCharacteristicDescribesVideoForAccessibility: CFString =
    _maCFString("MAMediaCharacteristicDescribesVideoForAccessibility")
public let MAMediaCharacteristicTranscribesSpokenDialogForAccessibility: CFString =
    _maCFString("MAMediaCharacteristicTranscribesSpokenDialogForAccessibility")

public let kMAAudibleMediaSettingsChangedNotification: CFString =
    _maCFString("kMAAudibleMediaSettingsChangedNotification")
public let kMACaptionAppearanceSettingsChangedNotification: CFString =
    _maCFString("kMACaptionAppearanceSettingsChangedNotification")
public let kMADimFlashingLightsChangedNotification: CFString =
    _maCFString("kMADimFlashingLightsChangedNotification")

func _maPost(_ name: CFString) {
    NotificationCenter.default.post(
        name: Notification.Name(_maString(name)),
        object: nil
    )
}
