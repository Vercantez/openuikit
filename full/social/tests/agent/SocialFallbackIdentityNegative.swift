import Social

/// Compile-time probe for Social-owned UIKit/Accounts lookalikes.
///
/// With `-D SOCIAL_STANDALONE_TEST_FIXTURES`, `Social.ACAccount` is always a
/// fixture type. `Social.UIView*` exist only when UIKit is absent; on Apple
/// hosts the fixture compile consumes canonical UIKit instead.
enum SocialFallbackIdentityNegative {
    static func proveStandaloneFallbacks() {
#if SOCIAL_STANDALONE_TEST_FIXTURES
        _ = Social.ACAccount.self
        _ = SocialStandaloneUnitFixture.marker
#if !canImport(UIKit)
        _ = Social.UIView.self
        _ = Social.UIViewController.self
        _ = Social.UIImage.self
        _ = Social.UITextView.self
        _ = Social.UITextViewDelegate.self
#endif
#else
        _ = Social.UIView.self
        _ = Social.UIViewController.self
        _ = Social.UIImage.self
        _ = Social.UITextView.self
        _ = Social.UITextViewDelegate.self
        _ = Social.ACAccount.self
#endif
    }
}
