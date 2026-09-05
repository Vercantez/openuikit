import Dispatch
import XCTest
import os

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
