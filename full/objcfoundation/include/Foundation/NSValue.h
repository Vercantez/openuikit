// NSValue / NSNumber = the Swift facade's Foundation.NSValue and
// Foundation.NSNumber (bridged to Swift's numeric types).
#ifndef OF_FOUNDATION_NSVALUE_H
#define OF_FOUNDATION_NSVALUE_H

#import <Foundation/NSObject.h>

@class NSString;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation7NSValue", "Foundation")
@interface NSValue : NSObject
#if !defined(__swift__)
+ (NSValue *)valueWithNonretainedObject:(nullable id)anObject;
@property (nullable, readonly) id nonretainedObjectValue;
+ (NSValue *)valueWithPointer:(nullable const void *)pointer;
@property (nullable, readonly) void *pointerValue;
- (BOOL)isEqualToValue:(NSValue *)value;
#endif
@end

// The SDK derives NSNumber from NSValue; the facade's NSNumber derives from
// NSObject, and the declaration follows the runtime class, not the SDK.
OF_SWIFT_CLASS("_TtC10Foundation8NSNumber", "Foundation")
@interface NSNumber : NSObject
#if !defined(__swift__)
- (NSNumber *)initWithChar:(char)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedChar:(unsigned char)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithShort:(short)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedShort:(unsigned short)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithInt:(int)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedInt:(unsigned int)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithLong:(long)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedLong:(unsigned long)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithLongLong:(long long)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedLongLong:(unsigned long long)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithFloat:(float)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithDouble:(double)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithBool:(BOOL)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithInteger:(NSInteger)value NS_DESIGNATED_INITIALIZER;
- (NSNumber *)initWithUnsignedInteger:(NSUInteger)value NS_DESIGNATED_INITIALIZER;

@property (readonly) char charValue;
@property (readonly) unsigned char unsignedCharValue;
@property (readonly) short shortValue;
@property (readonly) unsigned short unsignedShortValue;
@property (readonly) int intValue;
@property (readonly) unsigned int unsignedIntValue;
@property (readonly) long longValue;
@property (readonly) unsigned long unsignedLongValue;
@property (readonly) long long longLongValue;
@property (readonly) unsigned long long unsignedLongLongValue;
@property (readonly) float floatValue;
@property (readonly) double doubleValue;
@property (readonly) BOOL boolValue;
@property (readonly) NSInteger integerValue;
@property (readonly) NSUInteger unsignedIntegerValue;
@property (readonly, copy) NSString *stringValue;
@property (readonly) const char *objCType NS_RETURNS_INNER_POINTER;

- (NSComparisonResult)compare:(NSNumber *)otherNumber;
- (BOOL)isEqualToNumber:(NSNumber *)number;
@property (readonly, copy) NSString *description;

+ (NSNumber *)numberWithChar:(char)value;
+ (NSNumber *)numberWithUnsignedChar:(unsigned char)value;
+ (NSNumber *)numberWithShort:(short)value;
+ (NSNumber *)numberWithUnsignedShort:(unsigned short)value;
+ (NSNumber *)numberWithInt:(int)value;
+ (NSNumber *)numberWithUnsignedInt:(unsigned int)value;
+ (NSNumber *)numberWithLong:(long)value;
+ (NSNumber *)numberWithUnsignedLong:(unsigned long)value;
+ (NSNumber *)numberWithLongLong:(long long)value;
+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)value;
+ (NSNumber *)numberWithFloat:(float)value;
+ (NSNumber *)numberWithDouble:(double)value;
+ (NSNumber *)numberWithBool:(BOOL)value;
+ (NSNumber *)numberWithInteger:(NSInteger)value;
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
