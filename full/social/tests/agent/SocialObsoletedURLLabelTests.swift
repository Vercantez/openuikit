@_spi(OpenUIKitHost) import Social

// Exercised coverage for the Swift-3-obsoleted `URL:`-label spelling
// (precise:
// c:objc(cs)SLRequest(cm)requestForServiceType:requestMethod:URL:parameters:::SYNTHESIZED::c:objc(cs)SLRequest).
// Darwin obsoletes this spelling in Swift 3+; Linux keeps it as a `@nonobjc`
// Swift-only shim over the same stored behavior. This test calls the capital
// `URL:` label directly. No DispatchQueue.main, RunLoop, semaphore waits,
// or await: the sealed Linux gate hangs on those.

func testSLRequestObsoletedURLLabel() {
    let url = URL(string: "https://example.invalid/obsoleted-label")!
    let request = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        URL: url,
        parameters: ["status": "hello"]
    )
    precondition(request != nil)
    precondition(request!.requestMethod == .POST)
    precondition(request!.url == url)
    precondition((request!.parameters["status"] as? String) == "hello")
    precondition(request!.isolatedHostServiceType == SLServiceTypeTwitter)
    let prepared = request!.preparedURLRequest()
    precondition(prepared != nil)
    precondition(prepared!.httpMethod == "POST")
    precondition(prepared!.httpBody != nil)
}

func testSLRequestObsoletedURLLabelMatchesCanonical() {
    let url = URL(string: "https://example.invalid/label-parity")!
    let legacy = SLRequest(
        forServiceType: "parity",
        requestMethod: .GET,
        URL: url,
        parameters: ["q": "term"]
    )!
    let canonical = SLRequest(
        forServiceType: "parity",
        requestMethod: .GET,
        url: url,
        parameters: ["q": "term"]
    )!
    precondition(legacy.url == canonical.url)
    precondition(legacy.requestMethod == canonical.requestMethod)
    precondition(legacy.isolatedHostServiceType == canonical.isolatedHostServiceType)
    let legacyPrepared = legacy.preparedURLRequest()!
    let canonicalPrepared = canonical.preparedURLRequest()!
    precondition(legacyPrepared.httpMethod == canonicalPrepared.httpMethod)
    precondition(legacyPrepared.url == canonicalPrepared.url)
}

testSLRequestObsoletedURLLabel()
testSLRequestObsoletedURLLabelMatchesCanonical()
print("SOCIAL_OBSOLETED_URL_LABEL_TESTS_OK")
