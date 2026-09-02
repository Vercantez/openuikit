// UIDatePicker — app-facing date/time state plus portable inline and wheel UI.
// Owner: controls/app-compat cluster.
//
// The public state and sizing rules in this file were measured on an iOS
// 26.1 iPhone 17 Pro Simulator.  In particular:
//
//   * raw values: mode 0...4 and style 0...3;
//   * automatic resolves to compact for date/time modes;
//   * wheels fit at 320 x 216; inline date/time/date-time fit at heights
//     440/114/482; compact date fits at 34.333 pt and the other modes at 36;
//   * compact and inline have no intrinsic size;
//   * date bounds clamp immediately, programmatic changes emit no actions;
//   * countdown values are minute-truncated and limited to 23:59;
//   * minute rounding floors the minute component while preserving seconds.
//
// The wheels reuse OpenUIKit's measured UIPickerView cylinder.  The inline
// calendar is deliberately portable: it is a functional 7 x 6 Gregorian-ish
// grid driven by the caller's Calendar, but its typography/material and fixed
// English month/weekday abbreviations are not an iOS pixel reproduction.
// Those visual and locale gaps are recorded in docs/KNOWN_GAPS.md.

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

/// UIKit's date-picker presentation choices and raw values.
@available(iOS 13.4, *)
public enum UIDatePickerStyle: Int, Sendable {
    case automatic = 0
    case wheels = 1
    case compact = 2
    @available(iOS 14.0, *)
    case inline = 3
}

@preconcurrency @MainActor
@available(iOS 2.0, *)
open class UIDatePicker: UIControl {
    /// UIKit's date-picker modes and raw values.
    public enum Mode: Int, Sendable {
        case time = 0
        case date = 1
        case dateAndTime = 2
        case countDownTimer = 3
        @available(iOS 17.4, *)
        case yearAndMonth = 4
    }

    // MARK: Public model

    open var datePickerMode: Mode = .dateAndTime {
        didSet {
            guard datePickerMode != oldValue else { return }
            precondition(styleIsSupported,
                         "UIDatePicker mode is unsupported by the requested style")
            if datePickerMode == .countDownTimer {
                resetDateForCountdownEntry()
                if _countDownDuration < 60 { _countDownDuration = 60 }
            }
            applyNaturalFrame(afterModeChangeFrom: oldValue)
            reapplyBounds()
            refreshPresentation()
        }
    }

    private var storedLocale: Locale?

    /// UIKit interprets nil through the process locale. OpenUIKit keeps nil as
    /// "use the picker's deterministic calendar locale" so scripted renders do
    /// not depend on the host process. Non-nil values are snapshotted by ID.
    open var locale: Locale? {
        get { storedLocale }
        set {
            storedLocale = newValue.map(Self.snapshotLocale)
            displayedMonth = monthStart(for: _date)
            refreshPresentation()
        }
    }

    private var storedCalendar: Calendar = UIDatePicker.canonicalCalendar()

    /// UIKit imports this Objective-C `null_resettable` property as an
    /// implicitly unwrapped optional. UIKit resets nil to currentCalendar;
    /// OpenUIKit resets it to its documented deterministic calendar.
    open var calendar: Calendar! {
        get { storedCalendar }
        set {
            storedCalendar = newValue.map(Self.snapshotCalendar)
                ?? Self.canonicalCalendar()
            displayedMonth = monthStart(for: _date)
            refreshPresentation()
        }
    }

    private var storedTimeZone: TimeZone?

    open var timeZone: TimeZone? {
        get { storedTimeZone }
        set {
            storedTimeZone = newValue.map(Self.snapshotTimeZone)
            displayedMonth = monthStart(for: _date)
            refreshPresentation()
        }
    }

    private var _date: Date

    /// Programmatic assignment updates the model and visuals but never emits
    /// `.valueChanged`, as measured on UIKit.
    open var date: Date {
        get { _date }
        set { setDateValue(newValue, userInitiated: false) }
    }

    private var _minimumDate: Date?

    open var minimumDate: Date? {
        get { _minimumDate }
        set {
            guard newValue.map(Self.isSupportedDate) ?? true else { return }
            _minimumDate = newValue
            reapplyBounds()
        }
    }

    private var _maximumDate: Date?

    open var maximumDate: Date? {
        get { _maximumDate }
        set {
            guard newValue.map(Self.isSupportedDate) ?? true else { return }
            _maximumDate = newValue
            reapplyBounds()
        }
    }

    private var _countDownDuration: TimeInterval = 0

    open var countDownDuration: TimeInterval {
        get { _countDownDuration }
        set {
            // UIKit ignores this property outside countdown mode. Entering
            // countdown subsequently normalizes the untouched zero to 60.
            guard datePickerMode == .countDownTimer else { return }
            // UIKit accepts 00:00 as its initial value, but an invalid
            // assignment (negative, below one minute, or beyond 23:59)
            // normalizes to one minute.  Valid values drop remaining seconds.
            if newValue.isFinite, newValue >= 60, newValue <= 86_399 {
                _countDownDuration = (newValue / 60).rounded(.down) * 60
            } else {
                _countDownDuration = 60
            }
            refreshPresentation()
        }
    }

    private var _minuteInterval = 1

    open var minuteInterval: Int {
        get { _minuteInterval }
        set {
            // UIKit documents divisors of 60 in 1...30.  Objective-C raises
            // for invalid input; a portable framework cannot surface that
            // exception safely, so invalid assignments leave the prior value.
            guard (1...30).contains(newValue), 60 % newValue == 0 else { return }
            guard newValue != _minuteInterval else { return }
            _minuteInterval = newValue
            // UIKit does not retroactively re-round `date` when the interval
            // changes. `roundsToMinuteInterval`'s false->true edge does.
            refreshPresentation()
        }
    }

    @available(iOS 13.4, *)
    open var preferredDatePickerStyle: UIDatePickerStyle = .automatic {
        didSet {
            guard preferredDatePickerStyle != oldValue else { return }
            precondition(styleIsSupported,
                         "UIDatePicker style is unsupported by the requested mode")
            applyNaturalFrame()
            refreshPresentation()
        }
    }

    /// Always concrete, including when `preferredDatePickerStyle` is
    /// `.automatic`.
    @available(iOS 13.4, *)
    open var datePickerStyle: UIDatePickerStyle { resolvedStyle }

    @available(iOS 15.0, *)
    open var roundsToMinuteInterval = true {
        didSet {
            if roundsToMinuteInterval, !oldValue {
                setDateValue(_date, userInitiated: false)
            }
        }
    }

    open func setDate(_ date: Date, animated: Bool) {
        // OpenUIKit has no wheel-scroll animation yet; model semantics are
        // identical for both values of `animated`.
        _ = animated
        setDateValue(date, userInitiated: false)
    }

    // MARK: Construction

    private var usesNaturalFrame: Bool
    private let wheelPicker = UIPickerView(frame: .zero)
    private lazy var wheelAdapter = WheelAdapter(owner: self)
    private let compactLabel = UILabel()
    private let monthLabel = UILabel()
    private let previousMonthButton = UIButton(type: .system)
    private let nextMonthButton = UIButton(type: .system)
    private var weekdayLabels: [UILabel] = []
    private var dayButtons: [UIButton] = []
    private var displayedMonth: Date
    private var synchronizingWheel = false
    // A UIDatePicker is a bounded control, not an unbounded scrolling canvas.
    // Keep hostile public geometry out of the private UIPickerView cylinder:
    // its row-count geometry necessarily converts a finite CGFloat to Int.
    // 16K points is far beyond every measured/native picker size while
    // placing a deterministic ceiling on layout work.
    private static let maximumPresentationExtent: CGFloat = 16_384

    private static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    private static let shortMonthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    private static let weekdayNames = ["S", "M", "T", "W", "T", "F", "S"]

    /// Keeps UIDatePicker's implementation detail out of its public protocol
    /// conformances. UIKit's UIDatePicker is not itself a picker data source
    /// or delegate; exposing that conformance changes downstream overload and
    /// generic resolution even if apps never call the methods directly.
    @MainActor
    private final class WheelAdapter: UIPickerViewDataSource, UIPickerViewDelegate {
        weak var owner: UIDatePicker?

        init(owner: UIDatePicker) {
            self.owner = owner
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            _ = pickerView
            return owner?.wheelNumberOfComponents() ?? 0
        }

        func pickerView(_ pickerView: UIPickerView,
                        numberOfRowsInComponent component: Int) -> Int {
            _ = pickerView
            return owner?.wheelNumberOfRows(in: component) ?? 0
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                        forComponent component: Int) -> String? {
            _ = pickerView
            return owner?.wheelTitle(for: row, component: component)
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                        inComponent component: Int) {
            owner?.wheelDidSelect(row: row, component: component,
                                  pickerView: pickerView)
        }
    }

    public override init(frame: CGRect) {
        usesNaturalFrame = frame == .zero
        _date = UIDatePicker.initialModelDate()
        displayedMonth = _date
        let initial = frame == .zero
            ? CGRect(x: 0, y: 0, width: 228, height: 36) : frame
        super.init(frame: initial)
        displayedMonth = monthStart(for: _date)
        configurePresentationViews()
        refreshPresentation()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        usesNaturalFrame = false
        _date = UIDatePicker.initialModelDate()
        displayedMonth = _date
        super.init(coder: coder)
        displayedMonth = monthStart(for: _date)
        configurePresentationViews()
        refreshPresentation()
    }

    private func configurePresentationViews() {
        isOpaque = false

        wheelPicker.dataSource = wheelAdapter
        wheelPicker.delegate = wheelAdapter
        // UIPickerView's measured geometry is presently jump-only.  Route
        // taps through this control so a tap above/below the centre advances
        // the corresponding component and emits the date-picker action.
        wheelPicker.isUserInteractionEnabled = false
        addSubview(wheelPicker)

        compactLabel.textAlignment = .center
        compactLabel.font = .systemFont(ofSize: 15)
        compactLabel.textColor = .label
        compactLabel.layer.cornerRadius = 7
        compactLabel.clipsToBounds = true
        compactLabel.backgroundColor = .secondarySystemBackground
        addSubview(compactLabel)

        monthLabel.textAlignment = .center
        monthLabel.font = .boldSystemFont(ofSize: 17)
        monthLabel.textColor = .label
        addSubview(monthLabel)

        previousMonthButton.setTitle("‹", for: .normal)
        previousMonthButton.titleLabel?.font = .systemFont(ofSize: 28)
        previousMonthButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.moveDisplayedMonth(by: -1)
        }
        addSubview(previousMonthButton)

        nextMonthButton.setTitle("›", for: .normal)
        nextMonthButton.titleLabel?.font = .systemFont(ofSize: 28)
        nextMonthButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.moveDisplayedMonth(by: 1)
        }
        addSubview(nextMonthButton)

        for index in 0..<7 {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.tag = index
            weekdayLabels.append(label)
            addSubview(label)
        }

        for day in 1...42 {
            let button = UIButton(type: .system)
            button.tag = day
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.layer.cornerRadius = 16
            button.addTarget(for: .touchUpInside) { [weak self, weak button] _, _ in
                guard let self, let button else { return }
                self.selectInlineDay(button.tag)
            }
            dayButtons.append(button)
            addSubview(button)
        }
    }

    // MARK: Date semantics

    // Foundation's practical calendrical range is much smaller than Double's.
    // Keeping conversions inside roughly years 5...3997 prevents hostile but
    // finite values from reaching Calendar implementations with unbounded work
    // or integer conversions. Out-of-range public assignments are ignored.
    private static let minimumSupportedReferenceTime: TimeInterval = -63_000_000_000
    private static let maximumSupportedReferenceTime: TimeInterval = 63_000_000_000

    /// UIKit starts at the current wall-clock instant. OpenUIKit never reads a
    /// wall clock: the host supplies time through `UIWindow.tick(timestamp:)`.
    /// Interpret that exact finite value in Foundation's reference-date domain
    /// so identical host traces construct identical controls and renders.
    private static func initialModelDate() -> Date {
        let hostTime = Timer.currentTime.isFinite ? Timer.currentTime : 0
        return Date.init(timeIntervalSinceReferenceDate: hostTime)
    }

    /// Deterministic replacement for UIKit's process-dependent current
    /// calendar. All defaults and nil resets use Gregorian/en_US_POSIX/UTC,
    /// Sunday-first and one minimum day in the first week.
    private static func canonicalCalendar() -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "en_US_POSIX")
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 1
        value.minimumDaysInFirstWeek = 1
        return value
    }

    /// Reconstruct value-semantic snapshots rather than retaining an
    /// autoupdating locale/calendar/time-zone provider supplied by an app.
    private static func snapshotLocale(_ input: Locale) -> Locale {
        Locale(identifier: input.identifier)
    }

    private static func snapshotTimeZone(_ input: TimeZone) -> TimeZone {
        TimeZone(identifier: input.identifier) ?? TimeZone(secondsFromGMT: 0)!
    }

    private static func snapshotCalendar(_ input: Calendar) -> Calendar {
        var value = Calendar(identifier: input.identifier)
        value.locale = input.locale.map(snapshotLocale)
            ?? Locale(identifier: "en_US_POSIX")
        value.timeZone = snapshotTimeZone(input.timeZone)
        value.firstWeekday = (1...7).contains(input.firstWeekday)
            ? input.firstWeekday : 1
        value.minimumDaysInFirstWeek = (1...7).contains(input.minimumDaysInFirstWeek)
            ? input.minimumDaysInFirstWeek : 1
        return value
    }

    private static func isSupportedDate(_ value: Date) -> Bool {
        let reference = value.timeIntervalSinceReferenceDate
        return reference.isFinite
            && reference >= minimumSupportedReferenceTime
            && reference <= maximumSupportedReferenceTime
    }

    private var effectiveCalendar: Calendar {
        var value = storedCalendar
        if let storedLocale { value.locale = storedLocale }
        if let storedTimeZone { value.timeZone = storedTimeZone }
        return value
    }

    private func roundedDate(_ value: Date) -> Date {
        guard Self.isSupportedDate(value) else { return _date }
        guard roundsToMinuteInterval, _minuteInterval > 1 else { return value }
        let minute = effectiveCalendar.component(.minute, from: value)
        let remainder = minute % _minuteInterval
        let rounded = value.addingTimeInterval(-TimeInterval(remainder * 60))
        return Self.isSupportedDate(rounded) ? rounded : value
    }

    private func boundedDate(_ value: Date) -> Date {
        if let minimumDate, let maximumDate, minimumDate > maximumDate {
            return value
        }
        if let minimumDate, value < minimumDate { return minimumDate }
        if let maximumDate, value > maximumDate { return maximumDate }
        return value
    }

    private func setDateValue(_ value: Date, userInitiated: Bool) {
        guard Self.isSupportedDate(value) else { return }
        // UIKit applies the minute grid before the final range admission. This
        // is observable at non-grid-aligned bounds: a low input rounds below
        // minimum and then clamps to the exact minimum, while a high input may
        // round to the last grid value below maximum without adopting the
        // maximum's seconds component.
        let next = boundedDate(roundedDate(value))
        guard Self.isSupportedDate(next) else { return }
        let changed = next != _date
        _date = next
        displayedMonth = monthStart(for: next)
        refreshPresentation()
        if userInitiated, changed { sendActions(for: .valueChanged) }
    }

    private func reapplyBounds() {
        setDateValue(_date, userInitiated: false)
    }

    /// Native UIKit resets the otherwise independent `date` model to the
    /// current day's start when countdown mode is entered. The portable host
    /// clock is explicit, so this transition stays repeatable. If that time is
    /// outside the bounded Foundation calendar range, retain the prior value.
    private func resetDateForCountdownEntry() {
        let hostTime = Timer.currentTime
        guard hostTime.isFinite else { return }
        let hostDate = Date.init(timeIntervalSinceReferenceDate: hostTime)
        guard Self.isSupportedDate(hostDate) else { return }
        let start = effectiveCalendar.startOfDay(for: hostDate)
        guard Self.isSupportedDate(start) else { return }
        setDateValue(start, userInitiated: false)
    }

    private func monthStart(for value: Date) -> Date {
        guard Self.isSupportedDate(value) else { return value }
        let cal = effectiveCalendar
        let c = cal.dateComponents([.era, .year, .month], from: value)
        guard let result = cal.date(from: c), Self.isSupportedDate(result) else {
            return value
        }
        return result
    }

    private func dateComponents(for value: Date) -> DateComponents {
        guard Self.isSupportedDate(value) else { return DateComponents() }
        return effectiveCalendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: value)
    }

    private func daysInDisplayedMonth() -> Int {
        guard Self.isSupportedDate(displayedMonth) else { return 0 }
        return boundedDayCount(effectiveCalendar.range(of: .day, in: .month,
                                                       for: displayedMonth)?.count)
    }

    private func boundedDayCount(_ proposed: Int?) -> Int {
        guard let proposed, (1...42).contains(proposed) else { return 0 }
        return proposed
    }

    private func boundedMonthCount(for value: Date) -> Int {
        guard Self.isSupportedDate(value),
              let count = effectiveCalendar.range(of: .month, in: .year,
                                                  for: value)?.count,
              (1...13).contains(count) else { return 0 }
        return count
    }

    private func monthTitle(_ month: Int, short: Bool) -> String {
        guard (1...12).contains(month) else {
            return short ? "M\(month)" : "Month \(month)"
        }
        return short ? Self.shortMonthNames[month - 1]
            : Self.monthNames[month - 1]
    }

    private func candidateDate(year: Int, month: Int, day: Int,
                               hour: Int, minute: Int) -> Date? {
        let monthCount = boundedMonthCount(for: _date)
        guard (1...9_999).contains(year),
              monthCount > 0, (1...monthCount).contains(month),
              (1...42).contains(day),
              (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }
        let cal = effectiveCalendar
        let maxDay: Int
        var monthComponents = DateComponents()
        monthComponents.year = year
        monthComponents.month = month
        monthComponents.day = 1
        if let first = cal.date(from: monthComponents) {
            maxDay = boundedDayCount(cal.range(of: .day, in: .month,
                                               for: first)?.count)
        } else {
            return nil
        }
        guard maxDay > 0 else { return nil }
        var c = dateComponents(for: _date)
        c.year = year
        c.month = month
        // Wheel changes are applied component-at-a-time. UIKit clamps a day
        // that becomes invalid when the month or year changes (Jan 31 -> Feb
        // 28, or leap day -> a non-leap year) instead of rejecting the turn.
        c.day = min(day, maxDay)
        c.hour = hour
        c.minute = minute
        guard let result = cal.date(from: c), Self.isSupportedDate(result) else {
            return nil
        }
        return result
    }

    // MARK: Style and sizing

    private var resolvedStyle: UIDatePickerStyle {
        resolvedStyle(for: datePickerMode)
    }

    private func resolvedStyle(for mode: Mode) -> UIDatePickerStyle {
        if preferredDatePickerStyle == .automatic {
            if mode == .countDownTimer || mode == .yearAndMonth {
                return .wheels
            }
            return .compact
        }
        return preferredDatePickerStyle
    }

    private var styleIsSupported: Bool {
        guard datePickerMode == .countDownTimer || datePickerMode == .yearAndMonth
        else { return true }
        return preferredDatePickerStyle == .automatic
            || preferredDatePickerStyle == .wheels
    }

    private var compactNaturalWidth: CGFloat {
        switch datePickerMode {
        case .time, .countDownTimer: return 96.667
        case .date, .yearAndMonth: return 127.333
        case .dateAndTime: return 228
        }
    }

    private func applyNaturalFrame(afterModeChangeFrom oldMode: Mode? = nil) {
        guard usesNaturalFrame else { return }
        // Changing among compact date/time modes does not rewrite UIKit's
        // existing 228 x 36 frame.  A subsequent sizeToFit uses the mode's
        // narrower measured fitting width.
        if let oldMode, resolvedStyle == .compact {
            guard resolvedStyle(for: oldMode) != .compact else { return }
            // Automatic countdown/year-month uses a 320 pt wheel. Returning
            // to a compact mode preserves that width but immediately adopts
            // the compact height, as measured on iOS 26.1.
            frame = CGRect(x: frame.minX, y: frame.minY,
                           width: frame.width,
                           height: datePickerMode == .date ? 34.333 : 36)
            return
        }
        let size: CGSize
        switch resolvedStyle {
        case .wheels:
            size = CGSize(width: 320, height: 216)
        case .inline:
            switch datePickerMode {
            case .time:
                size = CGSize(width: 228, height: 52)
            case .dateAndTime:
                size = CGSize(width: 320, height: 366)
            default:
                // UIKit installs a 324 pt initial date-only inline frame;
                // sizeThatFits then reports the complete 440 pt calendar.
                size = CGSize(width: 320, height: 324)
            }
        case .compact, .automatic:
            size = CGSize(width: 228, height: 36)
        }
        frame = CGRect(origin: frame.origin, size: size)
    }

    open override var intrinsicContentSize: CGSize {
        switch resolvedStyle {
        case .wheels: return CGSize(width: 320, height: 216)
        case .compact, .inline, .automatic:
            return CGSize(width: UIView.noIntrinsicMetric,
                          height: UIView.noIntrinsicMetric)
        }
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        switch resolvedStyle {
        case .wheels:
            return CGSize(width: 320, height: 216)
        case .inline:
            switch datePickerMode {
            case .time:
                return CGSize(width: size.width > 0 ? size.width : 112.667,
                              height: 114)
            case .dateAndTime:
                return CGSize(width: 320, height: 482)
            default:
                return CGSize(width: 320, height: 440)
            }
        case .compact, .automatic:
            return CGSize(width: size.width > 0 ? size.width : compactNaturalWidth,
                          height: datePickerMode == .date ? 34.333 : 36)
        }
    }

    // MARK: Presentation refresh/layout

    private func refreshPresentation() {
        updatePresentationVisibility()
        let style = resolvedStyle
        let inlineTime = style == .inline && datePickerMode == .time
        let inlineDateAndTime = style == .inline && datePickerMode == .dateAndTime
        if style == .wheels || inlineTime {
            synchronizingWheel = true
            wheelPicker.reloadAllComponents()
            synchronizeWheelSelection()
            synchronizingWheel = false
        } else if style == .compact {
            compactLabel.text = compactTitle
        } else if style == .inline {
            updateInlineCalendar()
            if inlineDateAndTime { compactLabel.text = timeTitle }
        }
        setNeedsLayout()
    }

    private func updatePresentationVisibility() {
        let style = resolvedStyle
        let inlineTime = style == .inline && datePickerMode == .time
        let inlineCalendar = style == .inline && !inlineTime
        let inlineDateAndTime = style == .inline && datePickerMode == .dateAndTime
        wheelPicker.isHidden = style != .wheels && !inlineTime
        compactLabel.isHidden = style != .compact && !inlineDateAndTime
        monthLabel.isHidden = !inlineCalendar
        previousMonthButton.isHidden = !inlineCalendar
        nextMonthButton.isHidden = !inlineCalendar
        for label in weekdayLabels { label.isHidden = !inlineCalendar }
        for button in dayButtons { button.isHidden = !inlineCalendar }
    }

    private var compactTitle: String {
        let c = dateComponents(for: _date)
        let year = c.year ?? 1
        let month = c.month ?? 1
        let day = c.day ?? 1
        let hour = c.hour ?? 0
        let minute = c.minute ?? 0
        switch datePickerMode {
        case .time:
            return "\(twoDigits(hour)):\(twoDigits(minute))"
        case .date:
            return "\(twoDigits(month))/\(twoDigits(day))/\(year)"
        case .dateAndTime:
            return "\(twoDigits(month))/\(twoDigits(day))/\(year)  \(twoDigits(hour)):\(twoDigits(minute))"
        case .countDownTimer:
            let total = Int(_countDownDuration / 60)
            return "\(twoDigits(total / 60)):\(twoDigits(total % 60))"
        case .yearAndMonth:
            return "\(monthTitle(month, short: false)) \(year)"
        }
    }

    private var timeTitle: String {
        let c = dateComponents(for: _date)
        return "\(twoDigits(c.hour ?? 0)):\(twoDigits(c.minute ?? 0))"
    }

    private func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard hasSupportedPresentationViewport else {
            clearPresentationFrames()
            return
        }
        updatePresentationVisibility()
        switch resolvedStyle {
        case .wheels:
            wheelPicker.frame = bounds
        case .compact, .automatic:
            compactLabel.frame = bounds
        case .inline:
            if datePickerMode == .time {
                wheelPicker.frame = bounds
            } else {
                layoutInlineCalendar()
                if datePickerMode == .dateAndTime {
                    compactLabel.frame = CGRect(x: bounds.minX + 8,
                                                y: bounds.maxY - 42,
                                                width: max(0, bounds.width - 16),
                                                height: 36)
                }
            }
        }
    }

    private var hasSupportedPresentationViewport: Bool {
        let values = [bounds.origin.x, bounds.origin.y,
                      bounds.size.width, bounds.size.height]
        guard values.allSatisfy(\.isFinite),
              bounds.size.width > 0, bounds.size.height > 0 else { return false }
        let limit = Self.maximumPresentationExtent
        return abs(bounds.origin.x) <= limit
            && abs(bounds.origin.y) <= limit
            && bounds.size.width <= limit
            && bounds.size.height <= limit
    }

    private func clearPresentationFrames() {
        let presentationViews: [UIView] = [
            wheelPicker, compactLabel, monthLabel,
            previousMonthButton, nextMonthButton,
        ] + weekdayLabels + dayButtons
        for view in presentationViews {
            view.isHidden = true
            view.frame = .zero
        }
    }

    private func layoutInlineCalendar() {
        var calendarBounds = bounds
        if datePickerMode == .dateAndTime {
            calendarBounds.size.height = max(0, calendarBounds.height - 42)
        }
        let headerHeight: CGFloat = min(52, max(36, calendarBounds.height * 0.13))
        let weekdayHeight: CGFloat = min(30, max(20, calendarBounds.height * 0.07))
        previousMonthButton.frame = CGRect(x: calendarBounds.minX,
                                           y: calendarBounds.minY,
                                           width: 44, height: headerHeight)
        nextMonthButton.frame = CGRect(x: calendarBounds.maxX - 44,
                                       y: calendarBounds.minY,
                                       width: 44, height: headerHeight)
        monthLabel.frame = CGRect(x: calendarBounds.minX + 44,
                                  y: calendarBounds.minY,
                                  width: max(0, calendarBounds.width - 88),
                                  height: headerHeight)

        let cellWidth = calendarBounds.width / 7
        let weekdayY = calendarBounds.minY + headerHeight
        for index in weekdayLabels.indices {
            weekdayLabels[index].frame = CGRect(
                x: calendarBounds.minX + CGFloat(index) * cellWidth,
                y: weekdayY, width: cellWidth, height: weekdayHeight)
        }

        let gridY = weekdayY + weekdayHeight
        let cellHeight = max(0, (calendarBounds.maxY - gridY) / 6)
        for index in dayButtons.indices {
            let column = index % 7
            let row = index / 7
            let cell = CGRect(x: calendarBounds.minX + CGFloat(column) * cellWidth,
                              y: gridY + CGFloat(row) * cellHeight,
                              width: cellWidth, height: cellHeight)
            let diameter = min(36, max(0, min(cell.width, cell.height) - 4))
            dayButtons[index].frame = CGRect(
                x: cell.midX - diameter / 2, y: cell.midY - diameter / 2,
                width: diameter, height: diameter)
            dayButtons[index].layer.cornerRadius = diameter / 2
        }
    }

    private func updateInlineCalendar() {
        guard Self.isSupportedDate(displayedMonth), Self.isSupportedDate(_date) else {
            monthLabel.text = nil
            for label in weekdayLabels { label.text = nil }
            for button in dayButtons {
                button.setTitle(nil, for: .normal)
                button.isEnabled = false
                button.backgroundColor = nil
            }
            return
        }
        let cal = effectiveCalendar
        let c = cal.dateComponents([.year, .month], from: displayedMonth)
        let year = c.year ?? 1
        let month = c.month ?? 1
        monthLabel.text = "\(monthTitle(month, short: false)) \(year)"

        let firstWeekday = max(1, min(7, cal.firstWeekday))
        for index in weekdayLabels.indices {
            let source = (firstWeekday - 1 + index) % 7
            weekdayLabels[index].text = Self.weekdayNames[source]
        }

        let rawWeekday = cal.component(.weekday, from: displayedMonth)
        let weekday = (1...7).contains(rawWeekday) ? rawWeekday : firstWeekday
        let offset = (weekday - firstWeekday + 7) % 7
        let dayCount = daysInDisplayedMonth()
        let selected = dateComponents(for: _date)

        for index in dayButtons.indices {
            let button = dayButtons[index]
            let day = index - offset + 1
            guard day >= 1, day <= dayCount else {
                button.setTitle(nil, for: .normal)
                button.isEnabled = false
                button.backgroundColor = nil
                continue
            }
            button.tag = day
            button.setTitle("\(day)", for: .normal)
            var test = DateComponents()
            test.year = year
            test.month = month
            test.day = day
            let candidate = cal.date(from: test)
            button.isEnabled = candidate.map(dateAllowed) ?? false
            let isSelected = selected.year == year && selected.month == month
                && selected.day == day
            button.backgroundColor = isSelected ? tintColor : nil
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.setTitleColor(.secondaryLabel, for: .disabled)
        }
    }

    private func dateAllowed(_ value: Date) -> Bool {
        guard Self.isSupportedDate(value) else { return false }
        if let minimumDate, let maximumDate, minimumDate > maximumDate {
            return true
        }
        if let minimumDate, value < monthStartOfDay(minimumDate) { return false }
        if let maximumDate, value > endOfDay(maximumDate) { return false }
        return true
    }

    private func monthStartOfDay(_ value: Date) -> Date {
        guard Self.isSupportedDate(value) else { return _date }
        let result = effectiveCalendar.startOfDay(for: value)
        return Self.isSupportedDate(result) ? result : value
    }

    private func endOfDay(_ value: Date) -> Date {
        guard Self.isSupportedDate(value) else { return _date }
        let start = effectiveCalendar.startOfDay(for: value)
        guard Self.isSupportedDate(start),
              let tomorrow = effectiveCalendar.date(byAdding: .day, value: 1,
                                                     to: start),
              Self.isSupportedDate(tomorrow) else { return value }
        let result = tomorrow.addingTimeInterval(-0.001)
        return Self.isSupportedDate(result) ? result : value
    }

    private func moveDisplayedMonth(by delta: Int) {
        guard (-1...1).contains(delta) else { return }
        guard let next = effectiveCalendar.date(byAdding: .month, value: delta,
                                                 to: displayedMonth),
              Self.isSupportedDate(next) else { return }
        displayedMonth = monthStart(for: next)
        updateInlineCalendar()
        setNeedsLayout()
    }

    /// Internal so tests can exercise the same user path without inventing a
    /// private touch.  Day buttons call this method directly.
    func selectInlineDay(_ day: Int) {
        let dayCount = daysInDisplayedMonth()
        guard dayCount > 0, (1...dayCount).contains(day) else { return }
        let cal = effectiveCalendar
        let month = cal.dateComponents([.year, .month], from: displayedMonth)
        let current = dateComponents(for: _date)
        guard let year = month.year, let monthValue = month.month,
              let candidate = candidateDate(year: year, month: monthValue,
                                            day: day,
                                            hour: current.hour ?? 0,
                                            minute: current.minute ?? 0),
              dateAllowed(candidate) else { return }
        setDateValue(candidate, userInitiated: true)
    }

    // MARK: Wheel data source/delegate

    func wheelNumberOfComponents() -> Int {
        switch datePickerMode {
        case .time, .countDownTimer, .yearAndMonth: return 2
        case .date: return 3
        case .dateAndTime: return 5
        }
    }

    func wheelNumberOfRows(in component: Int) -> Int {
        guard (0..<wheelNumberOfComponents()).contains(component) else { return 0 }
        switch datePickerMode {
        case .time:
            return component == 0 ? 24 : 60 / _minuteInterval
        case .date:
            if component == 0 { return boundedMonthCount(for: _date) }
            if component == 1 { return daysInCurrentDateMonth() }
            return 9_999
        case .dateAndTime:
            if component == 0 { return boundedMonthCount(for: _date) }
            if component == 1 { return daysInCurrentDateMonth() }
            if component == 2 { return 9_999 }
            if component == 3 { return 24 }
            return 60 / _minuteInterval
        case .countDownTimer:
            return component == 0 ? 24 : 60 / _minuteInterval
        case .yearAndMonth:
            return component == 0 ? boundedMonthCount(for: _date) : 9_999
        }
    }

    func wheelTitle(for row: Int, component: Int) -> String? {
        let rowCount = wheelNumberOfRows(in: component)
        guard row >= 0, row < rowCount else { return nil }
        switch datePickerMode {
        case .time:
            return component == 0 ? twoDigits(row)
                : twoDigits(row * _minuteInterval)
        case .date:
            if component == 0 { return monthTitle(row + 1, short: true) }
            return component == 1 ? "\(row + 1)" : "\(row + 1)"
        case .dateAndTime:
            if component == 0 { return monthTitle(row + 1, short: true) }
            if component == 1 || component == 2 { return "\(row + 1)" }
            if component == 3 { return twoDigits(row) }
            return twoDigits(row * _minuteInterval)
        case .countDownTimer:
            return component == 0 ? "\(row) hr" : "\(row * _minuteInterval) min"
        case .yearAndMonth:
            return component == 0 ? monthTitle(row + 1, short: false)
                : "\(row + 1)"
        }
    }

    private func wheelDidSelect(row: Int, component: Int,
                                pickerView: UIPickerView) {
        guard !synchronizingWheel else { return }
        let rowCount = wheelNumberOfRows(in: component)
        guard row >= 0, row < rowCount else { return }
        if datePickerMode == .countDownTimer {
            let hours = pickerView.selectedRow(inComponent: 0)
            let minutes = pickerView.selectedRow(inComponent: 1) * _minuteInterval
            let next = TimeInterval(hours * 3_600 + minutes * 60)
            let changed = next != _countDownDuration
            _countDownDuration = next
            if changed { sendActions(for: .valueChanged) }
            return
        }

        let c = dateComponents(for: _date)
        var year = c.year ?? 1
        var month = c.month ?? 1
        var day = c.day ?? 1
        var hour = c.hour ?? 0
        var minute = c.minute ?? 0

        switch datePickerMode {
        case .time:
            if component == 0 { hour = row }
            else { minute = row * _minuteInterval }
        case .date:
            if component == 0 { month = row + 1 }
            else if component == 1 { day = row + 1 }
            else { year = row + 1 }
        case .dateAndTime:
            if component == 0 { month = row + 1 }
            else if component == 1 { day = row + 1 }
            else if component == 2 { year = row + 1 }
            else if component == 3 { hour = row }
            else { minute = row * _minuteInterval }
        case .yearAndMonth:
            if component == 0 { month = row + 1 }
            else { year = row + 1 }
        case .countDownTimer:
            break
        }

        guard let candidate = candidateDate(year: year, month: month, day: day,
                                            hour: hour, minute: minute) else { return }
        setDateValue(candidate, userInitiated: true)
    }

    private func daysInCurrentDateMonth() -> Int {
        guard Self.isSupportedDate(_date) else { return 0 }
        return boundedDayCount(effectiveCalendar.range(of: .day, in: .month,
                                                       for: _date)?.count)
    }

    private func synchronizeWheelSelection() {
        let c = dateComponents(for: _date)
        let year = max(1, min(9_999, c.year ?? 1))
        let monthCount = max(1, boundedMonthCount(for: _date))
        let month = max(1, min(monthCount, c.month ?? 1))
        let dayCount = max(1, daysInCurrentDateMonth())
        let day = max(1, min(dayCount, c.day ?? 1))
        let hour = max(0, min(23, c.hour ?? 0))
        let minuteRow = max(0, min(60 / _minuteInterval - 1,
            (c.minute ?? 0) / _minuteInterval))

        switch datePickerMode {
        case .time:
            wheelPicker.selectRow(hour, inComponent: 0, animated: false)
            wheelPicker.selectRow(minuteRow, inComponent: 1, animated: false)
        case .date:
            wheelPicker.selectRow(month - 1, inComponent: 0, animated: false)
            wheelPicker.selectRow(day - 1, inComponent: 1, animated: false)
            wheelPicker.selectRow(year - 1, inComponent: 2, animated: false)
        case .dateAndTime:
            wheelPicker.selectRow(month - 1, inComponent: 0, animated: false)
            wheelPicker.selectRow(day - 1, inComponent: 1, animated: false)
            wheelPicker.selectRow(year - 1, inComponent: 2, animated: false)
            wheelPicker.selectRow(hour, inComponent: 3, animated: false)
            wheelPicker.selectRow(minuteRow, inComponent: 4, animated: false)
        case .countDownTimer:
            let totalMinutes = Int(_countDownDuration / 60)
            wheelPicker.selectRow(totalMinutes / 60, inComponent: 0, animated: false)
            wheelPicker.selectRow((totalMinutes % 60) / _minuteInterval,
                                  inComponent: 1, animated: false)
        case .yearAndMonth:
            wheelPicker.selectRow(month - 1, inComponent: 0, animated: false)
            wheelPicker.selectRow(year - 1, inComponent: 1, animated: false)
        }
    }

    /// Drives the same selection path as a wheel interaction.  Kept internal
    /// for behavioral tests and scripted hosts; UIKit's public selection API
    /// belongs to UIPickerView, not UIDatePicker.
    func selectWheelRow(_ row: Int, component: Int) {
        guard row >= 0, row < wheelNumberOfRows(in: component) else { return }
        wheelPicker.selectRow(row, inComponent: component, animated: false)
    }

    // MARK: Wheel tap interaction

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        let wheelInteraction = resolvedStyle == .wheels
            || (resolvedStyle == .inline && datePickerMode == .time)
        guard wheelInteraction, hasSupportedPresentationViewport,
              let touch else { return }
        let point = touch.location(in: self)
        guard point.x.isFinite, point.y.isFinite, bounds.width.isFinite,
              bounds.height.isFinite, bounds.width > 0, bounds.height > 0 else {
            return
        }
        let components = max(1, wheelPicker.numberOfComponents)
        let componentPosition = ((point.x - bounds.minX) / bounds.width)
            * CGFloat(components)
        guard componentPosition.isFinite else { return }
        let component = Int(max(0, min(CGFloat(components - 1),
                                       componentPosition)))
        let direction = point.y < bounds.midY ? -1 : 1
        let selected = wheelPicker.selectedRow(inComponent: component)
        wheelPicker.selectRow(selected + direction, inComponent: component,
                              animated: false)
    }
}
