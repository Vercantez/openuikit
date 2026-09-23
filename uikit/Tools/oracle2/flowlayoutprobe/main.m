// Oracle driver: run the shared scenario against Apple's UIKit and print it.
#import <UIKit/UIKit.h>
#import "OUKFlowLayoutScenario.h"

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# flowlayoutprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## trace\n");
        for (NSString *line in OUKRunFlowLayoutScenario()) printf("%s\n", line.UTF8String);
    }
    return 0;
}
