#ifndef OPENUIKIT_FOUNDATION_NSOBJECT_H
#define OPENUIKIT_FOUNDATION_NSOBJECT_H

#import <objc/NSObject.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSZone.h>

@class NSCoder;

NS_ASSUME_NONNULL_BEGIN

@protocol NSCopying
- (id)copyWithZone:(NSZone * _Nullable)zone;
@end

@protocol NSMutableCopying
- (id)mutableCopyWithZone:(NSZone * _Nullable)zone;
@end

@protocol NSCoding
- (void)encodeWithCoder:(NSCoder *)coder;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;
@end

@protocol NSSecureCoding <NSCoding>
@required
+ (BOOL)supportsSecureCoding;
@end

NS_ASSUME_NONNULL_END

#endif
