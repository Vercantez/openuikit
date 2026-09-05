#if os(Linux)
import CLinuxXCTestSupport
import XCTest

/// Forces the CLinuxXCTestSupport object file into the test executable so
/// its constructor runs before XCTMain. The pump itself is installed from
/// that constructor (see Sources/CLinuxXCTestSupport/pump.c).
final class LinuxXCTestPumpTests: XCTestCase {
    func testPumpConstructorInstalled() {
        // Touch the C symbol so the linker cannot GC the constructor.
        XCTAssertEqual(linux_xctest_pump_installed(), 1)
        XCTAssertEqual(linux_xctest_pump_install(), 1)
    }
}
#endif
