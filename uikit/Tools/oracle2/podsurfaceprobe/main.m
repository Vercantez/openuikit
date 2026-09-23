// Oracle driver: run the shared pod-surface scenario against Apple's UIKit.
#import <UIKit/UIKit.h>
#import "OUKPodSurfaceScenario.h"

static void print(const char *line, void *context) { printf("%s\n", line); }

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# podsurfaceprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        for (int i = 0; OUKPodSurfaceSection(i); i++) {
            const char *name = OUKPodSurfaceSection(i);
            printf("## %s\n", name);
            OUKPodSurfaceRun(name, print, NULL);
        }
    }
    return 0;
}
