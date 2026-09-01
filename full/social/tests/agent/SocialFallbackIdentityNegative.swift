import Social

/// Compile-only consumer of fixture Social.UIKit/Accounts lookalikes.
/// Success here only proves the isolated -D SOCIAL_STANDALONE_TEST_FIXTURES
/// compile published those nominal types. It is not platform identity.
enum SocialFallbackIdentityNegative {
    static func proveStandaloneFallbacks() {
        _ = Social.UIView.self
        _ = Social.UIViewController.self
        _ = Social.UIImage.self
        _ = Social.UITextView.self
        _ = Social.UITextViewDelegate.self
        _ = Social.ACAccount.self
#if SOCIAL_STANDALONE_TEST_FIXTURES
        _ = SocialStandaloneUnitFixture.marker
#endif
    }
}
