import Dispatch
import XCTest
import os
#if canImport(ObjectiveC)
import ObjectiveC
#endif

final class OSSignposterTests: XCTestCase {
    // MEASURED Tools/oracle2/signposterprobe/transcript-macos.txt.
    func testNetNewsWireArticlesTableShapeAndMeasuredValues() {
        // ArticlesTable.swift:28 / 767 / 771 / 777.
        let s = OSSignposter(subsystem: "com.example.probe", category: .pointsOfInterest)
        XCTAssertTrue(s.isEnabled)
        XCTAssertTrue(OSSignposter(subsystem: "com.example.probe", category: "x").isEnabled)
        XCTAssertTrue(OSSignposter().isEnabled)
        XCTAssertFalse(OSSignposter(logHandle: .disabled).isEnabled)
        let a = s.makeSignpostID()
        let b = s.makeSignpostID()
        XCTAssertNotEqual(a, b)
        for id in [a, b] {
            XCTAssertNotEqual(id, .invalid)
            XCTAssertNotEqual(id, .null)
            XCTAssertNotEqual(id, .exclusive)
        }
        let state = s.beginInterval("Fetch articles")
        s.endInterval("Fetch articles", state, "\(3) articles")
        s.endInterval("Fetch articles", s.beginInterval("Fetch articles"), "no result set")
        s.emitEvent("event")
        XCTAssertEqual(s.withIntervalSignpost("around") { 42 }, 42)
    }

#if canImport(ObjectiveC)
    /// The test bundle loads Apple's libswiftos too; a port class registered
    /// under Apple's runtime name (_TtC2os23OSSignpostIntervalState) makes
    /// objc warn "implemented in both ... spurious casting failures".
    func testIntervalStateDoesNotTakeAppleRuntimeName() {
        let name = String(cString: class_getName(OSSignpostIntervalState.self))
        // class_getName spells Apple's class either way.
        XCTAssertFalse(["_TtC2os23OSSignpostIntervalState", "os.OSSignpostIntervalState"].contains(name), name)
    }
#endif

    func testSignpostIDSentinelsMatchApple() {
        XCTAssertEqual(OSSignpostID.exclusive.rawValue, 0xEEEEB0B5B2B2EEEE)
        XCTAssertEqual(OSSignpostID.invalid.rawValue, UInt64.max)
        XCTAssertEqual(OSSignpostID.null.rawValue, 0)
    }
}

final class OSLogFormattingTests: XCTestCase {
    func testFloatIntegerFormattingAndAlignmentInterpolationsCompile() {
        // NetNewsWire RSDatabase FMDatabase+Extras.swift:43:
        //   "\(duration, format: .fixed(precision: 4), privacy: .public)"
        // Declarations follow iPhoneSimulator26.1.sdk os.swiftinterface
        // (OSLogFloatFormatting / OSLogIntegerFormatting / OSLogStringAlignment).
        // The port's Logger discards messages, so the values are never read.
        let logger = Logger(subsystem: "com.example", category: "fmt")
        let duration = 0.25
        let count = 7
        let ratio: Float = 1.5
        logger.debug("VACUUM took \(duration, format: .fixed(precision: 4), privacy: .public) seconds")
        logger.info("\(duration, format: .exponential) \(duration, format: .hybrid(precision: 3)) \(ratio, format: .fixed)")
        logger.info("\(duration, format: .fixed, align: .right(columns: 8))")
        logger.info("\(count, format: .hex(includePrefix: true), privacy: .public) \(count, format: .decimal(minDigits: 3))")
        logger.info("\(UInt8(3), format: .octal) \(Int64(9), format: .decimal, align: .left(columns: 4))")
        // the existing privacy-only shape still resolves (no ambiguity)
        logger.info("\(count, privacy: .public) \(duration)")
        XCTAssertEqual(logger.category, "fmt")
    }
}

final class OSAllocatedUnfairLockTests: XCTestCase {
    func testWithLockSerializesConcurrentIncrements() {
        // NetNewsWire Cache.swift:24 / Hackers DependencyContainer.swift:85
        // shape: OSAllocatedUnfairLock(initialState:) + withLock { $0 }.
        let lock = OSAllocatedUnfairLock(initialState: 0)
        let iterations = 1000
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            lock.withLock { $0 += 1 }
        }
        XCTAssertEqual(lock.withLock { $0 }, iterations)
    }

    func testWithLockUncheckedMatchesWithLock() {
        let lock = OSAllocatedUnfairLock(initialState: 0)
        lock.withLockUnchecked { $0 = 7 }
        XCTAssertEqual(lock.withLockUnchecked { $0 }, 7)
    }

    func testOptionalStateGetSet() {
        // Hackers Shared DependencyContainer.swift:85–88.
        let lock = OSAllocatedUnfairLock<Int?>(initialState: nil)
        XCTAssertNil(lock.withLock { $0 })
        lock.withLock { $0 = 3 }
        XCTAssertEqual(lock.withLock { $0 }, 3)
    }

    func testVoidLockNoArgumentWithLock() {
        // nextcloud NotificationService.swift:31 then line 127.
        let lock = OSAllocatedUnfairLock()
        var seen = 0
        lock.withLock { seen = 4 }
        XCTAssertEqual(seen, 4)
        lock.withLockUnchecked { seen = 5 }
        XCTAssertEqual(seen, 5)
    }

    func testUncheckedStateInitializer() {
        let lock = OSAllocatedUnfairLock(uncheckedState: 11)
        XCTAssertEqual(lock.withLock { $0 }, 11)
    }
}

final class OSLoggerTests: XCTestCase {
    func testSubsystemCategoryInitAndMethods() {
        // Hackers PostRepository+Parsing.swift:14; NetNewsWire Account.swift:94.
        let logger = Logger(subsystem: "com.weiranzhang.Hackers", category: "PostRepository.Parsing")
        XCTAssertEqual(logger.subsystem, "com.weiranzhang.Hackers")
        XCTAssertEqual(logger.category, "PostRepository.Parsing")
        logger.log("plain")
        logger.debug("debug")
        logger.info("info")
        logger.notice("notice")
        logger.warning("warning")
        logger.error("error")
        logger.fault("fault")
        logger.critical("critical")
        logger.trace("trace")
        logger.log(level: .error, "Failed")
    }

    func testEmptyInit() {
        // Pocket Casts FileLog.swift:28.
        let logger = Logger()
        logger.info("\(logger.subsystem)")
    }

    func testPrivacyInterpolationIsAccepted() {
        // NetNewsWire Account.swift:366 privacy: .public (451 corpus hits);
        // ProtonMail AppLogger.swift:44 privacy: .public; 3× .private.
        let logger = Logger(subsystem: "Account", category: "Account")
        let type = "feedbin"
        let error = "failed"
        logger.error("Account: retrieveCredentials: failed to retrieve \(type, privacy: .public) credentials: \(error, privacy: .public)")
        logger.info("mask \(error, privacy: .private)")
        logger.debug("auto \(type)")
        logger.info("\(error, privacy: .sensitive)")
    }

    func testOSLogAndOsLogCallShapes() {
        // Focus NimbusWrapper.swift:57–68.
        let log = OSLog(subsystem: "org.mozilla.nimbus", category: "default")
        os_log("%{private}@", log: log, type: .error, "secret")
        os_log("%@", log: log, type: .debug, "debug")
        os_log("%@", log: log, type: .info, "info")
        os_log("%@", log: log, type: .fault, "warn")
        os_log("%@", log: log, type: .error, "error")
        // DuckDuckGo AutofillCredentialsDebugViewController.swift:139 / 200.
        os_log("Failed to fetch accounts")
        os_log("Error creating attributed string: \(errorMessage)")
        XCTAssertEqual(log.subsystem, "org.mozilla.nimbus")
        XCTAssertNotEqual(OSLog.default, OSLog.disabled)
    }

    func testOsSignpostNoOp() {
        // DuckDuckGo Core/Instruments.swift:44–63.
        let log = OSLog(subsystem: "com.duckduckgo.instrumentation", category: "Events")
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "Timed Event", signpostID: id,
                    "Event: %@ info: %@", "tabInitialisation", "")
        os_signpost(.end, log: log, name: "Timed Event", signpostID: id,
                    "Result: %@", "")
        os_signpost(.event, log: log, name: "Tick")
        XCTAssertNotEqual(id, OSSignpostID.invalid)
    }

    private var errorMessage: String { "boom" }
}
