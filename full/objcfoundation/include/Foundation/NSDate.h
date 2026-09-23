// NSDate: FoundationObjCBridge.NSDate, bridged to Foundation.Date.
#ifndef OF_FOUNDATION_NSDATE_H
#define OF_FOUNDATION_NSDATE_H

#import <Foundation/NSObject.h>

@class NSString;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge6NSDate", "FoundationObjCBridge")
__attribute__((swift_bridge("FoundationEssentials.Date")))
@interface NSDate : NSObject
#if !defined(__swift__)
@property (readonly) NSTimeInterval timeIntervalSinceReferenceDate;
@property (readonly) NSTimeInterval timeIntervalSince1970;
@property (readonly) NSTimeInterval timeIntervalSinceNow;
@property (readonly, copy) NSString *description;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTimeIntervalSince1970:(NSTimeInterval)secs;
- (instancetype)initWithTimeIntervalSinceNow:(NSTimeInterval)secs;
- (NSTimeInterval)timeIntervalSinceDate:(NSDate *)anotherDate;
- (instancetype)dateByAddingTimeInterval:(NSTimeInterval)ti;
- (NSDate *)earlierDate:(NSDate *)anotherDate;
- (NSDate *)laterDate:(NSDate *)anotherDate;
- (NSComparisonResult)compare:(NSDate *)other;
- (BOOL)isEqualToDate:(NSDate *)otherDate;
+ (instancetype)date;
@property (class, readonly) NSTimeInterval timeIntervalSinceReferenceDate;
+ (instancetype)dateWithTimeIntervalSinceNow:(NSTimeInterval)secs;
+ (instancetype)dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti;
+ (instancetype)dateWithTimeIntervalSince1970:(NSTimeInterval)secs;
@property (class, readonly, copy) NSDate *distantFuture;
@property (class, readonly, copy) NSDate *distantPast;
@property (class, readonly, copy) NSDate *now;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
