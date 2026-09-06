#import <Foundation/Foundation.h>
extern void FocusOracleStart(void);
__attribute__((constructor)) static void bootstrapFocusOracle(void) {
    @autoreleasepool { FocusOracleStart(); }
}
