// NSObject and the copying / fast-enumeration contracts.
#ifndef OF_FOUNDATION_NSOBJECT_H
#define OF_FOUNDATION_NSOBJECT_H

#import <Foundation/NSObjCRuntime.h>
#import <objc/NSObject.h>
#import <objc/runtime.h>

#if !defined(__swift__)
typedef struct _NSZone NSZone;  // Swift: ObjectiveC.NSZone
#endif

typedef struct {
    unsigned long state;
    id __unsafe_unretained _Nullable * _Nullable itemsPtr;
    unsigned long * _Nullable mutationsPtr;
    unsigned long extra[5];
} NSFastEnumerationState;

// The facade declares NSCopying as a Swift protocol; these Objective-C
// protocols exist for Objective-C conformance clauses only.
#if !defined(__swift__)
@protocol NSCopying
- (id)copyWithZone:(nullable NSZone *)zone;
@end

@protocol NSMutableCopying
- (id)mutableCopyWithZone:(nullable NSZone *)zone;
@end

@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
@end

@protocol NSCoding
@end
@protocol NSSecureCoding <NSCoding>
@end
#endif

#endif
