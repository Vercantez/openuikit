#import <objc/NSObject.h>
#import <objc/runtime.h>
#include <stdio.h>
extern void __CFInitialize(void);
int main(void) {
    __CFInitialize();
    const char *names[] = {"__NSCFString","__NSCFArray","__NSCFDictionary",
                           "__NSCFSet","__NSCFConstantString","NSURL"};
    for (int i = 0; i < 6; i++) {
        Class c = objc_getClass(names[i]);
        Class s = c ? class_getSuperclass(c) : NULL;
        printf("  %-24s -> %s\n", names[i], s ? class_getName(s) : (c ? "(root)" : "(absent)"));
    }
    /* Are any of the six connectNSBaseClasses re-parents even present here? */
    const char *six[] = {"NSString","NSArray","NSMutableArray","NSDictionary","NSSet","NSEnumerator"};
    printf("  --- the six connectNSBaseClasses re-parents:\n");
    for (int i = 0; i < 6; i++)
        printf("  %-24s %s\n", six[i], objc_getClass(six[i]) ? "PRESENT" : "absent");
    return 0;
}
