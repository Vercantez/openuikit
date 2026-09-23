// NSRange as in the iOS 26.1 SDK. Objective-C/C only: Swift code uses the
// facade's NSRange (OpenUIKit.NSRange), a Swift struct a Clang declaration
// cannot name, so Objective-C methods taking NSRange are not imported into
// Swift (a documented wall, docs/agent_reports/guest-objc-foundation.md).
#ifndef OF_FOUNDATION_NSRANGE_H
#define OF_FOUNDATION_NSRANGE_H

#import <Foundation/NSObjCRuntime.h>

#if !defined(__swift__)
typedef struct _NSRange {
    NSUInteger location;
    NSUInteger length;
} NSRange;

typedef NSRange *NSRangePointer;

NS_INLINE NSRange NSMakeRange(NSUInteger loc, NSUInteger len) {
    NSRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE NSUInteger NSMaxRange(NSRange range) {
    return (range.location + range.length);
}

NS_INLINE BOOL NSLocationInRange(NSUInteger loc, NSRange range) {
    return (!(loc < range.location) && (loc - range.location) < range.length) ? YES : NO;
}

NS_INLINE BOOL NSEqualRanges(NSRange range1, NSRange range2) {
    return (range1.location == range2.location && range1.length == range2.length);
}

@class NSString;
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *NSStringFromRange(NSRange range);
FOUNDATION_EXPORT NSRange NSRangeFromString(NSString *aString);
NS_ASSUME_NONNULL_END
#endif

#endif
