import XCTest
import Foundation
@testable import OpenUIKit

@MainActor
final class DatePickerTests: XCTestCase {
    private var savedBackend: RenderBackend = .quartz
    private var savedCompositor: RenderCompositor = .layers
    private var savedResourceRoot = ""

    override func setUp() {
        super.setUp()
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
    }

    override func tearDown() {
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        Timer._reset()
        super.tearDown()
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int = 0, _ minute: Int = 0,
                      _ second: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = utcCalendar()
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return components.date!
    }

    func testRawValuesDefaultsAndMeasuredSizing() {
        XCTAssertEqual(UIDatePicker.Mode.time.rawValue, 0)
        XCTAssertEqual(UIDatePicker.Mode.date.rawValue, 1)
        XCTAssertEqual(UIDatePicker.Mode.dateAndTime.rawValue, 2)
        XCTAssertEqual(UIDatePicker.Mode.countDownTimer.rawValue, 3)
        XCTAssertEqual(UIDatePicker.Mode.yearAndMonth.rawValue, 4)
        XCTAssertEqual(UIDatePickerStyle.automatic.rawValue, 0)
        XCTAssertEqual(UIDatePickerStyle.wheels.rawValue, 1)
        XCTAssertEqual(UIDatePickerStyle.compact.rawValue, 2)
        XCTAssertEqual(UIDatePickerStyle.inline.rawValue, 3)

        let picker = UIDatePicker()
        XCTAssertEqual(picker.datePickerMode, .dateAndTime)
        XCTAssertEqual(picker.preferredDatePickerStyle, .automatic)
        XCTAssertEqual(picker.datePickerStyle, .compact)
        XCTAssertEqual(picker.minuteInterval, 1)
        XCTAssertEqual(picker.countDownDuration, 0)
        XCTAssertTrue(picker.roundsToMinuteInterval)
        picker.calendar = nil
        XCTAssertNotNil(picker.calendar)
        XCTAssertEqual(picker.frame.size, CGSize(width: 228, height: 36))
        XCTAssertEqual(picker.intrinsicContentSize,
                       CGSize(width: UIView.noIntrinsicMetric,
                              height: UIView.noIntrinsicMetric))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 228, height: 36))

        picker.datePickerMode = .date
        XCTAssertEqual(picker.frame.size, CGSize(width: 228, height: 36))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 127.333, height: 34.333))
        XCTAssertEqual(picker.sizeThatFits(CGSize(width: 160, height: 0)),
                       CGSize(width: 160, height: 34.333))

        picker.preferredDatePickerStyle = .inline
        XCTAssertEqual(picker.datePickerStyle, .inline)
        XCTAssertEqual(picker.frame.size, CGSize(width: 320, height: 324))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 320, height: 440))
        XCTAssertEqual(picker.sizeThatFits(CGSize(width: 160, height: 160)),
                       CGSize(width: 320, height: 440))

        picker.preferredDatePickerStyle = .wheels
        XCTAssertEqual(picker.frame.size, CGSize(width: 320, height: 216))
        XCTAssertEqual(picker.intrinsicContentSize, CGSize(width: 320, height: 216))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 320, height: 216))

        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .inline
        XCTAssertEqual(picker.frame.size, CGSize(width: 228, height: 52))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 112.667, height: 114))
        XCTAssertEqual(picker.sizeThatFits(CGSize(width: 160, height: 0)),
                       CGSize(width: 160, height: 114))

        picker.datePickerMode = .dateAndTime
        XCTAssertEqual(picker.frame.size, CGSize(width: 320, height: 366))
        XCTAssertEqual(picker.sizeThatFits(.zero), CGSize(width: 320, height: 482))

        let automaticTransition = UIDatePicker()
        automaticTransition.datePickerMode = .countDownTimer
        XCTAssertEqual(automaticTransition.frame.size,
                       CGSize(width: 320, height: 216))
        automaticTransition.datePickerMode = .date
        XCTAssertEqual(automaticTransition.frame.size,
                       CGSize(width: 320, height: 34.333))
    }

    func testDefaultDateUsesOnlyTheExplicitHostClock() {
        Timer._reset()
        defer { Timer._reset() }
        Timer._step(to: 3_661.75)

        let picker = UIDatePicker()

        XCTAssertEqual(picker.date.timeIntervalSinceReferenceDate, 3_661.75)
        picker.calendar = nil
        XCTAssertEqual(picker.calendar.identifier, .gregorian)
        XCTAssertEqual(picker.calendar.locale?.identifier, "en_US_POSIX")
        XCTAssertEqual(picker.calendar.timeZone.secondsFromGMT(), 0)
        XCTAssertEqual(picker.calendar.firstWeekday, 1)
        XCTAssertEqual(picker.calendar.minimumDaysInFirstWeek, 1)
        XCTAssertNil(picker.locale)
        XCTAssertNil(picker.timeZone)
    }

    func testExtremeFiniteHostClockIsExactButNeverEntersCalendar() {
        Timer._reset()
        defer { Timer._reset() }
        Timer._step(to: .greatestFiniteMagnitude)
        let picker = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                                width: 320, height: 320))
        XCTAssertEqual(picker.date.timeIntervalSinceReferenceDate,
                       .greatestFiniteMagnitude)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.layoutIfNeeded()
        let bitmap = UIRenderer.render(picker, scale: 1)
        XCTAssertEqual(bitmap.width, 320)
        XCTAssertEqual(bitmap.height, 320)
    }

    func testDateRoundingPreservesSecondsAndBoundsClampImmediately() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.minuteInterval = 15

        picker.date = date(2026, 8, 29, 12, 20, 57)
        let components = utcCalendar().dateComponents([.minute, .second],
                                                       from: picker.date)
        XCTAssertEqual(components.minute, 15)
        XCTAssertEqual(components.second, 57)

        picker.roundsToMinuteInterval = false
        let exact = date(2026, 8, 29, 12, 22, 31)
        picker.setDate(exact, animated: true)
        XCTAssertEqual(picker.date, exact)

        let minimum = date(2026, 8, 30, 8)
        picker.minimumDate = minimum
        XCTAssertEqual(picker.date, minimum)

        let maximum = date(2026, 8, 30, 7)
        picker.maximumDate = maximum
        // An inverted range is ignored, as documented by UIKit.
        picker.date = exact
        XCTAssertEqual(picker.date, exact)

        picker.minimumDate = nil
        picker.date = date(2026, 9, 2)
        XCTAssertEqual(picker.date, maximum)
    }

    func testNativeRoundingToggleIntervalChangeAndNonalignedBoundOrder() {
        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)

        let rounded = UIDatePicker()
        rounded.calendar = utcCalendar()
        rounded.timeZone = TimeZone(secondsFromGMT: 0)
        rounded.roundsToMinuteInterval = false
        rounded.minuteInterval = 15
        rounded.date = base.addingTimeInterval(7 * 60 + 37)
        XCTAssertEqual(rounded.date.timeIntervalSinceReferenceDate, 800_000_457)
        rounded.roundsToMinuteInterval = true
        XCTAssertEqual(rounded.date.timeIntervalSinceReferenceDate, 800_000_157)

        rounded.roundsToMinuteInterval = false
        rounded.date = base.addingTimeInterval(22 * 60 + 11)
        rounded.roundsToMinuteInterval = true
        XCTAssertEqual(rounded.date.timeIntervalSinceReferenceDate, 800_001_031)
        rounded.minuteInterval = 30
        XCTAssertEqual(rounded.date.timeIntervalSinceReferenceDate, 800_001_031)

        let bounded = UIDatePicker()
        bounded.calendar = utcCalendar()
        bounded.timeZone = TimeZone(secondsFromGMT: 0)
        bounded.minuteInterval = 15
        let minimum = base.addingTimeInterval(7 * 60 + 17)
        bounded.minimumDate = minimum
        bounded.date = base
        XCTAssertEqual(bounded.date, minimum)

        bounded.minimumDate = nil
        bounded.maximumDate = base.addingTimeInterval(22 * 60 + 13)
        bounded.date = base.addingTimeInterval(30 * 60)
        XCTAssertEqual(bounded.date.timeIntervalSinceReferenceDate, 800_001_020)
    }

    func testCountdownNormalizationAndAutomaticWheelStyle() {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        XCTAssertEqual(picker.datePickerStyle, .wheels)
        picker.preferredDatePickerStyle = .wheels
        XCTAssertEqual(picker.datePickerStyle, .wheels)

        picker.countDownDuration = 3_661
        XCTAssertEqual(picker.countDownDuration, 3_660)
        picker.countDownDuration = 100_000
        XCTAssertEqual(picker.countDownDuration, 60)
        picker.countDownDuration = -1
        XCTAssertEqual(picker.countDownDuration, 60)

        picker.minuteInterval = 7
        XCTAssertEqual(picker.minuteInterval, 1)
        picker.minuteInterval = 30
        XCTAssertEqual(picker.minuteInterval, 30)
        XCTAssertEqual(picker.countDownDuration, 60)
    }

    func testCountdownModeTransitionMatrixAndDateSetterSplit() {
        Timer._reset()
        defer { Timer._reset() }
        for value: TimeInterval in [0, 59, 60, 61, 3_661, 86_399,
                                    .nan, .infinity, -.infinity] {
            let picker = UIDatePicker()
            picker.countDownDuration = value
            XCTAssertEqual(picker.countDownDuration, 0, "outside \(value)")
            picker.datePickerMode = .countDownTimer
            XCTAssertEqual(picker.countDownDuration, 60, "entering \(value)")
        }

        let normalized = UIDatePicker()
        normalized.datePickerMode = .countDownTimer
        let matrix: [(TimeInterval, TimeInterval)] = [
            (0, 60), (59, 60), (60, 60), (61, 60),
            (3_661, 3_660), (86_399, 86_340), (86_400, 60),
            (.nan, 60), (.infinity, 60), (-.infinity, 60),
        ]
        for (input, expected) in matrix {
            normalized.countDownDuration = input
            XCTAssertEqual(normalized.countDownDuration, expected, "input \(input)")
        }

        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)
        Timer._step(to: 800_010_123)
        let hostDay = utcCalendar().startOfDay(for:
            Date(timeIntervalSinceReferenceDate: Timer.currentTime))

        let transition = UIDatePicker()
        transition.calendar = utcCalendar()
        transition.timeZone = TimeZone(secondsFromGMT: 0)
        transition.roundsToMinuteInterval = false
        transition.date = base
        transition.datePickerMode = .countDownTimer
        XCTAssertEqual(transition.date, hostDay)

        let boundedTransition = UIDatePicker()
        boundedTransition.calendar = utcCalendar()
        boundedTransition.timeZone = TimeZone(secondsFromGMT: 0)
        boundedTransition.roundsToMinuteInterval = false
        boundedTransition.minimumDate = hostDay.addingTimeInterval(6_000)
        boundedTransition.maximumDate = hostDay.addingTimeInterval(7_200)
        boundedTransition.date = hostDay.addingTimeInterval(6_500)
        boundedTransition.datePickerMode = .countDownTimer
        XCTAssertEqual(boundedTransition.date,
                       hostDay.addingTimeInterval(6_000))

        let propertyVersusMethod = UIDatePicker()
        propertyVersusMethod.calendar = utcCalendar()
        propertyVersusMethod.timeZone = TimeZone(secondsFromGMT: 0)
        propertyVersusMethod.roundsToMinuteInterval = false
        propertyVersusMethod.date = base
        propertyVersusMethod.datePickerMode = .countDownTimer
        propertyVersusMethod.date = base.addingTimeInterval(5_400)
        XCTAssertEqual(propertyVersusMethod.date.timeIntervalSinceReferenceDate,
                       800_005_400)
        propertyVersusMethod.setDate(base.addingTimeInterval(7_200), animated: false)
        XCTAssertEqual(propertyVersusMethod.date.timeIntervalSinceReferenceDate,
                       800_007_200)
        propertyVersusMethod.setDate(base.addingTimeInterval(7_800), animated: true)
        XCTAssertEqual(propertyVersusMethod.date.timeIntervalSinceReferenceDate,
                       800_007_800)

        let range = UIDatePicker()
        range.calendar = utcCalendar()
        range.timeZone = TimeZone(secondsFromGMT: 0)
        range.roundsToMinuteInterval = false
        range.date = base
        range.datePickerMode = .countDownTimer
        range.minimumDate = base.addingTimeInterval(6_000)
        XCTAssertEqual(range.date.timeIntervalSinceReferenceDate,
                       800_006_000)
        range.maximumDate = base.addingTimeInterval(7_200)
        range.date = base.addingTimeInterval(9_000)
        XCTAssertEqual(range.date.timeIntervalSinceReferenceDate,
                       800_007_200)
        range.datePickerMode = .dateAndTime
        XCTAssertEqual(range.date.timeIntervalSinceReferenceDate,
                       800_007_200)

        Timer._reset()
        let unsupportedHost = UIDatePicker()
        unsupportedHost.calendar = utcCalendar()
        unsupportedHost.roundsToMinuteInterval = false
        unsupportedHost.date = base
        Timer._step(to: .greatestFiniteMagnitude)
        unsupportedHost.datePickerMode = .countDownTimer
        XCTAssertEqual(unsupportedHost.date, base)
    }

    func testHostileDatesCalendarsAndWheelCoordinatesFailClosed() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.roundsToMinuteInterval = false
        let stable = date(2026, 8, 29, 10, 15, 30)
        picker.date = stable
        var events = 0
        picker.addTarget(for: .valueChanged) { _, _ in events += 1 }

        for seconds in [Double.nan, .infinity, -.infinity,
                        Double.greatestFiniteMagnitude,
                        -Double.greatestFiniteMagnitude,
                        63_000_000_001, -63_000_000_001] {
            let hostile = Date(timeIntervalSinceReferenceDate: seconds)
            picker.date = hostile
            picker.setDate(hostile, animated: false)
            picker.minimumDate = hostile
            picker.maximumDate = hostile
            XCTAssertEqual(picker.date, stable, "hostile \(seconds)")
            XCTAssertNil(picker.minimumDate)
            XCTAssertNil(picker.maximumDate)
        }
        XCTAssertEqual(events, 0)

        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        XCTAssertEqual(picker.wheelNumberOfRows(in: -1), 0)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 99), 0)
        XCTAssertNil(picker.wheelTitle(for: -1, component: 0))
        XCTAssertNil(picker.wheelTitle(for: Int.max, component: 0))
        XCTAssertNil(picker.wheelTitle(for: 0, component: Int.max))
        picker.selectWheelRow(-1, component: 0)
        picker.selectWheelRow(Int.max, component: 0)
        picker.selectWheelRow(0, component: Int.max)
        XCTAssertEqual(picker.date, stable)
        XCTAssertEqual(events, 0)

        for identifier: Calendar.Identifier in [.hebrew, .islamicUmmAlQura,
                                                  .chinese] {
            var exotic = Calendar(identifier: identifier)
            exotic.locale = Locale(identifier: "en_US_POSIX")
            exotic.timeZone = TimeZone(secondsFromGMT: 0)!
            picker.calendar = exotic
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .inline
            picker.layoutIfNeeded()
            let bitmap = UIRenderer.render(picker, scale: 1)
            XCTAssertGreaterThanOrEqual(bitmap.width, 0)
            XCTAssertGreaterThanOrEqual(bitmap.height, 0)
        }
    }

    func testHostilePresentationViewportsAreInertBeforeWheelGeometry() {
        TextTestSupport.configureResourceRoot()
        let hostile: [(String, CGRect)] = [
            ("zero", .zero),
            ("negative", CGRect(x: 0, y: 0, width: -1, height: 160)),
            ("nan-size", CGRect(x: 0, y: 0, width: CGFloat.nan, height: 160)),
            ("infinite-size", CGRect(x: 0, y: 0,
                                     width: 160, height: CGFloat.infinity)),
            ("infinite-origin", CGRect(x: -CGFloat.infinity, y: 0,
                                       width: 160, height: 160)),
            ("greatest-size", CGRect(x: 0, y: 0,
                                     width: 160,
                                     height: CGFloat.greatestFiniteMagnitude)),
            ("greatest-origin", CGRect(x: CGFloat.greatestFiniteMagnitude, y: 0,
                                       width: 160, height: 160)),
            ("over-cap", CGRect(x: 0, y: 0, width: 16_385, height: 160)),
        ]
        let presentations: [(UIDatePicker.Mode, UIDatePickerStyle)] = [
            (.time, .wheels), (.date, .inline),
        ]
        let routes: [(RenderBackend, RenderCompositor)] = [
            (.quartz, .layers), (.swift, .renderPass),
        ]
        var touchID = 100

        for (mode, style) in presentations {
            for mutation in ["bounds", "frame"] {
                for (name, rect) in hostile {
                    // A hostile frame origin changes only the view's center;
                    // the picker-owned presentation viewport is its bounds.
                    // Frame size mutations below exercise the same guarded
                    // path as direct hostile bounds sizes.
                    if mutation == "frame", name.hasSuffix("origin") { continue }
                    let window = UIWindow(frame: CGRect(x: 0, y: 0,
                                                        width: 320, height: 320))
                    let picker = UIDatePicker(frame: CGRect(x: 80, y: 80,
                                                            width: 160, height: 160))
                    picker.calendar = utcCalendar()
                    picker.timeZone = TimeZone(secondsFromGMT: 0)
                    picker.datePickerMode = mode
                    picker.preferredDatePickerStyle = style
                    var events = 0
                    picker.addTarget(for: .valueChanged) { _, _ in events += 1 }
                    window.addSubview(picker)
                    if mutation == "bounds" {
                        picker.bounds = rect
                    } else {
                        picker.frame = rect
                    }
                    picker.setNeedsLayout()
                    picker.layoutIfNeeded()

                    XCTAssertTrue(picker.subviews.allSatisfy { $0.frame == .zero },
                                  "\(style) \(mutation) \(name)")
                    window.sendTouch(.began, at: CGPoint(x: 160, y: 160),
                                     timestamp: 1, touchID: touchID)
                    window.sendTouch(.ended, at: CGPoint(x: 160, y: 160),
                                     timestamp: 1.01, touchID: touchID)
                    touchID += 1
                    XCTAssertEqual(events, 0,
                                   "\(style) \(mutation) \(name)")

                    for (backend, compositor) in routes {
                        OpenUIKitRuntime.renderBackend = backend
                        OpenUIKitRuntime.compositor = compositor
                        let bitmap = UIRenderer.render(picker, scale: 1)
                        XCTAssertGreaterThanOrEqual(bitmap.width, 0)
                        XCTAssertGreaterThanOrEqual(bitmap.height, 0)
                    }
                }
            }
        }
    }

    func testProgrammaticUpdatesDoNotEmitButInlineUserSelectionDoes() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        var events = 0
        picker.addTarget(for: .valueChanged) { _, _ in events += 1 }

        picker.date = date(2026, 8, 10, 14, 12, 9)
        picker.setDate(date(2026, 8, 11, 14, 12, 9), animated: true)
        XCTAssertEqual(events, 0)

        picker.selectInlineDay(12)
        XCTAssertEqual(events, 1)
        let components = utcCalendar().dateComponents([.year, .month, .day,
                                                        .hour, .minute, .second],
                                                       from: picker.date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.day, 12)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 12)
        XCTAssertEqual(components.second, 9)
    }

    func testWheelRowsTrackCalendarAndMinuteInterval() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 15
        picker.date = date(2024, 2, 29, 23, 45)

        XCTAssertFalse((picker as Any) is any UIPickerViewDataSource)
        XCTAssertFalse((picker as Any) is any UIPickerViewDelegate)
        XCTAssertEqual(picker.wheelNumberOfComponents(), 5)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 0), 12)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 1), 29)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 2), 9_999)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 3), 24)
        XCTAssertEqual(picker.wheelNumberOfRows(in: 4), 4)
        XCTAssertEqual(picker.wheelTitle(for: 1, component: 0), "Feb")
        XCTAssertEqual(picker.wheelTitle(for: 3, component: 4), "45")
    }

    func testWheelUserSelectionUpdatesDateAndEmitsOnce() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 15
        picker.date = date(2026, 8, 29, 10, 0, 27)
        var events = 0
        picker.addTarget(for: .valueChanged) { _, _ in events += 1 }

        picker.selectWheelRow(13, component: 0)
        picker.selectWheelRow(3, component: 1)
        let components = utcCalendar().dateComponents([.hour, .minute, .second],
                                                       from: picker.date)
        XCTAssertEqual(components.hour, 13)
        XCTAssertEqual(components.minute, 45)
        XCTAssertEqual(components.second, 27)
        XCTAssertEqual(events, 2)
    }

    func testWheelMonthAndYearChangesClampAnInvalidDay() {
        let picker = UIDatePicker()
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.roundsToMinuteInterval = false
        var events = 0
        picker.addTarget(for: .valueChanged) { _, _ in events += 1 }

        picker.date = date(2025, 1, 31, 12)
        picker.selectWheelRow(1, component: 0)
        var components = utcCalendar().dateComponents([.year, .month, .day],
                                                       from: picker.date)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 28)
        XCTAssertEqual(events, 1)

        picker.date = date(2024, 2, 29, 12)
        picker.selectWheelRow(2_024, component: 2)
        components = utcCalendar().dateComponents([.year, .month, .day],
                                                   from: picker.date)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 28)
        XCTAssertEqual(events, 2)
    }

    func testPublicWindowTouchRoutesExactlyOneValueChangedOrNoneWhenClamped() throws {
        TextTestSupport.configureResourceRoot()

        let inlineWindow = UIWindow(frame: CGRect(x: 0, y: 0,
                                                  width: 320, height: 320))
        let inline = UIDatePicker(frame: inlineWindow.bounds)
        inline.calendar = utcCalendar()
        inline.timeZone = TimeZone(secondsFromGMT: 0)
        inline.datePickerMode = .date
        inline.preferredDatePickerStyle = .inline
        inline.date = date(2026, 8, 10, 14, 12, 9)
        var inlineEvents = 0
        inline.addTarget(for: .valueChanged) { _, _ in inlineEvents += 1 }
        inlineWindow.addSubview(inline)
        inline.layoutIfNeeded()

        let day = try XCTUnwrap(inline.subviews.compactMap { $0 as? UIButton }
            .first { $0.currentTitle == "12" && $0.isEnabled })
        let point = CGPoint(x: day.frame.midX, y: day.frame.midY)
        XCTAssertTrue(inlineWindow.hitTest(point, with: nil) === day)
        inlineWindow.sendTouch(.began, at: point, timestamp: 1)
        inlineWindow.sendTouch(.ended, at: point, timestamp: 1.05)
        XCTAssertEqual(inlineEvents, 1)
        XCTAssertEqual(utcCalendar().component(.day, from: inline.date), 12)

        inline.date = date(2026, 8, 13)
        inline.setDate(date(2026, 8, 14), animated: true)
        XCTAssertEqual(inlineEvents, 1)

        let wheelWindow = UIWindow(frame: CGRect(x: 0, y: 0,
                                                 width: 160, height: 160))
        let wheel = UIDatePicker(frame: wheelWindow.bounds)
        wheel.calendar = utcCalendar()
        wheel.timeZone = TimeZone(secondsFromGMT: 0)
        wheel.datePickerMode = .time
        wheel.preferredDatePickerStyle = .wheels
        wheel.date = date(2026, 8, 29, 13, 45)
        var wheelEvents = 0
        wheel.addTarget(for: .valueChanged) { _, _ in wheelEvents += 1 }
        wheelWindow.addSubview(wheel)
        wheel.layoutIfNeeded()

        let lowerHour = CGPoint(x: 40, y: 130)
        XCTAssertTrue(wheelWindow.hitTest(lowerHour, with: nil) === wheel)
        wheelWindow.sendTouch(.began, at: lowerHour, timestamp: 2)
        wheelWindow.sendTouch(.ended, at: lowerHour, timestamp: 2.05)
        XCTAssertEqual(wheelEvents, 1)
        XCTAssertEqual(utcCalendar().component(.hour, from: wheel.date), 14)

        wheel.date = date(2026, 8, 29, 23, 45)
        wheelWindow.sendTouch(.began, at: lowerHour, timestamp: 3)
        wheelWindow.sendTouch(.ended, at: lowerHour, timestamp: 3.05)
        XCTAssertEqual(wheelEvents, 1)
        XCTAssertEqual(utcCalendar().component(.hour, from: wheel.date), 23)
    }

    func testPublicWheelTouchRoutingUsesTranslatedBoundsCoordinates() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0,
                                            width: 160, height: 160))
        let picker = UIDatePicker(frame: window.bounds)
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 15
        picker.date = date(2026, 8, 29, 10, 0)
        // The visible frame remains 0...160, but points delivered to the
        // picker are in this translated 100...260 / 200...360 bounds space.
        picker.bounds = CGRect(x: 100, y: 200, width: 160, height: 160)
        var events = 0
        picker.addTarget(for: .valueChanged) { _, _ in events += 1 }
        window.addSubview(picker)
        window.layoutIfNeeded()

        window.sendTouch(.began, at: CGPoint(x: 40, y: 130),
                         timestamp: 10, touchID: 10)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 130),
                         timestamp: 10.01, touchID: 10)
        var components = utcCalendar().dateComponents([.hour, .minute],
                                                       from: picker.date)
        XCTAssertEqual(components.hour, 11)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(events, 1)

        window.sendTouch(.began, at: CGPoint(x: 120, y: 130),
                         timestamp: 11, touchID: 11)
        window.sendTouch(.ended, at: CGPoint(x: 120, y: 130),
                         timestamp: 11.01, touchID: 11)
        components = utcCalendar().dateComponents([.hour, .minute],
                                                   from: picker.date)
        XCTAssertEqual(components.hour, 11)
        XCTAssertEqual(components.minute, 15)
        XCTAssertEqual(events, 2)
    }

    func testInlineAndWheelPresentationsRenderVisibleContent() {
        TextTestSupport.configureResourceRoot()

        let inline = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                                width: 320, height: 440))
        inline.calendar = utcCalendar()
        inline.timeZone = TimeZone(secondsFromGMT: 0)
        inline.datePickerMode = .date
        inline.preferredDatePickerStyle = .inline
        inline.date = date(2026, 8, 29)
        inline.layoutIfNeeded()
        let inlineBitmap = UIRenderer.renderPassRender(inline, scale: 1)
        XCTAssertGreaterThan(alphaPixelCount(inlineBitmap), 500)

        let wheel = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                               width: 320, height: 216))
        wheel.calendar = utcCalendar()
        wheel.timeZone = TimeZone(secondsFromGMT: 0)
        wheel.datePickerMode = .time
        wheel.preferredDatePickerStyle = .wheels
        wheel.date = date(2026, 8, 29, 13, 45)
        wheel.layoutIfNeeded()
        let wheelBitmap = UIRenderer.renderPassRender(wheel, scale: 1)
        XCTAssertGreaterThan(alphaPixelCount(wheelBitmap), 300)
    }

    func testReminderSizedPresentationsHaveStableHashesAcrossBothRenderers() {
        TextTestSupport.configureResourceRoot()
        let originalBackend = OpenUIKitRuntime.renderBackend
        let originalCompositor = OpenUIKitRuntime.compositor
        defer {
            OpenUIKitRuntime.renderBackend = originalBackend
            OpenUIKitRuntime.compositor = originalCompositor
        }
        let routes: [(RenderBackend, RenderCompositor, UInt64, UInt64)] = [
            (.quartz, .layers, 2_889_488_627_813_500_763,
             16_149_897_736_431_780_672),
            (.swift, .renderPass, 9_812_274_091_467_974_076,
             16_704_647_445_093_918_638),
        ]

        for (backend, compositor, expectedInline, expectedWheel) in routes {
            OpenUIKitRuntime.renderBackend = backend
            OpenUIKitRuntime.compositor = compositor

            let inline = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                                    width: 320, height: 320))
            inline.calendar = utcCalendar()
            inline.timeZone = TimeZone(secondsFromGMT: 0)
            inline.datePickerMode = .date
            inline.preferredDatePickerStyle = .inline
            inline.date = date(2026, 8, 29)
            inline.layoutIfNeeded()
            let inlineA = UIRenderer.render(inline, scale: 1)
            let inlineB = UIRenderer.render(inline, scale: 1)
            XCTAssertEqual(inlineA.pixels, inlineB.pixels)
            XCTAssertEqual(fnv1a(inlineA.pixels), expectedInline,
                           "inline backend=\(backend) compositor=\(compositor)")

            let wheel = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                                   width: 160, height: 160))
            wheel.calendar = utcCalendar()
            wheel.timeZone = TimeZone(secondsFromGMT: 0)
            wheel.datePickerMode = .time
            wheel.preferredDatePickerStyle = .wheels
            wheel.date = date(2026, 8, 29, 13, 45)
            wheel.layoutIfNeeded()
            let wheelA = UIRenderer.render(wheel, scale: 1)
            let wheelB = UIRenderer.render(wheel, scale: 1)
            XCTAssertEqual(wheelA.pixels, wheelB.pixels)
            XCTAssertEqual(fnv1a(wheelA.pixels), expectedWheel,
                           "wheel backend=\(backend) compositor=\(compositor)")
        }
    }

    private func alphaPixelCount(_ bitmap: Bitmap) -> Int {
        var count = 0
        for index in stride(from: 3, to: bitmap.pixels.count, by: 4)
        where bitmap.pixels[index] != 0 {
            count += 1
        }
        return count
    }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }
}

extension DatePickerTests {
    /// Forms t200, iPhone SE 2x, iOS 26.1: compact `.date` chrome.
    func testIOSCompactDateChromeMatchesFormsCapture() throws {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }

        let picker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 128, height: 34))
        picker.calendar = utcCalendar()
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.locale = Locale(identifier: "en_US_POSIX")
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.date = date(2026, 9, 4)
        picker.layoutIfNeeded()

        let label = try XCTUnwrap(
            picker.subviews.compactMap { $0 as? UILabel }
                .first { $0.text == "Sep 4, 2026" },
            "compact title should be DateFormatter.medium")
        XCTAssertEqual(label.font.pointSize, 17)
        XCTAssertEqual(label.layer.cornerRadius, 17)
        // Trailing-aligned capsule: title intrinsic 93.5 + 24 = 117.5.
        XCTAssertEqual(label.frame.height, 34)
        XCTAssertEqual(label.frame.maxX, 128, accuracy: 0.5)
        XCTAssertGreaterThan(label.frame.width, 100)
        XCTAssertLessThan(label.frame.minX, 16)
    }
}
