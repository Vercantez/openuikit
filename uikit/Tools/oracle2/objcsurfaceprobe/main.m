// Oracle driver: run the shared surface scenario against Apple's UIKit.
#import <UIKit/UIKit.h>
#import "OUKSurfaceScenario.h"

static void print(const char *line, void *context) { printf("%s\n", line); }

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# objcsurfaceprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## superclasses\n");
        OUKSurfaceSuperclassFacts(print, NULL);
        printf("## font\n");
        OUKSurfaceFontScenario(print, NULL);
        printf("## layer\n");
        OUKSurfaceLayerScenario(print, NULL);
        printf("## layersubclass\n");
        OUKSurfaceLayerSubclassScenario(print, NULL);
        printf("## cgcolor\n");
        OUKSurfaceColorScenario(print, NULL);
        // Measured, not compared: identity/caching (apps must not rely on it).
        printf("## identity\n");
        UIFont *a = [UIFont systemFontOfSize:17], *b = [UIFont systemFontOfSize:17];
        printf("systemFontOfSize:17 twice identical=%s concrete=%s\n", a == b ? "YES" : "NO",
               NSStringFromClass([a class]).UTF8String);
        printf("copy identical=%s\n", [a copy] == a ? "YES" : "NO");
        printf("preferredFontForTextStyle:body isEqual systemFontOfSize:17=%s pointSize=%g fontName=%s\n",
               [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] isEqual:a] ? "YES" : "NO",
               [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize,
               [UIFont preferredFontForTextStyle:UIFontTextStyleBody].fontName.UTF8String);
        printf("italicSystemFontOfSize:17 fontName=%s\n", [UIFont italicSystemFontOfSize:17].fontName.UTF8String);
        printf("hash sys17=%lu sys18=%lu bold17=%lu\n", (unsigned long)a.hash,
               (unsigned long)[UIFont systemFontOfSize:18].hash, (unsigned long)[UIFont boldSystemFontOfSize:17].hash);
        printf("UIView.layer class=%s CAShapeLayer:%s CAGradientLayer:%s\n",
               NSStringFromClass([[UIView new].layer class]).UTF8String,
               NSStringFromClass([CAShapeLayer superclass]).UTF8String,
               NSStringFromClass([CAGradientLayer superclass]).UTF8String);
    }
    return 0;
}
