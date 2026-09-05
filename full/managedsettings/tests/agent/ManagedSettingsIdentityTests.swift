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

func testApplicationBundleIdentifierInit() {
    let app = Application(bundleIdentifier: "com.example.app")
    precondition(app.bundleIdentifier == "com.example.app")
    precondition(app.token == nil)
    precondition(app.localizedDisplayName == nil)
}

func testApplicationTokenInit() {
    let token: ApplicationToken = linuxToken("11111111-1111-4111-8111-111111111111")
    let app = Application(token: token)
    precondition(app.token == token)
    precondition(app.bundleIdentifier == nil)
    precondition(app.localizedDisplayName == nil)
}

func testApplicationEquality() {
    let a = Application(bundleIdentifier: "com.a")
    let b = Application(bundleIdentifier: "com.a")
    let c = Application(bundleIdentifier: "com.c")
    precondition(a == b)
    precondition(a != c)
}

func testApplicationHash() {
    let app = Application(bundleIdentifier: "com.hash")
    var hasherA = Hasher()
    var hasherB = Hasher()
    app.hash(into: &hasherA)
    app.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(app.hashValue == app.hashValue)
}

func testApplicationInequality() {
    let token: ApplicationToken = linuxToken("22222222-2222-4222-8222-222222222222")
    precondition(Application(bundleIdentifier: "com.a") != Application(token: token))
}

func testWebDomainInit() {
    let domain = WebDomain(domain: "example.com")
    precondition(domain.domain == "example.com")
    precondition(domain.token == nil)
}

func testWebDomainTokenInit() {
    let token: WebDomainToken = linuxToken("33333333-3333-4333-8333-333333333333")
    let domain = WebDomain(token: token)
    precondition(domain.token == token)
    precondition(domain.domain == nil)
}

func testWebDomainEquality() {
    precondition(WebDomain(domain: "a.com") == WebDomain(domain: "a.com"))
    precondition(WebDomain(domain: "a.com") != WebDomain(domain: "b.com"))
}

func testWebDomainHash() {
    let domain = WebDomain(domain: "hash.example")
    var hasherA = Hasher()
    var hasherB = Hasher()
    domain.hash(into: &hasherA)
    domain.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(domain.hashValue == domain.hashValue)
}

func testWebDomainInequality() {
    let token: WebDomainToken = linuxToken("44444444-4444-4444-8444-444444444444")
    precondition(WebDomain(domain: "a.com") != WebDomain(token: token))
}

func testActivityCategoryTokenInit() {
    let token: ActivityCategoryToken = linuxToken("55555555-5555-4555-8555-555555555555")
    let category = ActivityCategory(token: token)
    precondition(category.token == token)
    precondition(category.localizedDisplayName == nil)
}

func testActivityCategoryEquality() {
    let token: ActivityCategoryToken = linuxToken("66666666-6666-4666-8666-666666666666")
    let other: ActivityCategoryToken = linuxToken("77777777-7777-4777-8777-777777777777")
    precondition(ActivityCategory(token: token) == ActivityCategory(token: token))
    precondition(ActivityCategory(token: token) != ActivityCategory(token: other))
}

func testActivityCategoryHash() {
    let token: ActivityCategoryToken = linuxToken("88888888-8888-4888-8888-888888888888")
    let category = ActivityCategory(token: token)
    var hasherA = Hasher()
    var hasherB = Hasher()
    category.hash(into: &hasherA)
    category.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(category.hashValue == category.hashValue)
}

func testActivityCategoryInequality() {
    let a: ActivityCategoryToken = linuxToken("99999999-9999-4999-8999-999999999999")
    let b: ActivityCategoryToken = linuxToken("AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE")
    precondition(ActivityCategory(token: a) != ActivityCategory(token: b))
}

func testTokenRoundTrip() {
    let original: ApplicationToken = linuxToken("C0FFEEEE-C0FF-4EEE-8EEE-C0FFEEEE0001")
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(ApplicationToken.self, from: encoded)
    precondition(decoded == original)
}

func testTokenDecodeFailClosed() {
    let appleShaped = Data("{\"token\":\"not-a-linux-payload\"}".utf8)
    do {
        _ = try JSONDecoder().decode(ApplicationToken.self, from: appleShaped)
        preconditionFailure("Apple-shaped token payload must fail closed")
    } catch is DecodingError {
        // expected
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testTokenEquality() {
    let a: WebDomainToken = linuxToken("DEADBEEF-0000-4000-8000-000000000001")
    let b: WebDomainToken = linuxToken("DEADBEEF-0000-4000-8000-000000000001")
    let c: WebDomainToken = linuxToken("DEADBEEF-0000-4000-8000-000000000002")
    precondition(a == b)
    precondition(a != c)
}

func testTokenHash() {
    let token: ActivityCategoryToken = linuxToken("FEEDFACE-0000-4000-8000-000000000001")
    var hasherA = Hasher()
    var hasherB = Hasher()
    token.hash(into: &hasherA)
    token.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(token.hashValue == token.hashValue)
}

func testTokenInequality() {
    let a: ApplicationToken = linuxToken("01010101-0101-4101-8101-010101010101")
    let b: ApplicationToken = linuxToken("02020202-0202-4202-8202-020202020202")
    precondition(a != b)
}

func testApplicationTokenAlias() {
    let token: ApplicationToken = linuxToken("A1A1A1A1-A1A1-41A1-81A1-A1A1A1A1A1A1")
    let typed: Token<Application> = token
    precondition(typed == token)
}

func testWebDomainTokenAlias() {
    let token: WebDomainToken = linuxToken("B2B2B2B2-B2B2-42B2-82B2-B2B2B2B2B2B2")
    let typed: Token<WebDomain> = token
    precondition(typed == token)
}

func testActivityCategoryTokenAlias() {
    let token: ActivityCategoryToken = linuxToken("C3C3C3C3-C3C3-43C3-83C3-C3C3C3C3C3C3")
    let typed: Token<ActivityCategory> = token
    precondition(typed == token)
}
