import Foundation

/// Documented `BEAccessibilityPressedState` raw values from the pinned
/// `dotnet/macios` `BEAccessibilityPressedState` enumeration.
public enum BEAccessibilityPressedState: Int, Equatable, Hashable, Sendable {
    case undefined = 0
    case `false` = 1
    case `true` = 2
    case mixed = 3
}

/// Documented `BEGestureType` raw values from the pinned macios binding.
public enum BEGestureType: Int, Equatable, Hashable, Sendable {
    case loupe = 0
    case oneFingerTap = 1
    case doubleTapAndHold = 2
    case doubleTap = 3
    case oneFingerDoubleTap = 8
    case oneFingerTripleTap = 9
    case twoFingerSingleTap = 10
    case twoFingerRangedSelectGesture = 11
    case imPhraseBoundaryDrag = 14
    case forceTouch = 15
}

/// Native `NS_ENUM` imported as a Swift enum. Sequential C values:
/// `none = 0`, `shift = 1`, `capsLock = 2`.
public enum BEKeyModifierFlags: Int, Equatable, Hashable, Sendable {
    case none = 0
    case shift = 1
    case capsLock = 2
}

/// Documented `BESelectionTouchPhase` sequential Native values.
public enum BESelectionTouchPhase: Int, Equatable, Hashable, Sendable {
    case started = 0
    case moved = 1
    case ended = 2
    case endedMovingForward = 3
    case endedMovingBackward = 4
    case endedNotMoving = 5
}

/// Documented `BEAccessibilityContainerType` bits from macios.
public struct BEAccessibilityContainerType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let landmark = BEAccessibilityContainerType(rawValue: 1 << 0)
    public static let table = BEAccessibilityContainerType(rawValue: 1 << 1)
    public static let list = BEAccessibilityContainerType(rawValue: 1 << 2)
    public static let fieldset = BEAccessibilityContainerType(rawValue: 1 << 3)
    public static let dialog = BEAccessibilityContainerType(rawValue: 1 << 4)
    public static let tree = BEAccessibilityContainerType(rawValue: 1 << 5)
    public static let frame = BEAccessibilityContainerType(rawValue: 1 << 6)
    public static let article = BEAccessibilityContainerType(rawValue: 1 << 7)
    public static let semanticGroup = BEAccessibilityContainerType(rawValue: 1 << 8)
    public static let scrollArea = BEAccessibilityContainerType(rawValue: 1 << 9)
    public static let alert = BEAccessibilityContainerType(rawValue: 1 << 10)
    public static let descriptionList = BEAccessibilityContainerType(rawValue: 1 << 11)
}

/// Documented `BESelectionFlags` bits from macios.
public struct BESelectionFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let wordIsNearTap = BESelectionFlags(rawValue: 1 << 0)
    public static let selectionFlipped = BESelectionFlags(rawValue: 1 << 1)
    public static let phraseBoundaryChanged = BESelectionFlags(rawValue: 1 << 2)
}

/// Documented `BETextReplacementOptions` bits from macios.
public struct BETextReplacementOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let addUnderline = BETextReplacementOptions(rawValue: 1 << 0)
}

/// Host-local `UIAccessibilityTraits` bits for BrowserEngineKit extras.
/// Darwin bit positions are unobserved (oracle).
public struct BEAccessibility {
    public static let menuItem = UIAccessibilityTraits(rawValue: 1 << 40)
    public static let popUpButton = UIAccessibilityTraits(rawValue: 1 << 41)
    public static let radioButton = UIAccessibilityTraits(rawValue: 1 << 42)
    public static let readOnly = UIAccessibilityTraits(rawValue: 1 << 43)
    public static let visited = UIAccessibilityTraits(rawValue: 1 << 44)

    /// Host-local notification tokens. Darwin `UIAccessibility.Notification`
    /// values for these constants are unobserved (oracle).
    public static let selectionChangedNotification = UIAccessibility.Notification(rawValue: 0xBE01)
    public static let valueChangedNotification = UIAccessibility.Notification(rawValue: 0xBE02)
}
