// Oracle driver: runs the shared protocol scenario inside a real iOS app
// (key window, first responders work), writes Documents/transcript.txt,
// and adds each protocol's SDK method list (name, required) for the shape
// check in Tests/ObjCProtocols2Tests.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "OUKProtocols2Scenario.h"

static NSMutableArray<NSString *> *gOut;
static void collect(const char *line, void *context) { [gOut addObject:@(line)]; }

static void shapes(void) {
    [gOut addObject:@"## shapes"];
    for (NSString *name in @[@"UITextFieldDelegate", @"UITextViewDelegate", @"UIGestureRecognizerDelegate",
                             @"UINavigationControllerDelegate", @"UIPickerViewDataSource", @"UIPickerViewDelegate",
                             @"UISearchBarDelegate", @"UISearchControllerDelegate", @"UITabBarDelegate",
                             @"UITabBarControllerDelegate", @"UICollectionViewDelegate", @"UITableViewDelegate"]) {
        Protocol *p = objc_getProtocol(name.UTF8String);
        NSMutableArray *rows = [NSMutableArray array];
        for (int required = 1; required >= 0; required--) {
            unsigned n = 0;
            struct objc_method_description *m = protocol_copyMethodDescriptionList(p, required, YES, &n);
            for (unsigned i = 0; i < n; i++)
                [rows addObject:[NSString stringWithFormat:@"%@ %@ %@", name, required ? @"required" : @"optional",
                                 NSStringFromSelector(m[i].name)]];
            free(m);
        }
        [gOut addObjectsFromArray:[rows sortedArrayUsingSelector:@selector(compare:)]];
    }
}

@interface ProbeApp : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation ProbeApp
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.whiteColor;
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        gOut = [NSMutableArray arrayWithObject:
                [NSString stringWithFormat:@"# objcprotocolprobe2 — iOS %@", UIDevice.currentDevice.systemVersion]];
        for (int i = 0; OUKProtocols2Section(i); i++) {
            [gOut addObject:[NSString stringWithFormat:@"## %s", OUKProtocols2Section(i)]];
            OUKProtocols2Run(OUKProtocols2Section(i), (__bridge void *)vc.view, collect, NULL);
        }
        shapes();
        NSString *text = [[gOut componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
        NSURL *url = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject
                      URLByAppendingPathComponent:@"transcript.txt"];
        [text writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
        printf("%s", text.UTF8String);
        exit(0);
    });
    return YES;
}
@end

int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ProbeApp class]));
    }
}
