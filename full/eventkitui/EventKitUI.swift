@_exported import Foundation

// MARK: - Build-time macros (EventKitUIDefines.h)
//
// Apple's headers gate these on TARGET_OS_IPHONE / TARGET_OS_SIMULATOR.
// This Linux isolated compile is neither iPhone OS nor the iOS Simulator.
// Values are therefore 0. They are not a claim that a future Darwin overlay
// would keep the same answers.

public var EKUI_IS_IOS: Int32 { 0 }

public var EKUI_IS_SIMULATOR: Int32 { 0 }

// MARK: - Framework bundle
//
// `EventKitUIBundle()` is the C export from EventKitUIBundle.h
// (`NSBundle * EventKitUIBundle(void)`). Linux has no Apple EventKitUI
// framework bundle to return. The IUO overlay is `Bundle!`; nil is the
// fail-closed result, not an invented identifier.

public func EventKitUIBundle() -> Bundle! {
    nil
}

// MARK: - EKCalendarChooserDisplayStyle
//
// Bridged `NS_ENUM(NSInteger, EKCalendarChooserDisplayStyle)` in declaration
// order from EKCalendarChooser.h. Raw values are the NS_ENUM indices.

public enum EKCalendarChooserDisplayStyle: Int, Hashable, Sendable {
    case allCalendars = 0
    case writableCalendarsOnly = 1
}

// MARK: - EKCalendarChooserSelectionStyle

public enum EKCalendarChooserSelectionStyle: Int, Hashable, Sendable {
    case single = 0
    case multiple = 1
}

// MARK: - EKEventEditViewAction
//
// Bridged `NS_ENUM(NSInteger, EKEventEditViewAction)`. The Swift overlay
// publishes both `canceled` (American spelling, the enum case) and
// `cancelled` (British spelling, a static alias).

public enum EKEventEditViewAction: Int, Hashable, Sendable {
    case canceled = 0
    case saved = 1
    case deleted = 2

    public static var cancelled: EKEventEditViewAction { .canceled }
}

// MARK: - EKEventViewAction

public enum EKEventViewAction: Int, Hashable, Sendable {
    case done = 0
    case responded = 1
    case deleted = 2
}
