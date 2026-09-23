// Built with -swift-version 4 (Package.swift). Each spelling here is one real
// UIKit imports in Swift 4 mode, per the iPhoneSimulator26.1 SDK's
// UIKit.apinotes `SwiftVersions: Version 4` section; Eidolon's source uses
// them (UIControlEvents, UIViewAnimationOptions, NSNotification.Name.UI...).
import XCTest
import Foundation
@testable import OpenUIKit

final class Swift4NamesTests: XCTestCase {
    func testSwift4TypeNamesAreTheCurrentTypes() {
        let events: UIControlEvents = .touchUpInside
        XCTAssertEqual(events, UIControl.Event.touchUpInside)
        let options: UIViewAnimationOptions = [.curveEaseInOut]
        XCTAssertEqual(options, UIView.AnimationOptions.curveEaseInOut)
        XCTAssertTrue(UITableViewStyle.self == UITableView.Style.self)
        XCTAssertTrue(UIViewAutoresizing.self == UIView.AutoresizingMask.self)
    }

    func testSwift4NotificationNames() {
        XCTAssertEqual(NSNotification.Name.UIApplicationDidBecomeActive,
                       UIApplication.didBecomeActiveNotification)
        XCTAssertEqual(NSNotification.Name.UIApplicationDidBecomeActive.rawValue,
                       "UIApplicationDidBecomeActiveNotification")
    }
}
