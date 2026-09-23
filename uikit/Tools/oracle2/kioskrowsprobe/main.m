// Oracle driver: run the shared Kiosk-rows scenario against Apple's UIKit,
// inside UIApplicationMain (sharedApplication, a key window and first
// responders exist), after launch. Prints the transcript and exits.
#import <UIKit/UIKit.h>
#import "OUKKioskRowsScenario.h"

static void print(const char *line, void *context) { printf("%s\n", line); fflush(stdout); }

@interface OUKKioskRowsDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation OUKKioskRowsDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *font = [[NSBundle mainBundle] pathForResource:@"EBGaramond12-Regular" ofType:@"ttf"];
        OUKKioskRowsSetFontPath(font.fileSystemRepresentation);
        printf("# kioskrowsprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        for (int i = 0; OUKKioskRowsSection(i); i++) {
            const char *name = OUKKioskRowsSection(i);
            printf("## %s\n", name);
            OUKKioskRowsRun(name, print, NULL);
        }
        printf("DONE\n");
        fflush(stdout);
        exit(0);
    });
    return YES;
}
@end

int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([OUKKioskRowsDelegate class]));
    }
}
