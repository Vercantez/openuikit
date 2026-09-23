// NSDateFormatter, NSLocale and NSTimeZone (FoundationObjCBridge): the
// surface FMDB's +storeableDateFormat: touches. Only the fixed-format
// en_US_POSIX / GMT-offset case FMDB configures is implemented; any other
// use stops with a message naming the missing piece rather than formatting
// with invented rules.
#ifndef OF_FOUNDATION_NSDATEFORMATTER_H
#define OF_FOUNDATION_NSDATEFORMATTER_H

#import <Foundation/NSObject.h>

@class NSString, NSDate;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge8NSLocale", "FoundationObjCBridge")
@interface NSLocale : NSObject
#if !defined(__swift__)
- (instancetype)initWithLocaleIdentifier:(NSString *)string;
+ (instancetype)localeWithLocaleIdentifier:(NSString *)ident;
@property (readonly, copy) NSString *localeIdentifier;
#endif
@end

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge10NSTimeZone", "FoundationObjCBridge")
@interface NSTimeZone : NSObject
#if !defined(__swift__)
+ (nullable instancetype)timeZoneForSecondsFromGMT:(NSInteger)seconds;
+ (nullable instancetype)timeZoneWithName:(NSString *)tzName;
@property (readonly) NSInteger secondsFromGMT;
@property (readonly, copy) NSString *name;
#endif
@end

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge15NSDateFormatter", "FoundationObjCBridge")
@interface NSDateFormatter : NSObject
#if !defined(__swift__)
@property (null_resettable, copy) NSString *dateFormat;
@property (null_resettable, copy) NSLocale *locale;
@property (null_resettable, copy) NSTimeZone *timeZone;
- (NSString *)stringFromDate:(NSDate *)date;
- (nullable NSDate *)dateFromString:(NSString *)string;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
