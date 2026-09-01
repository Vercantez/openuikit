import Social

enum SocialFallbackIdentityNegative {
    static func proveStandaloneFallbacks() {
        _ = Social.UIView.self
        _ = Social.UIViewController.self
        _ = Social.UIImage.self
        _ = Social.UITextView.self
        _ = Social.UITextViewDelegate.self
        _ = Social.ACAccount.self
    }
}
