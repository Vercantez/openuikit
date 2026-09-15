import Social

// Focused service-type constant tests for coverage evidence.
// Each test is a top-level synchronous no-argument `func test*()` that
// references exactly one SLServiceType identifier. Values below are pinned
// by the Apple oracle probe in
// scratch/oracle-2026-09-14/social-service-types-2026-09-15.txt
// (macOS SDK runtime printout, 2026-09-15).
// No DispatchQueue.main, RunLoop, semaphore waits, or await: the sealed
// Linux gate hangs on those.

func testSLServiceTypeTwitter() {
    precondition(SLServiceTypeTwitter == "com.apple.social.twitter")
    precondition(SLServiceTypeTwitter.hasPrefix("com.apple.social."))
    precondition(!SLServiceTypeTwitter.isEmpty)
}

func testSLServiceTypeFacebook() {
    precondition(SLServiceTypeFacebook == "com.apple.social.facebook")
    precondition(SLServiceTypeFacebook.hasPrefix("com.apple.social."))
    precondition(!SLServiceTypeFacebook.isEmpty)
}

func testSLServiceTypeSinaWeibo() {
    precondition(SLServiceTypeSinaWeibo == "com.apple.social.sinaweibo")
    precondition(SLServiceTypeSinaWeibo.hasPrefix("com.apple.social."))
    precondition(!SLServiceTypeSinaWeibo.isEmpty)
}

func testSLServiceTypeTencentWeibo() {
    precondition(SLServiceTypeTencentWeibo == "com.apple.social.tencentweibo")
    precondition(SLServiceTypeTencentWeibo.hasPrefix("com.apple.social."))
    precondition(!SLServiceTypeTencentWeibo.isEmpty)
}

func testSLServiceTypeLinkedIn() {
    precondition(SLServiceTypeLinkedIn == "com.apple.social.linkedin")
    precondition(SLServiceTypeLinkedIn.hasPrefix("com.apple.social."))
    precondition(!SLServiceTypeLinkedIn.isEmpty)
}

func testSLServiceTypesAreDistinct() {
    let all = [
        SLServiceTypeTwitter,
        SLServiceTypeFacebook,
        SLServiceTypeSinaWeibo,
        SLServiceTypeTencentWeibo,
        SLServiceTypeLinkedIn,
    ]
    precondition(Set(all).count == all.count)
}

testSLServiceTypeTwitter()
testSLServiceTypeFacebook()
testSLServiceTypeSinaWeibo()
testSLServiceTypeTencentWeibo()
testSLServiceTypeLinkedIn()
testSLServiceTypesAreDistinct()
print("SOCIAL_SERVICE_TYPES_TESTS_OK")
