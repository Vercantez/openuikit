// Oracle driver: run the shared SafariServices scenario against Apple's.
#import <UIKit/UIKit.h>
#import "OUKSafariScenario.h"

static void print(const char *line, void *context) { printf("%s\n", line); }

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# safariobjcprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## safari\n");
        OUKSafariScenario(print, NULL);
    }
    return 0;
}
