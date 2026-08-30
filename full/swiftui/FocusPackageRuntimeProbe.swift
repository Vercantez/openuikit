// Project-owned runtime probe. Focus and SnapKit sources remain unchanged.
import Foundation
import FocusPackageBundleProvider
import Onboarding
import SnapKit
import UIKit

final class PlainObject {}

final class EqualObject: Hashable {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

    static func == (lhs: EqualObject, rhs: EqualObject) -> Bool {
        lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

private func fail(_ message: String) -> Never {
    fatalError("FAIL: " + message)
}

let first = PlainObject()
let second = PlainObject()
let identities = NSMutableSet()
identities.add(first)
identities.add(first)
identities.add(second)
guard identities.allObjects.count == 2 else {
    fail("class identity insertion")
}
identities.remove(first)
guard identities.allObjects.count == 1,
      identities.allObjects.contains(where: { ($0 as AnyObject) === second }) else {
    fail("class identity removal")
}

let values = NSMutableSet()
weak var retainedEqual: EqualObject?
do {
    let equalA = EqualObject(7)
    let equalB = EqualObject(7)
    retainedEqual = equalA
    values.add(equalA)
    values.add(equalB)
}
guard values.allObjects.count == 1,
      retainedEqual != nil,
      values.allObjects.contains(where: { ($0 as AnyObject) === retainedEqual }) else {
    fail("Hashable equality or first-object retention")
}
values.remove(EqualObject(7))
guard values.allObjects.isEmpty else {
    fail("Hashable equality removal")
}

let retainedIdentities = NSMutableSet()
weak var retainedIdentity: PlainObject?
do {
    let object = PlainObject()
    retainedIdentity = object
    retainedIdentities.add(object)
}
guard retainedIdentity != nil,
      retainedIdentities.allObjects.contains(where: {
          ($0 as AnyObject) === retainedIdentity
      }) else {
    fail("identity-keyed object retention")
}

let expectedBundlePath = CommandLine.arguments[1]
let main = Bundle.main
guard main.bundlePath == expectedBundlePath,
      main.bundleURL.path == expectedBundlePath,
      main.resourcePath == expectedBundlePath + "/Contents/Resources",
      main.resourceURL?.path == expectedBundlePath + "/Contents/Resources" else {
    fail("main bundle/resource root: " + main.bundlePath)
}
guard Bundle(path: "/definitely/not/a/real/focus-bundle") == nil else {
    fail("nonexistent Bundle(path:) must be nil")
}

let expectedSnapKitBundle = expectedBundlePath + "/SnapKit_SnapKit.bundle"
guard FocusSnapKitResourceProof.bundlePath == expectedSnapKitBundle,
      FocusSnapKitResourceProof.resourcePath == expectedSnapKitBundle,
      FocusSnapKitResourceProof.privacyManifestPath ==
        expectedSnapKitBundle + "/PrivacyInfo.xcprivacy",
      FocusSnapKitResourceProof.missingResourcePath == nil else {
    fail("SnapKit generated primary resource lookup")
}

let flatPath = CommandLine.arguments[2]
guard let flat = Bundle(path: flatPath),
      Bundle(url: URL(fileURLWithPath: flatPath)) != nil,
      flat.resourcePath == flatPath,
      flat.resourceURL?.path == flatPath else {
    fail("flat resource bundle")
}
guard flat.url(forResource: "present", withExtension: "txt")?.path ==
        flatPath + "/present.txt",
      flat.url(forResource: "missing", withExtension: "txt") == nil else {
    fail("bounded resource lookup")
}

guard Bundle(for: PlainObject.self).bundlePath == main.bundlePath else {
    fail("Bundle(for:) in executable image")
}
let providerPath = CommandLine.arguments[3]
let provider = Bundle(for: FocusPackageFrameworkFinder.self)
guard provider.bundlePath == providerPath,
      provider.resourcePath == providerPath + "/Resources",
      provider.url(
          forResource: "bundle-provider-marker",
          withExtension: "txt"
      )?.path == providerPath + "/Resources/bundle-provider-marker.txt" else {
    fail("Bundle(for:) dynamic framework image: " + provider.bundlePath)
}

var storedV2 = Set<ToolTipRoute>()
let v2 = OnboardingEventsHandlerV2(
    getShownTips: { storedV2 },
    setShownTips: { storedV2 = $0 }
)
v2.send(.applicationDidLaunch)
guard v2.route == .onboarding(.v2), storedV2 == [.onboarding(.v2)] else {
    fail("V2 first route/persistence")
}
v2.send(.applicationDidLaunch)
guard storedV2.count == 1 else {
    fail("V2 duplicate suppression")
}
v2.send(.clearTapped)
guard v2.route == .widget, storedV2.contains(.widget) else {
    fail("V2 widget route")
}

var storedV1 = Set<ToolTipRoute>()
let v1 = OnboardingEventsHandlerV1(
    visitedURLcounter: 0,
    getShownTips: { storedV1 },
    setShownTips: { storedV1 = $0 }
)
v1.send(.startBrowsing)
v1.send(.startBrowsing)
guard v1.route == nil else {
    fail("V1 premature trash route")
}
v1.send(.startBrowsing)
guard v1.route == .trash(.v1), storedV1 == [.trash(.v1)] else {
    fail("V1 third-visit route/persistence")
}

let snapView = UIView()
snapView.snp.makeConstraints { make in
    make.width.equalTo(42)
}
guard snapView.constraints.count == 1,
      snapView.constraints[0].constant == 42 else {
    fail("unchanged SnapKit associated set activation")
}
snapView.snp.removeConstraints()
guard snapView.constraints.isEmpty else {
    fail("unchanged SnapKit associated set removal")
}

print("FOCUS_PACKAGE_FOUNDATION_OK bundle=main,flat,dynamic resource=url")
print("FOCUS_PACKAGE_PUBLISHED_OK handlers=v1,v2")
print(
    "FOCUS_PACKAGE_SNAPKIT_OK "
        + "lifecycle=add,remove set=identity,equality,retention resource=privacy"
)
