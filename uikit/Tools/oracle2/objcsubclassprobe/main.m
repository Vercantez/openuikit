// Oracle driver: run the shared scenario against Apple's UIKit and print it.
#import <UIKit/UIKit.h>
#import "OUKSubclassScenario.h"

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# objcsubclassprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## superclasses\n");
        for (NSString *line in OUKSuperclassFacts()) printf("%s\n", line.UTF8String);
        printf("## trace\n");
        for (NSString *line in OUKRunSubclassScenarios()) printf("%s\n", line.UTF8String);
    }
    return 0;
}
