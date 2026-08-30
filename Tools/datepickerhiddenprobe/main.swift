// Literal-UIKit ARM64 Mach-O runtime closure for the bounded UIDatePicker
// slice. This source intentionally has no app-side import rewrite and must be
// compiled with the Foundation umbrella absent and FoundationEssentials
// supplied by the pinned support toolchain.
import UIKit

#if canImport(Foundation)
#error("datepickerhiddenprobe must compile with Foundation hidden")
#endif

#if !canImport(FoundationEssentials)
#error("datepickerhiddenprobe requires the pinned FoundationEssentials module")
#endif

@main
@MainActor
struct DatePickerHiddenProbe {
    static func main() {
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        OpenUIKitRuntime.resourceRoot = "/uikit/Sources/OpenUIKit/Resources"
        OpenUIKitRuntime.imageScreenScale = 2

        Timer._reset()
        defer { Timer._reset() }
        let clockWindow = UIWindow(frame: .zero)
        clockWindow.tick(timestamp: 800_010_123.75)
        precondition(Timer.currentTime == 800_010_123.75)

        let defaults = UIDatePicker()
        defaults.calendar = nil
        let requestedPOSIX = Locale(identifier: "en_US_POSIX")
        precondition(defaults.date.timeIntervalSinceReferenceDate == 800_010_123.75)
        precondition(defaults.calendar.identifier == .gregorian)
        // The pinned FoundationEssentials-only build intentionally uses its
        // unlocalized Locale provider: every requested identifier is exposed
        // as en_001 until FoundationInternationalization is staged. Prove the
        // substrate boundary directly rather than misreporting it as a picker
        // snapshot failure or silently accepting an arbitrary locale.
        precondition(requestedPOSIX.identifier == "en_001")
        precondition(defaults.calendar.locale?.identifier == "en_001")
        precondition(defaults.calendar.timeZone.secondsFromGMT() == 0)
        precondition(defaults.calendar.firstWeekday == 1)
        precondition(defaults.calendar.minimumDaysInFirstWeek == 1)
        precondition(defaults.locale == nil && defaults.timeZone == nil)

        let calendar = utcCalendar()
        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)

        var boundsEvents = 0
        let bounded = UIDatePicker()
        bounded.calendar = calendar
        bounded.timeZone = TimeZone(secondsFromGMT: 0)
        bounded.minuteInterval = 15
        bounded.addTarget(for: .valueChanged) { _, _ in boundsEvents += 1 }
        bounded.minimumDate = base.addingTimeInterval(437)
        bounded.date = base
        let boundedLow = bounded.date.timeIntervalSinceReferenceDate
        precondition(boundedLow == 800_000_437)
        bounded.minimumDate = nil
        bounded.maximumDate = base.addingTimeInterval(1_333)
        bounded.setDate(base.addingTimeInterval(1_800), animated: true)
        let boundedHigh = bounded.date.timeIntervalSinceReferenceDate
        precondition(boundedHigh == 800_001_020)
        precondition(boundsEvents == 0)

        let rounding = UIDatePicker()
        rounding.calendar = calendar
        rounding.timeZone = TimeZone(secondsFromGMT: 0)
        rounding.roundsToMinuteInterval = false
        rounding.minuteInterval = 15
        rounding.date = base.addingTimeInterval(457)
        let unrounded = rounding.date.timeIntervalSinceReferenceDate
        rounding.roundsToMinuteInterval = true
        let rounded = rounding.date.timeIntervalSinceReferenceDate
        precondition(unrounded == 800_000_457)
        precondition(rounded == 800_000_157)

        var countdownEvents = 0
        let countdown = UIDatePicker()
        countdown.addTarget(for: .valueChanged) { _, _ in countdownEvents += 1 }
        countdown.countDownDuration = 3_661
        precondition(countdown.countDownDuration == 0)
        countdown.calendar = calendar
        countdown.timeZone = TimeZone(secondsFromGMT: 0)
        countdown.roundsToMinuteInterval = false
        countdown.date = base
        countdown.datePickerMode = .countDownTimer
        let entryDate = countdown.date.timeIntervalSinceReferenceDate
        precondition(entryDate == 799_977_600)
        precondition(countdown.countDownDuration == 60)
        countdown.countDownDuration = 3_661
        precondition(countdown.countDownDuration == 3_660)
        countdown.date = base.addingTimeInterval(5_400)
        let propertyDate = countdown.date.timeIntervalSinceReferenceDate
        countdown.setDate(base.addingTimeInterval(7_200), animated: false)
        let methodFalseDate = countdown.date.timeIntervalSinceReferenceDate
        countdown.setDate(base.addingTimeInterval(7_800), animated: true)
        let methodTrueDate = countdown.date.timeIntervalSinceReferenceDate
        precondition(propertyDate == 800_005_400)
        precondition(methodFalseDate == 800_007_200)
        precondition(methodTrueDate == 800_007_800)
        precondition(countdownEvents == 0)

        var touchEvents = 0
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        let touched = UIDatePicker(frame: window.bounds)
        touched.calendar = calendar
        touched.timeZone = TimeZone(secondsFromGMT: 0)
        touched.datePickerMode = .time
        touched.preferredDatePickerStyle = .wheels
        touched.minuteInterval = 15
        touched.date = date(2026, 8, 29, 10, 0, calendar: calendar)
        touched.bounds = CGRect(x: 100, y: 200, width: 160, height: 160)
        touched.addTarget(for: .valueChanged) { _, _ in touchEvents += 1 }
        window.addSubview(touched)
        window.layoutIfNeeded()

        window.sendTouch(.began, at: CGPoint(x: 40, y: 130),
                         timestamp: 800_010_124, touchID: 10)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 130),
                         timestamp: 800_010_124.01, touchID: 10)
        var touchedComponents = calendar.dateComponents([.hour, .minute],
                                                        from: touched.date)
        precondition(touchedComponents.hour == 11)
        precondition(touchedComponents.minute == 0)
        precondition(touchEvents == 1)

        window.sendTouch(.began, at: CGPoint(x: 120, y: 130),
                         timestamp: 800_010_125, touchID: 11)
        window.sendTouch(.ended, at: CGPoint(x: 120, y: 130),
                         timestamp: 800_010_125.01, touchID: 11)
        touchedComponents = calendar.dateComponents([.hour, .minute],
                                                    from: touched.date)
        precondition(touchedComponents.hour == 11)
        precondition(touchedComponents.minute == 15)
        precondition(touchEvents == 2)

        let inline = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                                width: 320, height: 320))
        inline.calendar = calendar
        inline.timeZone = TimeZone(secondsFromGMT: 0)
        inline.datePickerMode = .date
        inline.preferredDatePickerStyle = .inline
        inline.date = date(2026, 8, 29, calendar: calendar)
        inline.layoutIfNeeded()
        let inlineA = UIRenderer.render(inline, scale: 1)
        let inlineB = UIRenderer.render(inline, scale: 1)
        precondition(inlineA.width == 320 && inlineA.height == 320)
        precondition(inlineA.pixels == inlineB.pixels)
        let inlineHash = fnv1a(inlineA.pixels)

        let wheel = UIDatePicker(frame: CGRect(x: 0, y: 0,
                                               width: 160, height: 160))
        wheel.calendar = calendar
        wheel.timeZone = TimeZone(secondsFromGMT: 0)
        wheel.datePickerMode = .time
        wheel.preferredDatePickerStyle = .wheels
        wheel.date = date(2026, 8, 29, 13, 45, calendar: calendar)
        wheel.layoutIfNeeded()
        let wheelA = UIRenderer.render(wheel, scale: 1)
        let wheelB = UIRenderer.render(wheel, scale: 1)
        precondition(wheelA.width == 160 && wheelA.height == 160)
        precondition(wheelA.pixels == wheelB.pixels)
        let wheelHash = fnv1a(wheelA.pixels)
        // These are the pinned ARM64 Mach-O/FoundationEssentials-only pixel
        // products. The macOS full-Foundation XCTest gate keeps its separate
        // hashes; the port does not rewrite either provider to force cross-
        // platform pixel equality.
        precondition(
            inlineHash == 2_796_023_057_706_954_829
                && wheelHash == 4_543_181_309_005_258_709,
            "render hashes inline=\(inlineHash) wheel=\(wheelHash)"
        )

        print("DATEPICKER_CLOCK current=800010123.75 default=800010123.75 "
              + "calendar=gregorian locale=en_001 requested=en_US_POSIX timezone=0 "
              + "firstWeekday=1 minimumDays=1")
        print("DATEPICKER_BOUNDS low=800000437 high=800001020 events=0")
        print("DATEPICKER_ROUNDING toggle=800000457->800000157")
        print("DATEPICKER_COUNTDOWN outside=0 entering=60 hostDay=799977600 "
              + "inside=3660 property=800005400 methodFalse=800007200 "
              + "methodTrue=800007800 events=0")
        print("DATEPICKER_TOUCH programmatic=0 hour=11 minute=15 events=2")
        print("DATEPICKER_RENDER inline=2796023057706954829 "
              + "wheel=4543181309005258709 repeat=identical")
        print("DATEPICKER_FOUNDATION_HIDDEN_RUNTIME_OK")
    }

    private static func utcCalendar() -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "en_US_POSIX")
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 1
        value.minimumDaysInFirstWeek = 1
        return value
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int,
                             _ hour: Int = 0, _ minute: Int = 0,
                             calendar: Calendar) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let value = calendar.date(from: components) else {
            fatalError("failed to create deterministic probe date")
        }
        return value
    }

    private static func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }
}
