// See include/OUKSafariScenario.h.
#import "OUKSafariScenario.h"
#import <objc/runtime.h>
#include <stdio.h>

@implementation SFSafariViewController (OUKSafariProbe)
+ (nullable SFSafariViewController *)ouk_safeSafariViewController:(NSURL *)url {
    @try {
        return [[SFSafariViewController alloc] initWithURL:url];
    }
    @catch (NSException *exception) {
        return nil;
    }
}
@end

static OUKSafariSink gSink;
static void *gContext;

static void emit(NSString *line) { gSink(line.UTF8String, gContext); }

static NSString *attempt(NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    @try {
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
        return [NSString stringWithFormat:@"ok class=%s", class_getName([vc class])];
    }
    @catch (NSException *exception) {
        return [NSString stringWithFormat:@"raised %@", exception.name];
    }
}

void OUKSafariScenario(OUKSafariSink sink, void *context) {
    gSink = sink; gContext = context;
    emit([NSString stringWithFormat:@"superclass %s", class_getName(class_getSuperclass([SFSafariViewController class]))]);
    emit([NSString stringWithFormat:@"runtime name %s", class_getName([SFSafariViewController class])]);
    NSArray *urls = @[@"https://netnewswire.com/", @"http://example.com/a?b=c", @"HTTPS://EXAMPLE.COM/",
                      @"file:///tmp/x.html", @"mailto:someone@example.com", @"feed://example.com/rss",
                      @"netnewswire://open", @"about:blank", @"example.com"];
    for (NSString *u in urls) emit([NSString stringWithFormat:@"initWithURL %@ -> %@", u, attempt(u)]);
    // The category (class method added to SafariServices' class) and its
    // exception guard: nil for a URL the initializer rejects.
    SFSafariViewController *good = [SFSafariViewController ouk_safeSafariViewController:
                                    [NSURL URLWithString:@"https://netnewswire.com/"]];
    SFSafariViewController *bad = [SFSafariViewController ouk_safeSafariViewController:
                                   [NSURL URLWithString:@"mailto:someone@example.com"]];
    emit([NSString stringWithFormat:@"category https -> %@", good ? @"object" : @"nil"]);
    emit([NSString stringWithFormat:@"category mailto -> %@", bad ? @"object" : @"nil"]);
    emit([NSString stringWithFormat:@"respondsToSelector ouk_safeSafariViewController: %@",
          [SFSafariViewController respondsToSelector:@selector(ouk_safeSafariViewController:)] ? @"YES" : @"NO"]);
    if (good) {
        emit([NSString stringWithFormat:@"dismissButtonStyle %ld",
              (long)good.dismissButtonStyle]);
        emit([NSString stringWithFormat:@"configuration entersReaderIfAvailable %d barCollapsingEnabled %d",
              good.configuration.entersReaderIfAvailable, good.configuration.barCollapsingEnabled]);
    }
}
