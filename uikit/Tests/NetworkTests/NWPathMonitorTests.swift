import Dispatch
import Network
import XCTest

/// NetNewsWire RSWeb/NetworkMonitor.swift: `NWPathMonitor()`,
/// `pathUpdateHandler`, `start(queue:)`, `cancel()`, and on the path
/// `status == .satisfied`, `availableInterfaces.first?.type`,
/// `isExpensive`, `isConstrained`.
///
/// MEASURED on Network.framework (Tools/oracle2/nwpathprobe,
/// transcript-macos.txt): before `start` the path is `.unsatisfied`,
/// reason `.notAvailable`, no interfaces, not expensive/constrained, no
/// IPv4/IPv6/DNS, and `queue` is nil; `start(queue:)` calls the handler
/// exactly once on that queue; `cancel()` delivers nothing further.
///
/// The port has no path source, so it never reports connectivity: the
/// one delivered path is the measured pre-start (unsatisfied) path.
/// Fail-closed: no fabricated network.
final class NWPathMonitorTests: XCTestCase {
    func testPathBeforeStartIsTheMeasuredUnsatisfiedPath() {
        let monitor = NWPathMonitor()
        let path = monitor.currentPath
        XCTAssertEqual(path.status, .unsatisfied)
        XCTAssertEqual(path.unsatisfiedReason, .notAvailable)
        XCTAssertTrue(path.availableInterfaces.isEmpty)
        XCTAssertFalse(path.isExpensive)
        XCTAssertFalse(path.isConstrained)
        XCTAssertFalse(path.supportsIPv4)
        XCTAssertFalse(path.supportsIPv6)
        XCTAssertFalse(path.supportsDNS)
        XCTAssertFalse(path.usesInterfaceType(.wifi))
        XCTAssertEqual(path, monitor.currentPath)
        XCTAssertNil(monitor.queue)
        XCTAssertEqual(NWPathMonitor(requiredInterfaceType: .cellular).currentPath.status, .unsatisfied)
    }

    func testStartDeliversOnePathOnTheGivenQueueAndCancelStopsDelivery() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "nwpath.test")
        let key = DispatchSpecificKey<Int>()
        queue.setSpecific(key: key, value: 7)
        let delivered = expectation(description: "handler")
        let lock = NSLock()
        var calls = 0
        var onQueue = false
        var status: NWPath.Status?
        monitor.pathUpdateHandler = { path in
            lock.lock()
            calls += 1
            onQueue = DispatchQueue.getSpecific(key: key) == 7
            status = path.status
            lock.unlock()
            delivered.fulfill()
        }
        monitor.start(queue: queue)
        wait(for: [delivered], timeout: 2)
        monitor.cancel()
        queue.sync {}
        lock.lock()
        XCTAssertEqual(calls, 1)
        XCTAssertTrue(onQueue)
        XCTAssertEqual(status, .unsatisfied)
        lock.unlock()
        XCTAssertTrue(monitor.queue === queue)
        XCTAssertEqual(monitor.currentPath.status, .unsatisfied)
    }

    func testInterfaceTypeCasesAndSendableShape() {
        let types: [NWInterface.InterfaceType] = [.other, .wifi, .cellular, .wiredEthernet, .loopback]
        XCTAssertEqual(Set(types).count, 5)
        // NetNewsWire stores the monitor in a `Sendable` final class.
        final class Holder: Sendable { let monitor = NWPathMonitor() }
        XCTAssertEqual(Holder().monitor.currentPath.status, .unsatisfied)
    }
}
