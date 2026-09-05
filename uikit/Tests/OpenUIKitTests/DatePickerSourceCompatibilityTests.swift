// Literal downstream-module gate: this file intentionally imports the public
// `UIKit` shim, never `@testable OpenUIKit`.

import XCTest
import UIKit
import Foundation

#if !os(Linux)
@MainActor
#endif
private class DatePickerOverrideProbe: UIDatePicker {
    override var datePickerMode: Mode {
        get { super.datePickerMode }
        set { super.datePickerMode = newValue }
    }

    override var locale: Locale? {
        get { super.locale }
        set { super.locale = newValue }
    }

    override var calendar: Calendar! {
        get { super.calendar }
        set { super.calendar = newValue }
    }

    override var timeZone: TimeZone? {
        get { super.timeZone }
        set { super.timeZone = newValue }
    }

    override var date: Date {
        get { super.date }
        set { super.date = newValue }
    }

    override var minimumDate: Date? {
        get { super.minimumDate }
        set { super.minimumDate = newValue }
    }

    override var maximumDate: Date? {
        get { super.maximumDate }
        set { super.maximumDate = newValue }
    }

    override var countDownDuration: TimeInterval {
        get { super.countDownDuration }
        set { super.countDownDuration = newValue }
    }

    override var minuteInterval: Int {
        get { super.minuteInterval }
        set { super.minuteInterval = newValue }
    }

    override var preferredDatePickerStyle: UIDatePickerStyle {
        get { super.preferredDatePickerStyle }
        set { super.preferredDatePickerStyle = newValue }
    }

    override var datePickerStyle: UIDatePickerStyle {
        super.datePickerStyle
    }

    override var roundsToMinuteInterval: Bool {
        get { super.roundsToMinuteInterval }
        set { super.roundsToMinuteInterval = newValue }
    }

    override func setDate(_ date: Date, animated: Bool) {
        super.setDate(date, animated: animated)
    }
}

#if !os(Linux)
@MainActor
#endif
private class DatePickerFrameProbe: UIDatePicker {
    static var frameInitializations = 0

    override init(frame: CGRect) {
        Self.frameInitializations += 1
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// Native UIKit inherits `init()` when a subclass supplies both designated
/// initializer paths. This catches an accidental `required` frame initializer
/// or an inaccessible convenience initializer in the portable surface.
#if !os(Linux)
@MainActor
#endif
private final class DatePickerInheritedInitProbe: DatePickerFrameProbe {}

#if !os(Linux)
@MainActor
#endif
final class DatePickerSourceCompatibilityTests: XCTestCase {
    private static let availabilityCounts = [
        "@available(iOS 2.0, *)": 1,
        "@available(iOS 13.4, *)": 3,
        "@available(iOS 14.0, *)": 1,
        "@available(iOS 15.0, *)": 1,
        "@available(iOS 17.4, *)": 1,
    ]

    private static let availableDeclarations = [
        "@available(iOS 13.4, *) public enum UIDatePickerStyle",
        "@available(iOS 14.0, *) case inline = 3",
        "@available(iOS 2.0, *) open class UIDatePicker: UIControl",
        "@available(iOS 17.4, *) case yearAndMonth = 4",
        "@available(iOS 13.4, *) open var preferredDatePickerStyle",
        "@available(iOS 13.4, *) open var datePickerStyle",
        "@available(iOS 15.0, *) open var roundsToMinuteInterval",
    ]

    private static func availabilityViolations(in source: String) -> [String] {
        // Reuse the determinism gate's lexical comment/string stripper so an
        // annotation merely discussed in docs or embedded in a literal cannot
        // satisfy this source-level symbol-graph contract.
        let executable = FoundationCoexistenceTests.sourceWithoutComments(
            source, preservingStringContents: false
        )
        let compact = executable.replacingOccurrences(
            of: #"\s+"#, with: " ", options: .regularExpression
        )
        var violations: [String] = []
        for (spelling, expected) in availabilityCounts {
            let actual = executable.components(separatedBy: spelling).count - 1
            if actual != expected {
                violations.append("\(spelling): \(actual) != \(expected)")
            }
        }
        for declaration in availableDeclarations where !compact.contains(declaration) {
            violations.append("missing \(declaration)")
        }
        return violations
    }

    func testGranularAvailabilityMatchesUIKit26SymbolGraph() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let sourceURL = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/OpenUIKit/UIDatePicker.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        // Exact introductions from UIKit 26.1's shipped symbol graph. Counts
        // make a stale duplicate annotation fail rather than merely finding
        // one matching fragment somewhere in comments or dead source.
        XCTAssertEqual(Self.availabilityViolations(in: source), [])

        let roundsDeclaration = """
        @available(iOS 15.0, *)
            open var roundsToMinuteInterval
        """
        var tampered = source
        let range = try XCTUnwrap(tampered.range(of: roundsDeclaration))
        tampered.replaceSubrange(range, with: "// removed rounds availability")
        tampered += "\n// \(roundsDeclaration)\n"
        tampered += "\nprivate let decoy = \"@available(iOS 15.0, *) open var roundsToMinuteInterval\"\n"
        let tamperedViolations = Self.availabilityViolations(in: tampered)
        XCTAssertTrue(tamperedViolations.contains { $0.contains("iOS 15.0") })
        XCTAssertTrue(tamperedViolations.contains {
            $0.contains("roundsToMinuteInterval")
        })
    }

    func testPublicMembersAreOverridableThroughLiteralUIKit() {
        let picker = DatePickerOverrideProbe()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.roundsToMinuteInterval = false
        picker.setDate(Date(timeIntervalSinceReferenceDate: 100), animated: true)

        XCTAssertEqual(picker.datePickerMode, .date)
        XCTAssertEqual(picker.datePickerStyle, .inline)
        XCTAssertEqual(picker.date.timeIntervalSinceReferenceDate, 100)
    }

    func testFrameCoderAndInheritedZeroInitializerTopology() {
        DatePickerFrameProbe.frameInitializations = 0
        let inherited = DatePickerInheritedInitProbe()
        XCTAssertTrue(type(of: inherited) == DatePickerInheritedInitProbe.self)
        XCTAssertEqual(DatePickerFrameProbe.frameInitializations, 1)

        let framed = DatePickerInheritedInitProbe(
            frame: CGRect(x: 1, y: 2, width: 160, height: 160)
        )
        XCTAssertTrue(type(of: framed) == DatePickerInheritedInitProbe.self)
        XCTAssertEqual(framed.frame,
                       CGRect(x: 1, y: 2, width: 160, height: 160))
        XCTAssertEqual(DatePickerFrameProbe.frameInitializations, 2)
    }

    func testRawInitializersFailClosed() {
        XCTAssertNil(UIDatePicker.Mode(rawValue: -1))
        XCTAssertNil(UIDatePicker.Mode(rawValue: 5))
        XCTAssertNil(UIDatePickerStyle(rawValue: -1))
        XCTAssertNil(UIDatePickerStyle(rawValue: 4))
    }
}
