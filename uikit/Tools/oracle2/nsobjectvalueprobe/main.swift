// NSObject-derived UIKit value classes oracle.
//
// The SDK headers state the DECLARATIONS (superclass, protocol list); this
// probe measures the parts that are behaviour rather than declaration, on a
// real iPhone 16 / iOS 26.1 simulator:
//
//   * the runtime class chain of CALayer, UIBarItem, UIBarButtonItem,
//     UITabBarItem, UINavigationItem, NSParagraphStyle and
//     NSMutableParagraphStyle (`class_getSuperclass` walked to the root),
//     and which of NSObjectProtocol / NSCoding / NSSecureCoding / NSCopying /
//     NSMutableCopying / UIAppearance each class conforms to;
//   * the value every UIAccessibility informal property reads on a BARE
//     `NSObject()` — the defaults a port has to reproduce;
//   * that the same properties are reachable and round-trip on objects that
//     are not views (a UIBarButtonItem, a UINavigationItem, a CALayer);
//   * UIBarItem's own defaults as inherited by both subclasses;
//   * NSParagraphStyle equality/hash/copy semantics, including whether two
//     equal-valued styles collapse in a Set (which is what tells you the
//     Hashable witnesses are isEqual/hash, not a Swift == / hash(into:)).
//
// Writes Documents/nsobject-value.json.
import UIKit
import ObjectiveC

var rows: [String: Any] = [:]

func chain(_ cls: AnyClass) -> [String] {
    var out: [String] = []
    var c: AnyClass? = cls
    while let k = c {
        out.append(NSStringFromClass(k))
        c = class_getSuperclass(k)
    }
    return out
}

func conformances(_ cls: AnyClass) -> [String: Bool] {
    var out: [String: Bool] = [:]
    let named: [(String, Protocol?)] = [
        ("NSObjectProtocol", NSProtocolFromString("NSObject")),
        ("NSCoding", NSProtocolFromString("NSCoding")),
        ("NSSecureCoding", NSProtocolFromString("NSSecureCoding")),
        ("NSCopying", NSProtocolFromString("NSCopying")),
        ("NSMutableCopying", NSProtocolFromString("NSMutableCopying")),
        ("UIAppearance", NSProtocolFromString("UIAppearance")),
        ("CAMediaTiming", NSProtocolFromString("CAMediaTiming")),
        ("UIAccessibilityIdentification",
         NSProtocolFromString("UIAccessibilityIdentification")),
    ]
    for (name, proto) in named {
        guard let proto else { out[name] = false; continue }
        out[name] = class_conformsToProtocol(cls, proto) || cls.conforms(to: proto)
    }
    return out
}

func str(_ s: String?) -> Any { s ?? NSNull() }

@MainActor
func measure() {
    rows["os"] = UIDevice.current.systemVersion
    rows["device"] = UIDevice.current.model

    // (1) Declarations, as the runtime sees them.
    var hierarchy: [String: Any] = [:]
    for cls in [CALayer.self as AnyClass, UIBarItem.self, UIBarButtonItem.self,
                UITabBarItem.self, UINavigationItem.self, NSParagraphStyle.self,
                NSMutableParagraphStyle.self, UIView.self, UIResponder.self] {
        hierarchy[NSStringFromClass(cls)] = [
            "chain": chain(cls),
            "conforms": conformances(cls),
        ]
    }
    rows["hierarchy"] = hierarchy

    // (2) UIAccessibility informal-protocol defaults on a BARE NSObject.
    let bare = NSObject()
    rows["nsobject.defaults"] = [
        "isAccessibilityElement": bare.isAccessibilityElement,
        "accessibilityLabel": str(bare.accessibilityLabel),
        "accessibilityHint": str(bare.accessibilityHint),
        "accessibilityValue": str(bare.accessibilityValue),
        "accessibilityTraits": String(bare.accessibilityTraits.rawValue),
        "accessibilityElementsHidden": bare.accessibilityElementsHidden,
        "accessibilityViewIsModal": bare.accessibilityViewIsModal,
        "shouldGroupAccessibilityChildren": bare.shouldGroupAccessibilityChildren,
        "accessibilityNavigationStyle": bare.accessibilityNavigationStyle.rawValue,
        "accessibilityElements.isNil": bare.accessibilityElements == nil,
    ]

    // (3) The same properties round-tripping on a bare NSObject, and staying
    // independent per object.
    let a = NSObject(), b = NSObject()
    a.accessibilityLabel = "alpha"
    a.isAccessibilityElement = true
    a.accessibilityTraits = .button
    a.accessibilityElementsHidden = true
    a.shouldGroupAccessibilityChildren = true
    rows["nsobject.roundtrip"] = [
        "a.label": str(a.accessibilityLabel),
        "a.isElement": a.isAccessibilityElement,
        "a.traits": String(a.accessibilityTraits.rawValue),
        "a.elementsHidden": a.accessibilityElementsHidden,
        "a.groupsChildren": a.shouldGroupAccessibilityChildren,
        "b.label.isNil": b.accessibilityLabel == nil,
        "b.isElement": b.isAccessibilityElement,
    ]

    // (4) Non-view NSObjects UIKit ships: the properties are reachable there
    // too, which is the whole point of putting them on the root class.
    let bbi = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    bbi.accessibilityLabel = "back-button"
    bbi.accessibilityIdentifier = "nav.back"
    let navItem = UINavigationItem(title: "Root")
    navItem.accessibilityLabel = "root-item"
    let layer = CALayer()
    layer.accessibilityLabel = "layer"
    let para = NSMutableParagraphStyle()
    para.accessibilityValue = "para"
    rows["nonview.roundtrip"] = [
        "UIBarButtonItem.accessibilityLabel": str(bbi.accessibilityLabel),
        "UIBarButtonItem.accessibilityIdentifier": str(bbi.accessibilityIdentifier),
        "UINavigationItem.accessibilityLabel": str(navItem.accessibilityLabel),
        "CALayer.accessibilityLabel": str(layer.accessibilityLabel),
        "NSMutableParagraphStyle.accessibilityValue": str(para.accessibilityValue),
    ]

    // (5) UIBarItem defaults, read through both concrete subclasses.
    func barItemDefaults(_ item: UIBarItem) -> [String: Any] {
        [
            "isEnabled": item.isEnabled,
            "title": str(item.title),
            "image.isNil": item.image == nil,
            "landscapeImagePhone.isNil": item.landscapeImagePhone == nil,
            "largeContentSizeImage.isNil": item.largeContentSizeImage == nil,
            "imageInsets": [item.imageInsets.top, item.imageInsets.left,
                            item.imageInsets.bottom, item.imageInsets.right]
                .map(Double.init),
            "landscapeImagePhoneInsets": [item.landscapeImagePhoneInsets.top,
                                          item.landscapeImagePhoneInsets.left,
                                          item.landscapeImagePhoneInsets.bottom,
                                          item.landscapeImagePhoneInsets.right]
                .map(Double.init),
            "tag": item.tag,
            "titleTextAttributes(.normal).isNil":
                item.titleTextAttributes(for: .normal) == nil,
            "accessibilityIdentifier.isNil": item.accessibilityIdentifier == nil,
        ]
    }
    rows["UIBarButtonItem.defaults"] = barItemDefaults(UIBarButtonItem())
    rows["UITabBarItem.defaults"] =
        barItemDefaults(UITabBarItem(title: "Home", image: nil, tag: 3))

    let tabItem = UITabBarItem(title: "Home", image: nil, tag: 3)
    rows["UITabBarItem.inherited"] = [
        "title": str(tabItem.title),
        "tag": tabItem.tag,
        "isEnabled": tabItem.isEnabled,
        "selectedImage.isNil": tabItem.selectedImage == nil,
        "titlePositionAdjustment": [Double(tabItem.titlePositionAdjustment.horizontal),
                                    Double(tabItem.titlePositionAdjustment.vertical)],
    ]

    // UIBarButtonItem's per-state / per-metrics appearance defaults.
    let plain = UIBarButtonItem()
    rows["UIBarButtonItem.appearanceDefaults"] = [
        "backgroundImage(.normal, .default).isNil":
            plain.backgroundImage(for: .normal, barMetrics: .default) == nil,
        "backgroundImage(.normal, .plain, .default).isNil":
            plain.backgroundImage(for: .normal, style: .plain,
                                  barMetrics: .default) == nil,
        "backgroundVerticalPositionAdjustment(.default)":
            Double(plain.backgroundVerticalPositionAdjustment(for: .default)),
        "titlePositionAdjustment(.default)":
            [Double(plain.titlePositionAdjustment(for: .default).horizontal),
             Double(plain.titlePositionAdjustment(for: .default).vertical)],
        "backButtonBackgroundImage(.normal, .default).isNil":
            plain.backButtonBackgroundImage(for: .normal,
                                            barMetrics: .default) == nil,
        "backButtonTitlePositionAdjustment(.default)":
            [Double(plain.backButtonTitlePositionAdjustment(for: .default).horizontal),
             Double(plain.backButtonTitlePositionAdjustment(for: .default).vertical)],
        "backButtonBackgroundVerticalPositionAdjustment(.default)":
            Double(plain.backButtonBackgroundVerticalPositionAdjustment(for: .default)),
        "possibleTitles.isNil": plain.possibleTitles == nil,
    ]

    // Round-trip of the same appearance surface.
    let img = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        .image { _ in UIColor.red.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 2, height: 2)) }
    let styled = UIBarButtonItem()
    styled.setBackgroundImage(img, for: .normal, barMetrics: .default)
    styled.setTitlePositionAdjustment(UIOffset(horizontal: 3, vertical: -4),
                                      for: .default)
    styled.setBackgroundVerticalPositionAdjustment(7, for: .default)
    styled.possibleTitles = ["One", "Two"]
    rows["UIBarButtonItem.appearanceRoundtrip"] = [
        "backgroundImage(.normal, .default).size":
            styled.backgroundImage(for: .normal, barMetrics: .default)
                .map { [Double($0.size.width), Double($0.size.height)] } ?? NSNull(),
        "backgroundImage(.normal, .compact).isNil":
            styled.backgroundImage(for: .normal, barMetrics: .compact) == nil,
        "titlePositionAdjustment(.default)":
            [Double(styled.titlePositionAdjustment(for: .default).horizontal),
             Double(styled.titlePositionAdjustment(for: .default).vertical)],
        "titlePositionAdjustment(.compact)":
            [Double(styled.titlePositionAdjustment(for: .compact).horizontal),
             Double(styled.titlePositionAdjustment(for: .compact).vertical)],
        "backgroundVerticalPositionAdjustment(.default)":
            Double(styled.backgroundVerticalPositionAdjustment(for: .default)),
        "possibleTitles": (styled.possibleTitles.map { Array($0).sorted() }) ?? [],
    ]

    // (6) CALayer members the Prelude lenses require.
    let l = CALayer()
    rows["CALayer.defaults"] = [
        "shouldRasterize": l.shouldRasterize,
        "rasterizationScale": Double(l.rasterizationScale),
        "masksToBounds": l.masksToBounds,
        "borderWidth": Double(l.borderWidth),
        "cornerRadius": Double(l.cornerRadius),
        "shadowOpacity": Double(l.shadowOpacity),
        "shadowRadius": Double(l.shadowRadius),
        "shadowOffset": [Double(l.shadowOffset.width), Double(l.shadowOffset.height)],
        "borderColor.isNil": l.borderColor == nil,
        "shadowColor.isNil": l.shadowColor == nil,
    ]

    // (7) Paragraph-style value semantics.
    let p1 = NSMutableParagraphStyle()
    p1.alignment = .center
    p1.lineSpacing = 6
    p1.tailIndent = -12
    let p2 = p1.mutableCopy() as! NSMutableParagraphStyle
    let p3 = p1.copy() as! NSParagraphStyle
    rows["NSParagraphStyle.value"] = [
        "mutableCopy.class": NSStringFromClass(type(of: p2)),
        "copy.class": NSStringFromClass(type(of: p3)),
        "p1.isEqual(p2)": p1.isEqual(p2),
        "p1 == p2": p1 == p2,
        "hash.equal": p1.hash == p2.hash,
        // If NSObject's isEqual/hash are the Hashable witnesses, two
        // equal-valued styles collapse to ONE element.
        "set.count.equalValues": Set([p1 as NSParagraphStyle, p2 as NSParagraphStyle]).count,
        "identity.p1===p2": p1 === p2,
    ]
    p2.lineSpacing = 7
    rows["NSParagraphStyle.value.afterMutation"] = [
        "p1.isEqual(p2)": p1.isEqual(p2),
        "p1 == p2": p1 == p2,
        "set.count": Set([p1 as NSParagraphStyle, p2 as NSParagraphStyle]).count,
        "p1.lineSpacing": Double(p1.lineSpacing),
        "p2.lineSpacing": Double(p2.lineSpacing),
    ]
    rows["NSParagraphStyle.default"] = [
        "alignment": NSParagraphStyle.default.alignment.rawValue,
        "lineSpacing": Double(NSParagraphStyle.default.lineSpacing),
        "lineBreakMode": NSParagraphStyle.default.lineBreakMode.rawValue,
        "hyphenationFactor": Double(NSParagraphStyle.default.hyphenationFactor),
    ]
}

func marker(_ name: String) {
    FileManager.default.createFile(
        atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data())
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            measure()
            let data = try! JSONSerialization.data(
                withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
            try! data.write(to: URL(fileURLWithPath:
                NSHomeDirectory() + "/Documents/nsobject-value.json"))
            marker("done")
        }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
