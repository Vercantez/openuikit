// Assertions (NSAssert and friends, as the iOS 26.1 SDK spells them) and
// NSAssertionHandler (FoundationObjCBridge). A failed assertion prints the
// SDK's "*** Assertion failure in ..." line and aborts: the guest has no
// Objective-C exception unwinding (@try/@catch is a documented wall), so the
// uncaught NSInternalInconsistencyException Apple raises ends the same way.
#ifndef OF_FOUNDATION_NSEXCEPTION_H
#define OF_FOUNDATION_NSEXCEPTION_H

#import <Foundation/NSObject.h>

@class NSString;

#if !defined(__swift__)
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const NSInternalInconsistencyException;
FOUNDATION_EXPORT NSString *const NSInvalidArgumentException;
FOUNDATION_EXPORT NSString *const NSRangeException;
NS_ASSUME_NONNULL_END
#endif

NS_ASSUME_NONNULL_BEGIN
OF_SWIFT_CLASS("_TtC20FoundationObjCBridge18NSAssertionHandler", "FoundationObjCBridge")
@interface NSAssertionHandler : NSObject
#if !defined(__swift__)
@property (class, readonly, strong) NSAssertionHandler *currentHandler;
- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(nullable NSString *)format, ... NS_FORMAT_FUNCTION(5, 6);
- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(nullable NSString *)format, ... NS_FORMAT_FUNCTION(4, 5);
#endif
@end
NS_ASSUME_NONNULL_END

#if !defined(__swift__)
#if !defined(NS_BLOCK_ASSERTIONS)
#define NSAssert(condition, desc, ...) \
    do { \
        if (__builtin_expect(!(condition), 0)) { \
            NSString *__assert_file__ = [NSString stringWithUTF8String:__FILE__]; \
            __assert_file__ = __assert_file__ ? __assert_file__ : @"<Unknown File>"; \
            [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:__assert_file__ \
                lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
        } \
    } while (0)
#define NSCAssert(condition, desc, ...) \
    do { \
        if (__builtin_expect(!(condition), 0)) { \
            NSString *__assert_fn__ = [NSString stringWithUTF8String:__PRETTY_FUNCTION__]; \
            __assert_fn__ = __assert_fn__ ? __assert_fn__ : @"<Unknown Function>"; \
            NSString *__assert_file__ = [NSString stringWithUTF8String:__FILE__]; \
            __assert_file__ = __assert_file__ ? __assert_file__ : @"<Unknown File>"; \
            [[NSAssertionHandler currentHandler] handleFailureInFunction:__assert_fn__ file:__assert_file__ \
                lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
        } \
    } while (0)
#else
#define NSAssert(condition, desc, ...) do {} while (0)
#define NSCAssert(condition, desc, ...) do {} while (0)
#endif
#define NSAssert1(c, d, a1) NSAssert((c), (d), (a1))
#define NSAssert2(c, d, a1, a2) NSAssert((c), (d), (a1), (a2))
#define NSCAssert1(c, d, a1) NSCAssert((c), (d), (a1))
#define NSParameterAssert(condition) NSAssert((condition), @"Invalid parameter not satisfying: %@", @#condition)
#define NSCParameterAssert(condition) NSCAssert((condition), @"Invalid parameter not satisfying: %@", @#condition)
#endif

#endif
