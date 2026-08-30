// M15: `import Foundation` alongside `import OpenUIKit`.
//
// This file is the deliverable, not a description of it. It imports Foundation
// the way a real app's file does, uses UIKit and Foundation names side by side
// with NO disambiguating typealias anywhere, and asserts that the geometry the
// two modules exchange really is ONE type. Before M15 every test file in this
// directory carried four to six `private typealias CGRect = OpenUIKit.CGRect`
// lines; 151 of them are gone, and this file would not compile without the
// change (docs/APP_COMPAT.md "Foundation coexistence").
//
// The second half is the determinism guard: the library may import Foundation,
// but the render and layout path still must not read a wall clock, a locale or
// a random source, because byte-identical Linux renders depend on it
// (docs/PORTABILITY.md). That is enforced here by scanning the sources.

import XCTest
import Foundation
@testable import OpenUIKit

final class FoundationCoexistenceTests: XCTestCase {

    // MARK: - One type, not two

    /// The compile-time claim: `CGRect` names the SAME declaration whether you
    /// reached it through Foundation or through OpenUIKit.
    func testGeometryTypesAreFoundationsOwn() {
        XCTAssertTrue(OpenUIKit.CGRect.self == Foundation.CGRect.self)
        XCTAssertTrue(OpenUIKit.CGPoint.self == Foundation.CGPoint.self)
        XCTAssertTrue(OpenUIKit.CGSize.self == Foundation.CGSize.self)
        XCTAssertTrue(OpenUIKit.CGFloat.self == Foundation.CGFloat.self)
        XCTAssertTrue(OpenUIKit.IndexPath.self == Foundation.IndexPath.self)
        XCTAssertTrue(OpenUIKit.NSRange.self == Foundation.NSRange.self)
    }

    /// A rect built by Foundation-facing code goes straight into a UIView, and
    /// the rect that comes back out is usable as a Foundation value. This is
    /// the thing that used to be impossible.
    ///
    /// `@MainActor` on this one method — not on the class — is the honest
    /// spelling after M15 merged Foundation coexistence with actor isolation:
    /// `CGRect`, `NSValue` and `NSCoder` are nonisolated values, `UIView` is
    /// main-actor-isolated exactly as in the iOS SDK, so only the test that
    /// touches a view needs the annotation. App source reads the same way.
    @MainActor
    func testAFoundationRectRoundTripsThroughAView() {
        let coder = NSCoder.self          // the corpus's #1 collision (344 files)
        XCTAssertNotNil(coder)

        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let view = UIView(frame: frame)
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(view.frame.insetBy(dx: 5, dy: 5),
                       CGRect(x: 15, y: 25, width: 90, height: 40))
        XCTAssertEqual(view.bounds.integral.width, 100)

        // NSValue is Foundation's; boxing a UIKit-produced rect must work.
        let boxed = NSValue(bytes: &view.frame.origin, objCType: "{CGPoint=dd}")
        XCTAssertNotNil(boxed)
    }

    /// `applying(_:)` is the one geometry member Foundation does not have, so
    /// OpenCoreGraphics adds it. Same numbers as before the switch.
    ///
    /// The `OpenUIKit.` qualification is the documented RESIDUE: Linux
    /// Foundation has no CGAffineTransform, so OpenUIKit keeps its own (one
    /// implementation for both platforms is what makes the rotation matrix
    /// byte-identical). On Darwin — the oracle platform only — Foundation
    /// re-exports CoreGraphics' and the two names collide. See
    /// Sources/OpenUIKit/FoundationTypes.swift.
    func testApplyingIsStillOurs() {
        let t = OpenUIKit.CGAffineTransform(translationX: 5, y: 7)
        XCTAssertEqual(CGPoint(x: 1, y: 2).applying(t), CGPoint(x: 6, y: 9))
        XCTAssertEqual(CGRect(x: 0, y: 0, width: 2, height: 2).applying(t),
                       CGRect(x: 5, y: 7, width: 2, height: 2))
        XCTAssertEqual(CGRect.null.applying(t), CGRect.null)
    }

    // MARK: - IndexPath: Foundation's storage, UIKit's spelling

    func testIndexPathIsFoundationsWithUIKitConveniences() {
        let ip = IndexPath(row: 3, section: 1)
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 3)
        XCTAssertEqual(ip.section, 1)
        XCTAssertEqual(ip.row, 3)
        XCTAssertEqual(ip.item, 3, "UIKit spells the same slot `item` for collection views")
        XCTAssertEqual(IndexPath(item: 3, section: 1), ip)
        XCTAssertLessThan(IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1))
        XCTAssertLessThan(IndexPath(row: 9, section: 0), IndexPath(row: 0, section: 1))
    }

    /// A UIKit data source keyed by index path and a Foundation collection of
    /// index paths are now interchangeable.
    func testIndexPathCrossesTheModuleBoundary() {
        var byPath: [IndexPath: String] = [:]
        byPath[IndexPath(row: 0, section: 0)] = "a"
        let fromFoundation = IndexPath(indexes: [0, 0])
        XCTAssertEqual(byPath[fromFoundation], "a")
    }

    // MARK: - Determinism guard
    //
    // The library is allowed to import Foundation now. It is NOT allowed to
    // read a wall clock, a locale or a random source: openrender must produce
    // the same bytes on macOS and on Linux, from scripted timestamps only.

    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // OpenUIKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repo root

    /// Symbols that would put non-determinism into the render or layout path.
    /// `Timer`'s own clock is `UIWindow.tick(timestamp:)`, which is why
    /// OpenUIKit keeps its own Timer instead of Foundation's (Timer.swift).
    private static let banned = [
        "NSDate", "DateFormatter",
        "gettimeofday", "clock_gettime", "mach_absolute_time",
        "CFAbsoluteTimeGetCurrent", "arc4random", "UUID(",
    ]

    private static let ambientPatterns = [
        "Date.now", "Date.init(timeIntervalSinceNow:",
        "Calendar.current", "Calendar.autoupdatingCurrent",
        "Locale.current", "Locale.autoupdatingCurrent",
        "TimeZone.current", "TimeZone.autoupdatingCurrent",
        "DispatchTime.now", "ProcessInfo.processInfo.systemUptime",
    ]

    /// The only Foundation constructors admitted in the render/layout source
    /// are the explicit deterministic environment in UIDatePicker. Counts are
    /// exact: deleting, duplicating, or changing any call fails the scan.
    /// A control-delimited token cannot occur in compilable Swift source. It
    /// therefore cannot be forged by naming a variable after the scanner's
    /// replacement for a deterministic string literal.
    private static let stringLiteralSentinel = "\u{1F}STRING_LITERAL\u{1F}"

    private static let datePickerConstructorAllowlist: [String: Int] = [
        "Date.init(timeIntervalSinceReferenceDate:hostTime)": 2,
        "Calendar(identifier:.gregorian)": 1,
        "Calendar(identifier:input.identifier)": 1,
        "Locale(identifier:\(stringLiteralSentinel))": 2,
        "Locale(identifier:input.identifier)": 1,
        "TimeZone(secondsFromGMT:0)!": 2,
        "TimeZone(identifier:input.identifier)": 1,
    ]

    /// The content-preserving spelling of the same allowlist is used for the
    /// conservative constructor scan. The code-only lexer above proves that
    /// a string/comment cannot satisfy an exact count; this second view makes
    /// executable string interpolation visible and rejects constructor-shaped
    /// decoys rather than trying to interpret all of Swift's string grammar.
    private static let datePickerPreservedConstructorAllowlist: [String: Int] = [
        "Date.init(timeIntervalSinceReferenceDate:hostTime)": 2,
        "Calendar(identifier:.gregorian)": 1,
        "Calendar(identifier:input.identifier)": 1,
        "Locale(identifier:\"en_US_POSIX\")": 2,
        "Locale(identifier:input.identifier)": 1,
        "TimeZone(secondsFromGMT:0)!": 2,
        "TimeZone(identifier:input.identifier)": 1,
    ]

    static func sourceWithoutComments(
        _ source: String,
        preservingStringContents: Bool = true
    ) -> String {
        // This deliberately small lexer distinguishes Swift string delimiters
        // from comments. A regex makes `"/*"` or `"//"` capable of erasing
        // executable source that follows it, which would turn the determinism
        // check itself into an evasion surface. Nested block comments and raw
        // or multiline strings are handled because framework source uses all
        // of those forms.
        let characters = Array(source)
        var output: [Character] = []
        var index = 0
        var blockDepth = 0
        var inLineComment = false
        var stringHashes: Int?
        var multilineString = false

        func matches(_ spelling: [Character], at offset: Int) -> Bool {
            guard offset >= 0, offset + spelling.count <= characters.count else {
                return false
            }
            for item in spelling.indices
                where characters[offset + item] != spelling[item] {
                return false
            }
            return true
        }

        func closingHashesMatch(after offset: Int, count: Int) -> Bool {
            guard offset + count <= characters.count else { return false }
            for item in 0..<count where characters[offset + item] != "#" {
                return false
            }
            return true
        }

        while index < characters.count {
            if inLineComment {
                if characters[index] == "\n" {
                    inLineComment = false
                    output.append("\n")
                }
                index += 1
                continue
            }

            if blockDepth > 0 {
                if matches(["/", "*"], at: index) {
                    blockDepth += 1
                    index += 2
                } else if matches(["*", "/"], at: index) {
                    blockDepth -= 1
                    index += 2
                } else {
                    index += 1
                }
                continue
            }

            if let hashes = stringHashes {
                // Ordinary string escapes consume the following character;
                // raw strings close only at a quote plus their exact hashes.
                if hashes == 0, characters[index] == "\\" {
                    if preservingStringContents {
                        output.append(characters[index])
                    }
                    index += 1
                    if index < characters.count {
                        if preservingStringContents {
                            output.append(characters[index])
                        }
                        index += 1
                    }
                    continue
                }
                let quotes = multilineString ? [Character]("\"\"\"") : ["\""]
                if matches(quotes, at: index),
                   closingHashesMatch(after: index + quotes.count,
                                      count: hashes) {
                    if preservingStringContents {
                        output.append(contentsOf: quotes)
                        output.append(contentsOf: repeatElement("#", count: hashes))
                    }
                    index += quotes.count + hashes
                    stringHashes = nil
                    multilineString = false
                    continue
                }
                if preservingStringContents {
                    output.append(characters[index])
                }
                index += 1
                continue
            }

            if matches(["/", "/"], at: index) {
                inLineComment = true
                index += 2
                continue
            }
            if matches(["/", "*"], at: index) {
                blockDepth = 1
                index += 2
                continue
            }

            var hashCount = 0
            var quoteOffset = index
            while quoteOffset < characters.count,
                  characters[quoteOffset] == "#" {
                hashCount += 1
                quoteOffset += 1
            }
            if quoteOffset < characters.count,
               characters[quoteOffset] == "\"" {
                let triple = matches(["\"", "\"", "\""], at: quoteOffset)
                let delimiterEnd = quoteOffset + (triple ? 3 : 1)
                if preservingStringContents {
                    output.append(contentsOf: characters[index..<delimiterEnd])
                } else {
                    // Keep surrounding executable tokens separate without
                    // retaining a constructor-shaped decoy from the literal.
                    output.append(contentsOf: stringLiteralSentinel)
                }
                index = delimiterEnd
                stringHashes = hashCount
                multilineString = triple
                continue
            }

            output.append(characters[index])
            index += 1
        }
        return String(output)
    }

    private static func compactExecutableSource(_ source: String) -> String {
        sourceWithoutComments(source).filter { !$0.isWhitespace }
    }

    private static func compactExecutableTokens(_ source: String) -> String {
        sourceWithoutComments(source, preservingStringContents: false)
            .filter { !$0.isWhitespace }
    }

    private static func removingApprovedConstructors(
        _ source: String,
        relativePath: String,
        allowlist: [String: Int]
    ) -> String {
        guard relativePath == "UIDatePicker.swift" else { return source }
        var remainder = source
        for (spelling, maximumCount) in allowlist {
            for _ in 0..<maximumCount {
                guard let range = remainder.range(of: spelling) else { break }
                remainder.removeSubrange(range)
            }
        }
        return remainder
    }

    private static func occurrenceCount(of spelling: String,
                                        in source: String) -> Int {
        guard !spelling.isEmpty else { return 0 }
        var count = 0
        var start = source.startIndex
        while let range = source.range(of: spelling,
                                       range: start..<source.endIndex) {
            count += 1
            start = range.upperBound
        }
        return count
    }

    /// Finds a constructor spelling without mistaking ordinary APIs such as
    /// `setDate(` or `layoutInlineCalendar(` for Foundation constructors.
    private static func containsStandaloneCall(_ type: String,
                                               in text: String) -> Bool {
        var searchStart = text.startIndex
        let needle = "\(type)("
        while let range = text.range(of: needle,
                                     range: searchStart..<text.endIndex) {
            if range.lowerBound == text.startIndex { return true }
            let prior = text[text.index(before: range.lowerBound)]
            if !(prior.isLetter || prior.isNumber || prior == "_") { return true }
            searchStart = range.upperBound
        }
        return false
    }

    private static func containsStandaloneTypeMember(
        _ type: String,
        member: String,
        in text: String
    ) -> Bool {
        var searchStart = text.startIndex
        let needle = "\(type).\(member)"
        while let range = text.range(of: needle,
                                     range: searchStart..<text.endIndex) {
            let hasIdentifierPrefix: Bool
            if range.lowerBound == text.startIndex {
                hasIdentifierPrefix = false
            } else {
                let prior = text[text.index(before: range.lowerBound)]
                hasIdentifierPrefix = prior.isLetter || prior.isNumber || prior == "_"
            }
            let hasIdentifierSuffix: Bool
            if range.upperBound == text.endIndex {
                hasIdentifierSuffix = false
            } else {
                let next = text[range.upperBound]
                hasIdentifierSuffix = next.isLetter || next.isNumber || next == "_"
            }
            if !hasIdentifierPrefix, !hasIdentifierSuffix { return true }
            searchStart = range.upperBound
        }
        return false
    }

    private static func deterministicViolations(in source: String,
                                                relativePath: String) -> [String] {
        let compact = compactExecutableSource(source)
        let executable = compactExecutableTokens(source)
        // UIDatePicker gets a deliberately conservative second pass over
        // string contents. This catches executable interpolation that the
        // code-only exact-count view replaces with a sentinel. Other modules
        // retain the established code-only policy.
        let unapproved = relativePath == "UIDatePicker.swift"
            ? removingApprovedConstructors(
                compact,
                relativePath: relativePath,
                allowlist: datePickerPreservedConstructorAllowlist
            )
            : executable
        var violations = ambientPatterns.filter { compact.contains($0) }
        let aliasPattern = #"typealias\s+`?[A-Za-z_][A-Za-z0-9_]*`?\s*=\s*(?:\(\s*)*(?:(?:Foundation|FoundationEssentials|FoundationInternationalization)\s*\.\s*)?(?:Date|Calendar|Locale|TimeZone)\b(?:\s*\))*"#
        if sourceWithoutComments(source).range(
            of: aliasPattern, options: .regularExpression
        ) != nil {
            violations.append("Foundation clock/environment typealias")
        }
        if relativePath == "UIDatePicker.swift" {
            for (spelling, expectedCount) in datePickerConstructorAllowlist {
                let actualCount = occurrenceCount(of: spelling, in: executable)
                if actualCount != expectedCount {
                    violations.append(
                        "\(spelling): expected \(expectedCount), found \(actualCount)"
                    )
                }
            }
        }
        for type in ["Date", "Calendar", "Locale", "TimeZone"] {
            if containsStandaloneCall(type, in: unapproved) {
                violations.append("\(type)(")
            }
            if containsStandaloneTypeMember(type, member: "self", in: unapproved) {
                violations.append("\(type).self")
            }
            if containsStandaloneTypeMember(type, member: "init", in: unapproved) {
                violations.append("\(type).init")
            }
        }
        return violations
    }

    func testDeterminismScannerRejectsAmbientAndSpellingEvasions() {
        let hostile = [
            "let value = Date()",
            "let value = Foundation . Date . now",
            "let value = Calendar /* disguise */ . current",
            "let value = Calendar\n.autoupdatingCurrent",
            "let value = Foundation.Locale . current",
            "let value = TimeZone /* disguise */ . autoupdatingCurrent",
            "let opener = \"/*\"; let value = Calendar.current; let closer = \"*/\"",
            "let marker = \"//\"; let value = TimeZone.autoupdatingCurrent",
            "let value = Foundation . Calendar (identifier: .gregorian)",
            "let value = Date . init (timeIntervalSinceReferenceDate: 0)",
            "typealias ClockDate = Date; let value = ClockDate()",
            "typealias AmbientCalendar = Foundation.Calendar; let value = AmbientCalendar.current",
            "typealias HiddenDate = FoundationEssentials.Date; let value = HiddenDate()",
            "typealias HiddenCalendar = FoundationInternationalization.Calendar; let value = HiddenCalendar.current",
            "typealias HiddenLocale = FoundationInternationalization.Locale; let value = HiddenLocale.autoupdatingCurrent",
            "typealias WrappedClock = (Date); let value = WrappedClock()",
            "typealias DeepWrappedCalendar = ((FoundationEssentials.Calendar)); let value = DeepWrappedCalendar.current",
            "let Clock = Date.self; let value = Clock.init()",
            "let Clock = FoundationEssentials.Date.self; let value = Clock.init()",
            "let CalendarFactory = Calendar.init",
            "let value = DispatchTime.now()",
            "let value = ProcessInfo.processInfo.systemUptime",
        ]
        for source in hostile {
            XCTAssertFalse(Self.deterministicViolations(
                in: source, relativePath: "Hostile.swift"
            ).isEmpty, source)
        }

        XCTAssertEqual(Self.deterministicViolations(
            in: "picker.setDate(value, animated: false)\nlayoutInlineCalendar()\nlet metadata = UserDate.self\nlet factory = CalendarFactory.initialValue\nlet note = \"Date.self Calendar.init\"",
            relativePath: "Benign.swift"
        ), [])

        let allowed = Self.datePickerPreservedConstructorAllowlist
            .flatMap { spelling, count in Array(repeating: spelling, count: count) }
            .joined(separator: ";")
        XCTAssertEqual(Self.deterministicViolations(
            in: allowed, relativePath: "UIDatePicker.swift"
        ), [])
        let oneSpelling = "Calendar(identifier:.gregorian)"
        XCTAssertFalse(Self.deterministicViolations(
            in: allowed + ";" + oneSpelling,
            relativePath: "UIDatePicker.swift"
        ).isEmpty)
        XCTAssertFalse(Self.deterministicViolations(
            in: allowed.replacingOccurrences(of: oneSpelling, with: "", options: [],
                                             range: allowed.range(of: oneSpelling)),
            relativePath: "UIDatePicker.swift"
        ).isEmpty)
        let literalDecoy = allowed.replacingOccurrences(
            of: oneSpelling, with: "\"\(oneSpelling)\"", options: [],
            range: allowed.range(of: oneSpelling)
        )
        XCTAssertFalse(Self.deterministicViolations(
            in: literalDecoy, relativePath: "UIDatePicker.swift"
        ).isEmpty)
        let commentDecoy = allowed.replacingOccurrences(
            of: oneSpelling, with: "/* \(oneSpelling) */", options: [],
            range: allowed.range(of: oneSpelling)
        )
        XCTAssertFalse(Self.deterministicViolations(
            in: commentDecoy, relativePath: "UIDatePicker.swift"
        ).isEmpty)
        let interpolationDecoy = allowed.replacingOccurrences(
            of: oneSpelling, with: "\"\\(\(oneSpelling))\"", options: [],
            range: allowed.range(of: oneSpelling)
        )
        XCTAssertFalse(Self.deterministicViolations(
            in: interpolationDecoy, relativePath: "UIDatePicker.swift"
        ).isEmpty)
        XCTAssertFalse(Self.deterministicViolations(
            in: #"let value = "\(Date(timeIntervalSinceReferenceDate: 0))""#,
            relativePath: "UIDatePicker.swift"
        ).isEmpty)
    }

    func testRenderPathReadsNoWallClockLocaleOrRandomSource() throws {
        let fm = FileManager.default
        var offenders: [String] = []
        for module in ["Sources/OpenUIKit", "Sources/OpenCoreGraphics"] {
            let dir = Self.repoRoot.appendingPathComponent(module)
            guard let e = fm.enumerator(atPath: dir.path) else {
                return XCTFail("cannot enumerate \(module)")
            }
            for case let rel as String in e where rel.hasSuffix(".swift") {
                let path = dir.appendingPathComponent(rel)
                let text = try String(contentsOf: path, encoding: .utf8)
                for violation in Self.deterministicViolations(
                    in: text, relativePath: rel
                ) {
                    offenders.append("\(module)/\(rel): \(violation)")
                }
                for (n, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                    let line = rawLine.trimmingCharacters(in: .whitespaces)
                    // Comments are where these names get DISCUSSED; the rule
                    // is about code.
                    if line.hasPrefix("//") || line.hasPrefix("///") { continue }
                    for token in Self.banned where line.contains(token) {
                        offenders.append("\(module)/\(rel):\(n + 1): \(token) — \(line)")
                    }
                }
            }
        }
        XCTAssertEqual(offenders, [], """
            The render/layout path must stay deterministic — byte-identical \
            Linux renders depend on it (docs/PORTABILITY.md). Drive time \
            through UIWindow.tick(timestamp:) instead.
            """)
    }
}
