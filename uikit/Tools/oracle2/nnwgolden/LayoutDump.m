// Measurement-only layout dump for an unmodified app on the iOS simulator.
// Loaded with SIMCTL_CHILD_DYLD_INSERT_LIBRARIES; after
// OPENUIKIT_LAYOUTDUMP_DELAY seconds (default 8) it writes the key window's
// view tree to OPENUIKIT_LAYOUTDUMP_PATH as
//   {"screen": {"scale": s, "size": [w, h]},
//    "views": [{"path": "0.1.2", "class": ..., "frame": [x, y, w, h] (in the
//               superview), "window_frame": [x, y, w, h], "text": ...}]}
// It reads the hierarchy only: nothing in the app is changed.
#import <UIKit/UIKit.h>

static void OUKDump(UIView *view, NSString *path, UIWindow *window, NSMutableArray *out) {
    CGRect wf = [view convertRect:view.bounds toView:window];
    NSMutableDictionary *row = [@{
        @"path": path,
        @"class": NSStringFromClass([view class]),
        @"frame": @[@(view.frame.origin.x), @(view.frame.origin.y), @(view.frame.size.width), @(view.frame.size.height)],
        @"window_frame": @[@(wf.origin.x), @(wf.origin.y), @(wf.size.width), @(wf.size.height)],
        @"hidden": @(view.isHidden || view.alpha < 0.01),
    } mutableCopy];
    if ([view isKindOfClass:[UILabel class]]) {
        NSString *text = ((UILabel *)view).text;
        if (text) row[@"text"] = text;
    }
    [out addObject:row];
    NSUInteger i = 0;
    for (UIView *sub in view.subviews) {
        NSString *child = path.length ? [NSString stringWithFormat:@"%@.%lu", path, (unsigned long)i]
                                      : [NSString stringWithFormat:@"%lu", (unsigned long)i];
        OUKDump(sub, child, window, out);
        i++;
    }
}

__attribute__((constructor)) static void OUKLayoutDumpInstall(void) {
    NSDictionary *env = NSProcessInfo.processInfo.environment;
    NSString *outPath = env[@"OPENUIKIT_LAYOUTDUMP_PATH"];
    if (!outPath) return;
    double delay = env[@"OPENUIKIT_LAYOUTDUMP_DELAY"] ? [env[@"OPENUIKIT_LAYOUTDUMP_DELAY"] doubleValue] : 8;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *key = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                if (w.isKeyWindow) key = w;
            }
            if (!key) key = ((UIWindowScene *)scene).windows.firstObject;
        }
        if (!key) { NSLog(@"LAYOUTDUMP: no window"); return; }
        NSMutableArray *views = [NSMutableArray array];
        OUKDump(key, @"", key, views);
        NSDictionary *doc = @{
            @"screen": @{@"scale": @(key.screen.scale),
                         @"size": @[@(key.bounds.size.width), @(key.bounds.size.height)]},
            @"views": views,
        };
        NSData *data = [NSJSONSerialization dataWithJSONObject:doc options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:outPath atomically:YES];
        // The app's own window, as the other real-app goldens are taken
        // (drawHierarchy of the key window at the screen scale): system
        // chrome drawn outside the app process (status bar, home indicator)
        // is not part of it, exactly as it is not part of the port's render.
        NSString *pngPath = env[@"OPENUIKIT_WINDOWSHOT_PATH"];
        if (pngPath) {
            UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat formatForTraitCollection:key.traitCollection];
            format.scale = key.screen.scale;
            UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:key.bounds format:format];
            NSData *png = [renderer PNGDataWithActions:^(UIGraphicsImageRendererContext *ctx) {
                [key drawViewHierarchyInRect:key.bounds afterScreenUpdates:NO];
            }];
            [png writeToFile:pngPath atomically:YES];
            NSLog(@"WINDOWSHOT_WRITTEN %@", pngPath);
        }
        NSLog(@"LAYOUTDUMP_WRITTEN %@ %lu views", outPath, (unsigned long)views.count);
    });
}
