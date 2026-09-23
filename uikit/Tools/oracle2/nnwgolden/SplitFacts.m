// Measurement-only: after OPENUIKIT_SPLITFACTS_DELAY seconds (default 15),
// NSLog the storyboard-decoded UISplitViewController facts of the key
// window's root (NetNewsWire Main.storyboard RootSplitViewController:
// UISplitViewControllerStyle = 2 and three archived children). Reads only.
#import <UIKit/UIKit.h>

static NSString *OUKName(UIViewController *vc) {
    if (!vc) return @"nil";
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UIViewController *top = ((UINavigationController *)vc).viewControllers.firstObject;
        return [NSString stringWithFormat:@"%@(root=%@)", NSStringFromClass([vc class]), NSStringFromClass([top class])];
    }
    return NSStringFromClass([vc class]);
}

__attribute__((constructor)) static void OUKSplitFactsInstall(void) {
    NSDictionary *env = NSProcessInfo.processInfo.environment;
    if (!env[@"OPENUIKIT_SPLITFACTS"]) return;
    double delay = env[@"OPENUIKIT_SPLITFACTS_DELAY"] ? [env[@"OPENUIKIT_SPLITFACTS_DELAY"] doubleValue] : 15;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *key = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
            for (UIWindow *w in ((UIWindowScene *)scene).windows) if (w.isKeyWindow) key = w;
        UISplitViewController *split = (UISplitViewController *)key.rootViewController;
        if (![split isKindOfClass:[UISplitViewController class]]) { NSLog(@"SPLITFACT root=%@", NSStringFromClass([split class])); return; }
        NSLog(@"SPLITFACT class=%@ style=%ld collapsed=%d displayMode=%ld preferredDisplayMode=%ld preferredSplitBehavior=%ld primaryBackgroundStyle=%ld primaryEdge=%ld",
              NSStringFromClass([split class]), (long)split.style, split.isCollapsed, (long)split.displayMode,
              (long)split.preferredDisplayMode, (long)split.preferredSplitBehavior,
              (long)split.primaryBackgroundStyle, (long)split.primaryEdge);
        NSLog(@"SPLITFACT primary=%@ supplementary=%@ secondary=%@ compact=%@",
              OUKName([split viewControllerForColumn:UISplitViewControllerColumnPrimary]),
              OUKName([split viewControllerForColumn:UISplitViewControllerColumnSupplementary]),
              OUKName([split viewControllerForColumn:UISplitViewControllerColumnSecondary]),
              OUKName([split viewControllerForColumn:UISplitViewControllerColumnCompact]));
        NSMutableArray *kids = [NSMutableArray array];
        for (UIViewController *c in split.childViewControllers) [kids addObject:OUKName(c)];
        NSMutableArray *vcs = [NSMutableArray array];
        for (UIViewController *c in split.viewControllers) [vcs addObject:OUKName(c)];
        NSLog(@"SPLITFACT children=%@ viewControllers=%@", [kids componentsJoinedByString:@","], [vcs componentsJoinedByString:@","]);
    });
}
