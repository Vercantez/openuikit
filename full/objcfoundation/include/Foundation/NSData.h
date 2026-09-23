// NSData / NSMutableData = the Swift facade's classes (bridged to Data).
#ifndef OF_FOUNDATION_NSDATA_H
#define OF_FOUNDATION_NSDATA_H

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation6NSData", "Foundation")
__attribute__((swift_bridge("FoundationEssentials.Data")))
@interface NSData : NSObject
#if !defined(__swift__)
@property (readonly) NSUInteger length;
@property (readonly) const void *bytes NS_RETURNS_INNER_POINTER;
@property (readonly, copy) NSString *description;
- (void)getBytes:(void *)buffer length:(NSUInteger)length;
- (void)getBytes:(void *)buffer range:(NSRange)range;
- (BOOL)isEqualToData:(NSData *)other;
- (NSData *)subdataWithRange:(NSRange)range;
+ (instancetype)data;
+ (instancetype)dataWithBytes:(nullable const void *)bytes length:(NSUInteger)length;
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length;
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b;
+ (instancetype)dataWithData:(NSData *)data;
- (instancetype)initWithBytes:(nullable const void *)bytes length:(NSUInteger)length;
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b;
- (instancetype)initWithData:(NSData *)data;
#endif
@end

OF_SWIFT_CLASS("_TtC10Foundation13NSMutableData", "Foundation")
@interface NSMutableData : NSData
#if !defined(__swift__)
// -mutableBytes and a settable -length are not implemented: the facade's
// storage cannot hand out a writable interior pointer.
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
- (void)appendData:(NSData *)other;
+ (nullable instancetype)dataWithCapacity:(NSUInteger)aNumItems;
- (nullable instancetype)initWithCapacity:(NSUInteger)capacity;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
