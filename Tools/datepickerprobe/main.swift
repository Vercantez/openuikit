import UIKit

private func f(_ value: Double) -> String {
    String(format: "%.3f", value)
}

private func seconds(_ value: Date) -> String {
    f(value.timeIntervalSinceReferenceDate)
}

private final class SurfaceSubclass: UIDatePicker {
    override var datePickerMode: Mode {
        get { super.datePickerMode }
        set { super.datePickerMode = newValue }
    }
    override var preferredDatePickerStyle: UIDatePickerStyle {
        get { super.preferredDatePickerStyle }
        set { super.preferredDatePickerStyle = newValue }
    }
    override var datePickerStyle: UIDatePickerStyle { super.datePickerStyle }
    override var roundsToMinuteInterval: Bool {
        get { super.roundsToMinuteInterval }
        set { super.roundsToMinuteInterval = newValue }
    }
    override var date: Date {
        get { super.date }
        set { super.date = newValue }
    }
    override func setDate(_ date: Date, animated: Bool) {
        super.setDate(date, animated: animated)
    }
}

private final class Delegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = application
        _ = launchOptions
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window

        var lines: [String] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)

        let surface = SurfaceSubclass()
        surface.calendar = nil
        lines.append("surface nil-calendar=\(surface.calendar != nil) protocols=\((surface as Any) is any UIPickerViewDataSource),\((surface as Any) is any UIPickerViewDelegate)")
        lines.append("surface raw=\(UIDatePicker.Mode.yearAndMonth.rawValue),\(UIDatePickerStyle.inline.rawValue) defaults=\(surface.datePickerMode.rawValue),\(surface.preferredDatePickerStyle.rawValue),\(surface.datePickerStyle.rawValue),\(surface.minuteInterval),\(f(surface.countDownDuration)),\(surface.roundsToMinuteInterval)")

        let rounded = UIDatePicker()
        rounded.calendar = calendar
        rounded.timeZone = TimeZone(secondsFromGMT: 0)
        rounded.roundsToMinuteInterval = false
        rounded.minuteInterval = 15
        rounded.date = base.addingTimeInterval(7 * 60 + 37)
        let exact = rounded.date
        rounded.roundsToMinuteInterval = true
        lines.append("round toggle=\(seconds(exact))->\(seconds(rounded.date))")
        rounded.roundsToMinuteInterval = false
        rounded.date = base.addingTimeInterval(22 * 60 + 11)
        rounded.roundsToMinuteInterval = true
        rounded.minuteInterval = 30
        lines.append("round interval-change=\(seconds(rounded.date))")

        let bounded = UIDatePicker()
        bounded.calendar = calendar
        bounded.timeZone = TimeZone(secondsFromGMT: 0)
        bounded.minuteInterval = 15
        let minimum = base.addingTimeInterval(7 * 60 + 17)
        bounded.minimumDate = minimum
        bounded.date = base
        lines.append("bounds nonaligned-min=\(seconds(bounded.date))")
        bounded.minimumDate = nil
        bounded.maximumDate = base.addingTimeInterval(22 * 60 + 13)
        bounded.date = base.addingTimeInterval(30 * 60)
        lines.append("bounds nonaligned-max=\(seconds(bounded.date))")

        for input: TimeInterval in [0, 59, 60, 61, 3_661, 86_399] {
            let picker = UIDatePicker()
            picker.countDownDuration = input
            let before = picker.countDownDuration
            picker.datePickerMode = .countDownTimer
            lines.append("countdown outside \(Int(input))=\(f(before))->\(f(picker.countDownDuration))")
        }

        let countdown = UIDatePicker()
        countdown.datePickerMode = .countDownTimer
        for input: TimeInterval in [0, 59, 60, 61, 3_661, 86_399, 86_400] {
            countdown.countDownDuration = input
            lines.append("countdown inside \(Int(input))=\(f(countdown.countDownDuration))")
        }

        func countdownPicker() -> UIDatePicker {
            let picker = UIDatePicker()
            picker.calendar = calendar
            picker.timeZone = TimeZone(secondsFromGMT: 0)
            picker.roundsToMinuteInterval = false
            picker.date = base
            picker.datePickerMode = .countDownTimer
            return picker
        }

        let entry = UIDatePicker()
        entry.calendar = calendar
        entry.timeZone = TimeZone(secondsFromGMT: 0)
        entry.roundsToMinuteInterval = false
        entry.date = base
        let beforeEntry = entry.date
        let beforeEntryNow = Date()
        entry.datePickerMode = .countDownTimer
        let afterEntryNow = Date()
        let entryIsCurrentDay = entry.date == calendar.startOfDay(for: beforeEntryNow)
            || entry.date == calendar.startOfDay(for: afterEntryNow)
        lines.append("countdown entry-current-day=\(entryIsCurrentDay) changed=\(entry.date != beforeEntry)")

        let property = countdownPicker()
        property.date = base.addingTimeInterval(5_400)
        lines.append("countdown property=\(seconds(property.date))")

        let methodFalse = countdownPicker()
        methodFalse.setDate(base.addingTimeInterval(7_200), animated: false)
        lines.append("countdown method-false=\(seconds(methodFalse.date))")

        let methodTrue = countdownPicker()
        methodTrue.setDate(base.addingTimeInterval(7_800), animated: true)
        lines.append("countdown method-true=\(seconds(methodTrue.date))")

        let range = countdownPicker()
        range.minimumDate = base.addingTimeInterval(6_000)
        let afterMinimum = range.date
        range.maximumDate = base.addingTimeInterval(7_200)
        range.date = base.addingTimeInterval(9_000)
        lines.append("countdown bounds-valid=\(afterMinimum >= base.addingTimeInterval(6_000)) high=\(seconds(range.date))")
        range.datePickerMode = .dateAndTime
        lines.append("countdown back=\(seconds(range.date))")

        var eventCount = 0
        let events = UIDatePicker()
        events.addAction(UIAction { _ in eventCount += 1 }, for: .valueChanged)
        events.date = base
        events.setDate(base.addingTimeInterval(60), animated: true)
        lines.append("programmatic events=\(eventCount)")

        let beforeDefault = Date()
        let defaults = UIDatePicker()
        let afterDefault = Date()
        let defaultSeconds = defaults.date.timeIntervalSinceReferenceDate
        let deltaBefore = defaults.date.timeIntervalSince(beforeDefault)
        let deltaAfter = defaults.date.timeIntervalSince(afterDefault)
        let inWindow = abs(deltaBefore) < 1 && abs(deltaAfter) < 1
        let fractional = defaultSeconds
            .truncatingRemainder(dividingBy: 60) != 0
        lines.append("default current=\(inWindow) not-minute-floored=\(fractional)")

        let output = lines.joined(separator: "\n") + "\n"
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        try! output.write(to: documents.appendingPathComponent("datepickerprobe.txt"),
                          atomically: true, encoding: .utf8)
        print(output, terminator: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
        return true
    }
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(Delegate.self))
