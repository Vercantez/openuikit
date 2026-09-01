@_exported import Foundation
#if canImport(EventKit)
@_exported import EventKit
#endif
#if canImport(UIKit)
@_exported import UIKit
#endif

// Linux starting point for Apple's public EventKitUI module.
//
// Enumerations, bundle lookup, and platform macros compile against Foundation
// alone. Controllers and delegates compile only when EventKit and UIKit are
// importable so this module never defines lookalike EKEventStore, EKCalendar,
// EKEvent, EKEntityType, UIViewController, or UINavigationController types.
// Host presentation controls are SPI. Nothing here requests Calendar access
// or writes an Apple store.

#if os(iOS)
public var EKUI_IS_IOS: Int32 { 1 }
#else
public var EKUI_IS_IOS: Int32 { 0 }
#endif

#if targetEnvironment(simulator)
public var EKUI_IS_SIMULATOR: Int32 { 1 }
#else
public var EKUI_IS_SIMULATOR: Int32 { 0 }
#endif

/// Linux has no `EventKitUI.framework` resource bundle.
public func EventKitUIBundle() -> Bundle! {
    nil
}

public enum EKCalendarChooserDisplayStyle: Int, Hashable, Sendable {
    case allCalendars = 0
    case writableCalendarsOnly = 1
}

public enum EKCalendarChooserSelectionStyle: Int, Hashable, Sendable {
    case single = 0
    case multiple = 1
}

public enum EKEventEditViewAction: Int, Hashable, Sendable {
    case canceled = 0
    case saved = 1
    case deleted = 2

    public static var cancelled: EKEventEditViewAction { .canceled }
}

public enum EKEventViewAction: Int, Hashable, Sendable {
    case done = 0
    case responded = 1
    case deleted = 2
}

@_spi(OpenUIKitHost)
public enum EventKitUIHost: Sendable {
    /// Apple Calendar chooser/editor/viewer sheets are not available here.
    public static let calendarSheetAvailable = false
    /// This module does not write through EventKit persistence.
    public static let eventStoreWriteAvailable = false
}

@_spi(OpenUIKitHost)
public struct EventKitUIHostError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
        case calendarUIUnavailable = 1
        case invitationResponseUnavailable = 2
        case eventDeletionUnavailable = 3
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .calendarUIUnavailable:
            description = "Apple Calendar UI is unavailable on this host"
        case .invitationResponseUnavailable:
            description = "Event invitation replies are unavailable on this host"
        case .eventDeletionUnavailable:
            description = "EventKit event deletion is unavailable on this host"
        }
    }
}

#if canImport(EventKit) && canImport(UIKit)

@MainActor
public protocol EKCalendarChooserDelegate: NSObjectProtocol {
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser)
}

extension EKCalendarChooserDelegate {
    public func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }

    public func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }

    public func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }
}

@MainActor
public protocol EKEventEditViewDelegate: NSObjectProtocol {
    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    )

    /// Optional on Apple via Objective-C. Ordinary Swift conformers may omit
    /// it. The edit controller does not invoke this default and this default
    /// does not invent a calendar or call a missing EventKit API.
    func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar
}

extension EKEventEditViewDelegate {
    public func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar {
        _ = controller
        preconditionFailure(
            "eventEditViewControllerDefaultCalendar(forNewEvents:) is unimplemented and this host has no default calendar"
        )
    }
}

@MainActor
public protocol EKEventViewDelegate: NSObjectProtocol {
    func eventViewController(
        _ controller: EKEventViewController,
        didCompleteWith action: EKEventViewAction
    )
}

@MainActor
open class EKCalendarChooser: UIKit.UIViewController {
    public let selectionStyle: EKCalendarChooserSelectionStyle
    open weak var delegate: (any EKCalendarChooserDelegate)?
    open var showsCancelButton = false
    open var showsDoneButton = false
    open var selectedCalendars: Set<EKCalendar> = []

    private let storedDisplayStyle: EKCalendarChooserDisplayStyle
    private let storedEntityType: EKEntityType
    private let storedEventStore: EKEventStore
    private var isNotifyingFinish = false
    private var didNotifyFinish = false
    private var isNotifyingCancel = false
    private var didNotifyCancel = false

    @_spi(OpenUIKitHost)
    public var displayStyle: EKCalendarChooserDisplayStyle { storedDisplayStyle }

    @_spi(OpenUIKitHost)
    public var entityType: EKEntityType { storedEntityType }

    @_spi(OpenUIKitHost)
    public var eventStore: EKEventStore { storedEventStore }

    public init(
        selectionStyle style: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle,
        entityType: EKEntityType,
        eventStore: EKEventStore
    ) {
        self.selectionStyle = style
        self.storedDisplayStyle = displayStyle
        self.storedEntityType = entityType
        self.storedEventStore = eventStore
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(
        selectionStyle: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle,
        eventStore: EKEventStore
    ) {
        self.init(
            selectionStyle: selectionStyle,
            displayStyle: displayStyle,
            entityType: .event,
            eventStore: eventStore
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }

    /// Host Done control. Selection is in-memory; this does not persist calendars.
    @_spi(OpenUIKitHost)
    open func finish() {
        guard !isNotifyingFinish, !didNotifyFinish else { return }
        isNotifyingFinish = true
        didNotifyFinish = true
        delegate?.calendarChooserDidFinish(self)
        isNotifyingFinish = false
    }

    /// Host Cancel control. Does not mutate EventKit.
    @_spi(OpenUIKitHost)
    open func cancel() {
        guard !isNotifyingCancel, !didNotifyCancel else { return }
        isNotifyingCancel = true
        didNotifyCancel = true
        delegate?.calendarChooserDidCancel(self)
        isNotifyingCancel = false
    }
}

@MainActor
open class EKEventViewController: UIKit.UIViewController {
    open weak var delegate: (any EKEventViewDelegate)?
    open var event: EKEvent!
    open var allowsEditing = false
    open var allowsCalendarPreview = false

    private var isNotifyingFinish = false
    private var didNotifyFinish = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }

    /// Host dismiss control. Emits `.done` only; does not delete or respond.
    @_spi(OpenUIKitHost)
    open func finish() {
        guard !isNotifyingFinish, !didNotifyFinish else { return }
        isNotifyingFinish = true
        didNotifyFinish = true
        delegate?.eventViewController(self, didCompleteWith: .done)
        isNotifyingFinish = false
    }
}

@MainActor
open class EKEventEditViewController: UIKit.UINavigationController {
    open weak var editViewDelegate: (any EKEventEditViewDelegate)?
    open var eventStore: EKEventStore!
    open var event: EKEvent?

    private var isCancelling = false
    private var didCancel = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NSCoder loading is unavailable on this host")
    }

    /// Apple cancel path: notify `.canceled` and do not write the event store.
    open func cancelEditing() {
        guard !isCancelling, !didCancel else { return }
        isCancelling = true
        didCancel = true
        editViewDelegate?.eventEditViewController(self, didCompleteWith: .canceled)
        isCancelling = false
    }
}

#endif
