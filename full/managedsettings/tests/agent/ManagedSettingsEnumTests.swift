import Foundation
import ManagedSettings

private func linuxToken<T>(_ uuid: String) -> Token<T> {
    let json = Data("{\"linuxOpaqueID\":\"\(uuid)\"}".utf8)
    do {
        return try JSONDecoder().decode(Token<T>.self, from: json)
    } catch {
        preconditionFailure("linux token decode failed: \(error)")
    }
}

func testShieldActionRawValues() {
    precondition(ShieldAction.primaryButtonPressed.rawValue == 0)
    precondition(ShieldAction.secondaryButtonPressed.rawValue == 1)
    precondition(ShieldAction(rawValue: 0) == .primaryButtonPressed)
    precondition(ShieldAction(rawValue: 1) == .secondaryButtonPressed)
    precondition(ShieldAction(rawValue: 2) == nil)
    let _: ShieldAction.RawValue = ShieldAction.primaryButtonPressed.rawValue
}

func testShieldActionInequalityAndHash() {
    precondition(ShieldAction.primaryButtonPressed != .secondaryButtonPressed)
    var hasherA = Hasher()
    var hasherB = Hasher()
    ShieldAction.primaryButtonPressed.hash(into: &hasherA)
    ShieldAction.primaryButtonPressed.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(ShieldAction.secondaryButtonPressed.hashValue == ShieldAction.secondaryButtonPressed.hashValue)
}

func testShieldActionResponseRawValues() {
    precondition(ShieldActionResponse.none.rawValue == 0)
    precondition(ShieldActionResponse.close.rawValue == 1)
    precondition(ShieldActionResponse.defer.rawValue == 2)
    precondition(ShieldActionResponse(rawValue: 0) == ShieldActionResponse.none)
    precondition(ShieldActionResponse(rawValue: 1) == .close)
    precondition(ShieldActionResponse(rawValue: 2) == .defer)
    precondition(ShieldActionResponse(rawValue: 3) == nil)
    let _: ShieldActionResponse.RawValue = ShieldActionResponse.close.rawValue
}

func testShieldActionResponseInequalityAndHash() {
    precondition(ShieldActionResponse.none != .close)
    precondition(ShieldActionResponse.close != .defer)
    var hasherA = Hasher()
    var hasherB = Hasher()
    ShieldActionResponse.none.hash(into: &hasherA)
    ShieldActionResponse.none.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(ShieldActionResponse.defer.hashValue == ShieldActionResponse.defer.hashValue)
}

func testCookiePolicyRawValues() {
    precondition(SafariSettings.CookiePolicy.never.rawValue == "never")
    precondition(SafariSettings.CookiePolicy.currentWebsite.rawValue == "currentWebsite")
    precondition(SafariSettings.CookiePolicy.visitedWebsites.rawValue == "visitedWebsites")
    precondition(SafariSettings.CookiePolicy.always.rawValue == "always")
    precondition(SafariSettings.CookiePolicy(rawValue: "never") == .never)
    precondition(SafariSettings.CookiePolicy(rawValue: "currentWebsite") == .currentWebsite)
    precondition(SafariSettings.CookiePolicy(rawValue: "visitedWebsites") == .visitedWebsites)
    precondition(SafariSettings.CookiePolicy(rawValue: "always") == .always)
    precondition(SafariSettings.CookiePolicy(rawValue: "Never") == nil)
    let _: SafariSettings.CookiePolicy.RawValue = SafariSettings.CookiePolicy.always.rawValue
}

func testCookiePolicyComparableOperators() {
    precondition(SafariSettings.CookiePolicy.never < .currentWebsite)
    precondition(SafariSettings.CookiePolicy.currentWebsite < .visitedWebsites)
    precondition(SafariSettings.CookiePolicy.visitedWebsites < .always)
    precondition(SafariSettings.CookiePolicy.always > .never)
    precondition(SafariSettings.CookiePolicy.always >= .always)
    precondition(SafariSettings.CookiePolicy.never <= .currentWebsite)
    precondition(!(SafariSettings.CookiePolicy.always < .never))
}

func testCookiePolicyClosedRange() {
    let closed = SafariSettings.CookiePolicy.never...SafariSettings.CookiePolicy.always
    precondition(closed.contains(.currentWebsite))
    precondition(closed.contains(.never))
    precondition(closed.contains(.always))
}

func testCookiePolicyHalfOpenRange() {
    let half = SafariSettings.CookiePolicy.never..<SafariSettings.CookiePolicy.always
    precondition(half.contains(.never))
    precondition(half.contains(.visitedWebsites))
    precondition(!half.contains(.always))
}

func testCookiePolicyPartialRangeFrom() {
    let from = SafariSettings.CookiePolicy.visitedWebsites...
    precondition(from.contains(.visitedWebsites))
    precondition(from.contains(.always))
    precondition(!from.contains(.never))
}

func testCookiePolicyPartialRangeThrough() {
    let through = ...SafariSettings.CookiePolicy.currentWebsite
    precondition(through.contains(.never))
    precondition(through.contains(.currentWebsite))
    precondition(!through.contains(.always))
}

func testCookiePolicyPartialRangeUpTo() {
    let upTo = ..<SafariSettings.CookiePolicy.visitedWebsites
    precondition(upTo.contains(.never))
    precondition(upTo.contains(.currentWebsite))
    precondition(!upTo.contains(.visitedWebsites))
}

func testCookiePolicyDescription() {
    precondition(SafariSettings.CookiePolicy.never.description == "never")
    precondition(String(describing: SafariSettings.CookiePolicy.always) == "always")
}

func testCookiePolicyInequalityAndHash() {
    precondition(SafariSettings.CookiePolicy.never != .always)
    var hasherA = Hasher()
    var hasherB = Hasher()
    SafariSettings.CookiePolicy.always.hash(into: &hasherA)
    SafariSettings.CookiePolicy.always.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(SafariSettings.CookiePolicy.never.hashValue == SafariSettings.CookiePolicy.never.hashValue)
}

func testFilterPolicyEquality() {
    let a = WebDomain(domain: "a.example")
    let b = WebDomain(domain: "b.example")
    precondition(WebContentSettings.FilterPolicy.none == .none)
    precondition(WebContentSettings.FilterPolicy.specific([a]) == .specific([a]))
    precondition(WebContentSettings.FilterPolicy.specific([a]) != .specific([b]))
    precondition(WebContentSettings.FilterPolicy.auto([a], except: [b]) == .auto([a], except: [b]))
    precondition(WebContentSettings.FilterPolicy.all(except: [a]) == .all(except: [a]))
    precondition(WebContentSettings.FilterPolicy.none != .specific([a]))
}

func testFilterPolicyAssociatedDefaults() {
    precondition(WebContentSettings.FilterPolicy.auto() == .auto([], except: []))
    precondition(WebContentSettings.FilterPolicy.all() == .all(except: []))
}

func testActivityCategoryPolicyEquality() {
    let cat = linuxToken("AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA") as ActivityCategoryToken
    let app = linuxToken("BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB") as ApplicationToken
    precondition(ShieldSettings.ActivityCategoryPolicy<Application>.none == .none)
    precondition(
        ShieldSettings.ActivityCategoryPolicy<Application>.all(except: [app])
            == .all(except: [app])
    )
    precondition(
        ShieldSettings.ActivityCategoryPolicy<Application>.specific([cat], except: [app])
            == .specific([cat], except: [app])
    )
    precondition(
        ShieldSettings.ActivityCategoryPolicy<Application>.none
            != .all(except: [])
    )
}

func testActivityCategoryPolicyDefaults() {
    precondition(ShieldSettings.ActivityCategoryPolicy<WebDomain>.all() == .all(except: []))
}

func testStoreNameRawRepresentable() {
    let name = ManagedSettingsStore.Name(rawValue: "family")
    precondition(name.rawValue == "family")
    let copy = ManagedSettingsStore.Name("family")
    precondition(copy == name)
    let _: ManagedSettingsStore.Name.RawValue = name.rawValue
}

func testStoreNameDefault() {
    precondition(ManagedSettingsStore.Name.default.rawValue == "default")
    precondition(ManagedSettingsStore.Name.default == ManagedSettingsStore.Name(rawValue: "default"))
}

func testStoreNameInequalityAndHash() {
    let a = ManagedSettingsStore.Name("one")
    let b = ManagedSettingsStore.Name("two")
    precondition(a != b)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    a.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == a.hashValue)
}
