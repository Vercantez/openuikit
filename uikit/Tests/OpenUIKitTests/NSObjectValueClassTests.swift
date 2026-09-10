// The UIKit value classes Apple derives from NSObject, and the accessibility
// informal protocol Apple puts ON NSObject.
//
// Every expectation below is either a line from the iOS 26.1 SDK headers
// (path and line number named in the comment) or a line from the
// Tools/oracle2/nsobjectvalueprobe transcript recorded on iPhone 16 /
// iOS 26.1 (docs/agent_reports/nsobject-value-classes.md). Nothing here is a
// guess.
import XCTest
import Foundation
@testable import OpenUIKit

// OpenUIKit's value classes SHADOW the platform's (docs/KNOWN_GAPS.md), and
// this file imports both. Same disambiguation AttributedStringTests writes.
private typealias CALayer = OpenUIKit.CALayer
private typealias NSParagraphStyle = OpenUIKit.NSParagraphStyle
private typealias NSMutableParagraphStyle = OpenUIKit.NSMutableParagraphStyle

#if !os(Linux)
@MainActor
#endif
final class NSObjectValueClassTests: XCTestCase {

    // MARK: - Class hierarchy
    //
    // Oracle `hierarchy` rows (runtime superclass chains walked with
    // class_getSuperclass):
    //   CALayer                  -> [CALayer, NSObject]
    //   UIBarItem                -> [UIBarItem, NSObject]
    //   UIBarButtonItem          -> [UIBarButtonItem, UIBarItem, NSObject]
    //   UITabBarItem             -> [UITabBarItem, UIBarItem, NSObject]
    //   UINavigationItem         -> [UINavigationItem, NSObject]
    //   NSParagraphStyle         -> [NSParagraphStyle, NSObject]
    //   NSMutableParagraphStyle  -> [NSMutableParagraphStyle, NSParagraphStyle, NSObject]

    func testLayerIsNSObject() {
        XCTAssertTrue(CALayer() is NSObject)
    }

    func testBarItemsAreNSObjectsUnderUIBarItem() {
        let button = UIBarButtonItem(title: "Back", style: .plain)
        let tab = UITabBarItem(title: "Home", image: nil, tag: 0)
        XCTAssertTrue(button is UIBarItem)
        XCTAssertTrue(button is NSObject)
        XCTAssertTrue(tab is UIBarItem)
        XCTAssertTrue(tab is NSObject)
    }

    func testNavigationItemIsNSObject() {
        XCTAssertTrue(UINavigationItem(title: "Root") is NSObject)
    }

    func testParagraphStylesAreNSObjects() {
        XCTAssertTrue(NSParagraphStyle() is NSObject)
        let mutable = NSMutableParagraphStyle()
        XCTAssertTrue(mutable is NSParagraphStyle)
        XCTAssertTrue(mutable is NSObject)
    }

    // MARK: - The accessibility informal protocol lives on NSObject
    //
    // Oracle `nsobject.defaults`, read on a bare `NSObject()`:
    //   isAccessibilityElement false, accessibilityLabel/Hint/Value nil,
    //   accessibilityTraits 0, accessibilityElementsHidden false,
    //   accessibilityViewIsModal false, shouldGroupAccessibilityChildren
    //   false, accessibilityNavigationStyle 0, accessibilityElements nil.

    func testBareNSObjectAccessibilityDefaults() {
        let bare = NSObject()
        XCTAssertFalse(bare.isAccessibilityElement)
        XCTAssertNil(bare.accessibilityLabel)
        XCTAssertNil(bare.accessibilityHint)
        XCTAssertNil(bare.accessibilityValue)
        XCTAssertEqual(bare.accessibilityTraits.rawValue, 0)
        XCTAssertFalse(bare.accessibilityElementsHidden)
        XCTAssertFalse(bare.accessibilityViewIsModal)
        XCTAssertFalse(bare.shouldGroupAccessibilityChildren)
        XCTAssertEqual(bare.accessibilityNavigationStyle, .automatic)
        XCTAssertNil(bare.accessibilityElements)
    }

    // Oracle `nsobject.roundtrip`: writing on one object leaves another
    // object's values at their defaults.
    func testNSObjectAccessibilityRoundTripsAndIsPerObject() {
        let a = NSObject()
        let b = NSObject()
        a.accessibilityLabel = "alpha"
        a.isAccessibilityElement = true
        a.accessibilityTraits = .button
        a.accessibilityElementsHidden = true
        a.shouldGroupAccessibilityChildren = true
        XCTAssertEqual(a.accessibilityLabel, "alpha")
        XCTAssertTrue(a.isAccessibilityElement)
        XCTAssertEqual(a.accessibilityTraits, .button)
        XCTAssertTrue(a.accessibilityElementsHidden)
        XCTAssertTrue(a.shouldGroupAccessibilityChildren)
        XCTAssertNil(b.accessibilityLabel)
        XCTAssertFalse(b.isAccessibilityElement)
    }

    // Oracle `nonview.roundtrip`: UIKit objects that are NOT views carry the
    // same properties. This is the row the port could not satisfy before.
    func testAccessibilityReachableOnNonViewUIKitObjects() {
        let button = UIBarButtonItem(title: "Back", style: .plain)
        button.accessibilityLabel = "back-button"
        button.accessibilityIdentifier = "nav.back"
        let navItem = UINavigationItem(title: "Root")
        navItem.accessibilityLabel = "root-item"
        let layer = CALayer()
        layer.accessibilityLabel = "layer"
        let paragraph = NSMutableParagraphStyle()
        paragraph.accessibilityValue = "para"
        XCTAssertEqual(button.accessibilityLabel, "back-button")
        XCTAssertEqual(button.accessibilityIdentifier, "nav.back")
        XCTAssertEqual(navItem.accessibilityLabel, "root-item")
        XCTAssertEqual(layer.accessibilityLabel, "layer")
        XCTAssertEqual(paragraph.accessibilityValue, "para")
    }

    // A view and its NSObject-typed self are ONE object with ONE state: the
    // trap of adding NSObject-level storage next to the old UIResponder
    // storage would show up right here as a divergence.
    func testViewAndItsNSObjectViewAgreeOnOneState() {
        let view = UIView(frame: .zero)
        view.accessibilityLabel = "through-uiview"
        let asObject: NSObject = view
        XCTAssertEqual(asObject.accessibilityLabel, "through-uiview")
        asObject.accessibilityLabel = "through-nsobject"
        XCTAssertEqual(view.accessibilityLabel, "through-nsobject")
        XCTAssertEqual(view.accessibilityValue, asObject.accessibilityValue)
        view.accessibilityValue = "v"
        XCTAssertEqual(asObject.accessibilityValue, "v")
    }

    // Kickstarter-ReactiveExtensions' shape verbatim: a member written
    // against `Object: NSObject` and applied to a UIKit type. Before the
    // move this did not compile (12 of ReactiveExtensions' 12 diagnostics).
    func testGenericNSObjectConstraintReachesAccessibility() {
        func bind<Object: NSObject>(_ object: Object, label: String) {
            object.accessibilityLabel = label
            object.isAccessibilityElement = true
            object.accessibilityElementsHidden = false
            object.accessibilityHint = "hint"
            object.accessibilityValue = "value"
            object.accessibilityTraits = .header
        }
        let label = UILabel(frame: .zero)
        bind(label, label: "bound")
        XCTAssertEqual(label.accessibilityLabel, "bound")
        XCTAssertEqual(label.accessibilityTraits, .header)
        XCTAssertEqual(label.accessibilityValue, "value")

        let item = UIBarButtonItem()
        bind(item, label: "item")
        XCTAssertEqual(item.accessibilityLabel, "item")
        XCTAssertTrue(item.isAccessibilityElement)
    }

    // Kickstarter-Prelude's `KSObjectProtocol: NSObjectProtocol` shape:
    // nine `{ get set }` accessibility requirements, then a RETROACTIVE
    // conformance on the UIKit types. `_PreludeKSObjectShape` below is that
    // protocol; the conformances are the compile fixture.
    func testPreludeStyleLensProtocolConformances() {
        let subjects: [_PreludeKSObjectShape] = [
            UIView(frame: .zero),
            CALayer(),
            UIBarButtonItem(),
            UITabBarItem(title: nil, image: nil, tag: 0),
            UINavigationItem(),
        ]
        for subject in subjects {
            subject.accessibilityLabel = "lensed"
            subject.isAccessibilityElement = true
            subject.accessibilityElements = ["child"]
            subject.shouldGroupAccessibilityChildren = true
            XCTAssertEqual(subject.accessibilityLabel, "lensed")
            XCTAssertTrue(subject.isAccessibilityElement)
            XCTAssertEqual(subject.accessibilityElements?.count, 1)
            XCTAssertTrue(subject.shouldGroupAccessibilityChildren)
        }
    }

    // An object that is gone must not lend its state to whatever lands on
    // its address next. The side table keys on the address, so every entry
    // carries a weak owner and a mismatched owner reads as absent.
    func testAccessibilityStateDoesNotLeakAcrossObjectLifetimes() {
        for _ in 0 ..< 2_000 {
            let scratch = NSObject()
            XCTAssertNil(scratch.accessibilityLabel,
                         "a fresh object inherited a dead object's label")
            scratch.accessibilityLabel = "transient"
        }
        // The sweep keeps the table from growing without bound: after it, no
        // entry may name a deallocated object.
        _UIAccessibilityStorage.sweep()
        let dead = _UIAccessibilityStorage.boxes.values.filter { $0.owner == nil }
        XCTAssertTrue(dead.isEmpty,
                      "\(dead.count) entries survived the sweep with no owner")
        let live = NSObject()
        live.accessibilityLabel = "live"
        XCTAssertEqual(live.accessibilityLabel, "live")
    }

    // MARK: - UIBarItem
    //
    // SDK: UIBarItem.h:19-40 (superclass NSObject; enabled default YES,
    // title/image nil, imageInsets zero, tag 0). Oracle
    // `UIBarButtonItem.defaults` / `UITabBarItem.defaults` confirm each.

    func testUIBarItemDefaultsOnBothSubclasses() {
        for item in [UIBarButtonItem() as UIBarItem,
                     UITabBarItem(title: nil, image: nil, tag: 0)] {
            XCTAssertTrue(item.isEnabled)
            XCTAssertNil(item.title)
            XCTAssertNil(item.image)
            XCTAssertNil(item.landscapeImagePhone)
            XCTAssertNil(item.largeContentSizeImage)
            XCTAssertEqual(item.imageInsets, .zero)
            XCTAssertEqual(item.landscapeImagePhoneInsets, .zero)
            XCTAssertEqual(item.tag, 0)
            XCTAssertNil(item.titleTextAttributes(for: .normal))
            XCTAssertNil(item.accessibilityIdentifier)
        }
    }

    // Oracle `UITabBarItem.defaults`: the designated initializer's title and
    // tag land on the inherited UIBarItem storage (title "Home", tag 3).
    func testUITabBarItemInitializerFillsInheritedStorage() {
        let tab = UITabBarItem(title: "Home", image: nil, tag: 3)
        XCTAssertEqual(tab.title, "Home")
        XCTAssertEqual(tab.tag, 3)
        XCTAssertTrue(tab.isEnabled)
        XCTAssertNil(tab.selectedImage)
        XCTAssertEqual(tab.titlePositionAdjustment, .zero)
        let asBarItem: UIBarItem = tab
        XCTAssertEqual(asBarItem.title, "Home")
        XCTAssertEqual(asBarItem.tag, 3)
    }

    func testUIBarButtonItemInitializersFillInheritedStorage() {
        XCTAssertEqual(UIBarButtonItem(title: "Save", style: .done).title, "Save")
        XCTAssertEqual(UIBarButtonItem(barButtonSystemItem: .edit).title, "Edit")
        XCTAssertEqual(UIBarButtonItem(barButtonSystemItem: .save).title, "Save")
        XCTAssertNil(UIBarButtonItem().title)
        let action = UIAction(title: "Go") { _ in }
        XCTAssertEqual(UIBarButtonItem(primaryAction: action).title, "Go")
    }

    func testTitleTextAttributesRoundTripPerState() {
        let item = UIBarItem()
        item.setTitleTextAttributes([.foregroundColor: UIColor.red], for: .normal)
        XCTAssertNotNil(item.titleTextAttributes(for: .normal))
        XCTAssertNil(item.titleTextAttributes(for: .highlighted))
        item.setTitleTextAttributes(nil, for: .normal)
        XCTAssertNil(item.titleTextAttributes(for: .normal))
    }

    // MARK: - UIBarButtonItem per-state / per-metrics appearance
    //
    // Oracle `UIBarButtonItem.appearanceDefaults` (all nil / zero) and
    // `appearanceRoundtrip` (a 2×2 image is readable back for
    // (.normal, .default) but NOT for (.normal, .compact); the title
    // adjustment reads (3, -4) for .default and (0, 0) for .compact; the
    // vertical adjustment reads 7).

    func testBarButtonItemAppearanceDefaults() {
        let item = UIBarButtonItem()
        XCTAssertNil(item.backgroundImage(for: .normal, barMetrics: .default))
        XCTAssertNil(item.backgroundImage(for: .normal, style: .plain,
                                          barMetrics: .default))
        XCTAssertEqual(item.backgroundVerticalPositionAdjustment(for: .default), 0)
        XCTAssertEqual(item.titlePositionAdjustment(for: .default), .zero)
        XCTAssertNil(item.backButtonBackgroundImage(for: .normal, barMetrics: .default))
        XCTAssertEqual(item.backButtonTitlePositionAdjustment(for: .default), .zero)
        XCTAssertEqual(
            item.backButtonBackgroundVerticalPositionAdjustment(for: .default), 0)
        XCTAssertNil(item.possibleTitles)
    }

    func testBarButtonItemAppearanceRoundTripsPerMetrics() {
        let item = UIBarButtonItem()
        let image = UIImage(bitmap: Bitmap(width: 2, height: 2))
        item.setBackgroundImage(image, for: .normal, barMetrics: .default)
        item.setTitlePositionAdjustment(UIOffset(horizontal: 3, vertical: -4),
                                        for: .default)
        item.setBackgroundVerticalPositionAdjustment(7, for: .default)
        item.possibleTitles = ["One", "Two"]
        XCTAssertEqual(item.backgroundImage(for: .normal, barMetrics: .default)?
            .size, CGSize(width: 2, height: 2))
        XCTAssertNil(item.backgroundImage(for: .normal, barMetrics: .compact))
        XCTAssertEqual(item.titlePositionAdjustment(for: .default),
                       UIOffset(horizontal: 3, vertical: -4))
        XCTAssertEqual(item.titlePositionAdjustment(for: .compact), .zero)
        XCTAssertEqual(item.backgroundVerticalPositionAdjustment(for: .default), 7)
        XCTAssertEqual(item.possibleTitles?.sorted(), ["One", "Two"])
    }

    // MARK: - CALayer
    //
    // Oracle `CALayer.defaults`: shouldRasterize false, rasterizationScale 1,
    // masksToBounds false, borderWidth 0, cornerRadius 0, shadowOpacity 0,
    // shadowRadius 3, shadowOffset (0, -3), borderColor and shadowColor
    // non-nil.

    func testLayerLensMembersAndDefaults() {
        let layer = CALayer()
        XCTAssertFalse(layer.shouldRasterize)
        XCTAssertEqual(layer.rasterizationScale, 1)
        XCTAssertFalse(layer.masksToBounds)
        XCTAssertEqual(layer.borderWidth, 0)
        XCTAssertEqual(layer.cornerRadius, 0)
        XCTAssertEqual(layer.shadowOpacity, 0)
        XCTAssertEqual(layer.shadowRadius, 3)
        XCTAssertEqual(layer.shadowOffset, CGSize(width: 0, height: -3))
        XCTAssertNotNil(layer.borderColor)
        XCTAssertNotNil(layer.shadowColor)
        layer.shouldRasterize = true
        layer.rasterizationScale = 3
        XCTAssertTrue(layer.shouldRasterize)
        XCTAssertEqual(layer.rasterizationScale, 3)
    }

    // The bounded KVC compatibility surface still answers on a layer that is
    // now an NSObject (the Darwin build makes these overrides of NSObject's
    // real KVC, so a regression here would surface as `undefined key`).
    func testLayerKeyValueCompatibilitySurvivesTheReparent() {
        let layer = CALayer()
        layer.setValue(true, forKey: "isOpaque")
        XCTAssertEqual(layer.value(forKey: "isOpaque") as? Bool, true)
        layer.setValue(4.5, forKeyPath: "filters.gaussianBlur.inputRadius")
        XCTAssertEqual(
            layer.value(forKeyPath: "filters.gaussianBlur.inputRadius") as? Double,
            4.5)
    }

    // MARK: - NSParagraphStyle value semantics
    //
    // Oracle `NSParagraphStyle.value`: mutableCopy() is an
    // NSMutableParagraphStyle, copy() an NSParagraphStyle, the two compare
    // equal but are not identical, their hashes agree, and a Set of the two
    // has ONE element — which is what proves isEqual/hash are the Hashable
    // witnesses. After mutating one, they differ and the Set has two.

    func testParagraphStyleCopySemantics() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 6
        style.tailIndent = -12

        let mutable = style.mutableCopy() as! NSMutableParagraphStyle
        let immutable = style.copy() as! NSParagraphStyle
        XCTAssertFalse(mutable === style)
        XCTAssertFalse(immutable is NSMutableParagraphStyle)
        XCTAssertTrue(style.isEqual(mutable))
        XCTAssertEqual(style, mutable)
        XCTAssertEqual(style.hash, mutable.hash)
        XCTAssertEqual(Set([style as NSParagraphStyle, mutable as NSParagraphStyle]).count, 1)
        XCTAssertEqual(immutable.lineSpacing, 6)
        XCTAssertEqual(immutable.tailIndent, -12)

        mutable.lineSpacing = 7
        XCTAssertFalse(style.isEqual(mutable))
        XCTAssertNotEqual(style, mutable)
        XCTAssertEqual(Set([style as NSParagraphStyle, mutable as NSParagraphStyle]).count, 2)
        XCTAssertEqual(style.lineSpacing, 6)
    }

    // Oracle `NSParagraphStyle.default`: lineSpacing 0, hyphenationFactor 0.
    func testParagraphStyleDefaultIsUnchanged() {
        XCTAssertEqual(NSParagraphStyle.default.lineSpacing, 0)
        XCTAssertEqual(NSParagraphStyle.default.hyphenationFactor, 0)
        XCTAssertTrue(NSParagraphStyle.default.isDefaultLayout)
    }

    // The typed helper the port's own callers use, kept beside Apple's
    // `mutableCopy()`.
    func testTypedMutableParagraphStyleCopy() {
        let style = NSMutableParagraphStyle()
        style.headIndent = 9
        let copy = style.mutableParagraphStyleCopy()
        XCTAssertEqual(copy.headIndent, 9)
        copy.headIndent = 3
        XCTAssertEqual(style.headIndent, 9)
    }
}

/// Kickstarter-Prelude's `KSObjectProtocol` reduced to its shape: nine
/// accessibility requirements rooted at a class-bound protocol, then a
/// retroactive conformance on each UIKit type its lenses cover. This is the
/// declaration that failed with "cannot declare conformance to
/// NSObjectProtocol" before the types became NSObject subclasses.
protocol _PreludeKSObjectShape: NSObjectProtocol {
    var accessibilityElementsHidden: Bool { get set }
    var accessibilityElements: [Any]? { get set }
    var accessibilityHint: String? { get set }
    var accessibilityLabel: String? { get set }
    var accessibilityNavigationStyle: UIAccessibilityNavigationStyle { get set }
    var accessibilityTraits: UIAccessibilityTraits { get set }
    var accessibilityValue: String? { get set }
    var isAccessibilityElement: Bool { get set }
    var shouldGroupAccessibilityChildren: Bool { get set }
}

extension UIView: _PreludeKSObjectShape {}
extension CALayer: _PreludeKSObjectShape {}
extension UIBarItem: _PreludeKSObjectShape {}
extension UINavigationItem: _PreludeKSObjectShape {}
