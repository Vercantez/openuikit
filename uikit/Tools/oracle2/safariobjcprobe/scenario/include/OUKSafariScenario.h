/* OUKSafariScenario — SFSafariViewController from Objective-C, the way
 * NetNewsWire's SFSafariViewController+Extras.m uses it: `@import
 * SafariServices;` alone (no Foundation import), a category class method
 * that wraps `-initWithURL:` in @try/@catch, and nothing else. Run against
 * Apple's SafariServices (Tools/oracle2/safariobjcprobe/run.sh, iOS 26.1
 * simulator) and against OpenUIKit's (Tests/SafariObjCTests). */
@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

/* NetNewsWire's category shape, verbatim in kind. */
@interface SFSafariViewController (OUKSafariProbe)
+ (nullable SFSafariViewController *)ouk_safeSafariViewController:(NSURL *)url;
@end

typedef void (*OUKSafariSink)(const char *line, void *_Nullable context);
void OUKSafariScenario(OUKSafariSink sink, void *_Nullable context);

NS_ASSUME_NONNULL_END
