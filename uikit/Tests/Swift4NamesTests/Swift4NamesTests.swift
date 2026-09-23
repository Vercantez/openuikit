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

    @MainActor
    func testSwift4MemberNames() {
        XCTAssertEqual(UIEdgeInsetsMake(1, 2, 3, 4), UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        let parent = UIViewController(), child = UIViewController()
        parent.addChild(child)
        XCTAssertTrue(parent.childViewControllers.first === child)
        let v = UIView(), a = UIView(), b = UIView()
        v.addSubview(a); v.addSubview(b)
        v.bringSubview(toFront: a)
        XCTAssertTrue(v.subviews.last === a)
        v.sendSubview(toBack: a)
        XCTAssertTrue(v.subviews.first === a)
        XCTAssertEqual(NSUnderlineStyle.styleSingle, NSUnderlineStyle.single)
        XCTAssertEqual(UIScrollViewDecelerationRateFast, UIScrollView.DecelerationRate.fast)
    }

    func testSwift4NotificationNames() {
        XCTAssertEqual(NSNotification.Name.UIApplicationDidBecomeActive,
                       UIApplication.didBecomeActiveNotification)
        XCTAssertEqual(NSNotification.Name.UIApplicationDidBecomeActive.rawValue,
                       "UIApplicationDidBecomeActiveNotification")
    }
}
