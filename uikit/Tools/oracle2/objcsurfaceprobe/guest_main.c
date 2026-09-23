/* Driver for the Foundation-free variant of the surface scenario
 * (OUK_NO_FOUNDATION): plain C, so the same file runs on the iOS 26.1
 * simulator (run.sh, transcript-guest-ios26.1.txt) and under machorun on
 * Linux against OpenUIKit (scripts/objc_surface_guest_probe.sh). */
#include <stdio.h>
#include "OUKSurfaceScenario.h"

static void print(const char *line, void *context) { (void)context; printf("%s\n", line); }

int main(void) {
    printf("## superclasses\n");
    OUKSurfaceSuperclassFacts(print, 0);
    printf("## font\n");
    OUKSurfaceFontScenario(print, 0);
    printf("## layer\n");
    OUKSurfaceLayerScenario(print, 0);
    printf("## layersubclass\n");
    OUKSurfaceLayerSubclassScenario(print, 0);
    printf("## end\n");
    fflush(stdout);
    return 0;
}
