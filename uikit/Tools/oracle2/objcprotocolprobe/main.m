// Oracle driver: run the shared protocol scenario against Apple's UIKit.
#import <UIKit/UIKit.h>
#import "OUKProtocolScenario.h"

static void print(const char *line, void *context) { printf("%s\n", line); }

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# objcprotocolprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## scroll\n");
        OUKProtocolScrollScenario(print, NULL);
        printf("## table\n");
        OUKProtocolTableScenario(print, NULL);
    }
    return 0;
}
