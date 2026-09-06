import XCTest
import UIKit
import SnapKit

final class SnapKitOpenUIKitTests: XCTestCase {
    func testMakeConstraintsInstallsLayoutConstraints() {
        // SnapKit 5.7.0 Tests.swift testMakeConstraints, against OpenUIKit
        // UIView (canImport(UIKit) is true because this target depends on
        // the OpenUIKit UIKit product). MEASURED /tmp/snapkit-ouik: 36/37
        // SnapKit sources compiled; Debugging.swift description override
        // needed NSLayoutConstraint: NSObject.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let v1 = UIView()
        let v2 = UIView()
        container.addSubview(v1)
        container.addSubview(v2)

        v1.snp.makeConstraints { make in
            make.top.equalTo(v2.snp.top).offset(50)
            make.left.equalTo(v2.snp.left).offset(50)
        }
        XCTAssertEqual(container.constraints.filter { $0 is LayoutConstraint }.count, 2)

        v2.snp.makeConstraints { make in
            make.edges.equalTo(v1)
        }
        XCTAssertEqual(container.constraints.filter { $0 is LayoutConstraint }.count, 6)
    }

    func testSafeAreaLayoutGuideSnp() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let child = UIView()
        container.addSubview(child)
        child.snp.makeConstraints { make in
            make.edges.equalTo(container.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }
        XCTAssertFalse(child.translatesAutoresizingMaskIntoConstraints)
        XCTAssertGreaterThan(container.constraints.count, 0)
    }
}
