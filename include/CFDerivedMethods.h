/* CFDerivedMethods.h -- machine-derived from CF's call sites, then adjudicated.
 * Every declaration carries its verdict; none is unreviewed. Self-contained. */
#ifndef _CF_DERIVED_METHODS_H
#define _CF_DERIVED_METHODS_H
#if defined(__OBJC__)
#include "CFFoundationInterfaces.h"
#include "CFBase.h"
#include "CFArray.h"
#include "CFData.h"
#include "CFDictionary.h"
#include "CFSet.h"
#include "CFBag.h"
#include "CFNumber.h"
#include "CFDate.h"
#include "CFString.h"
#include "CFCharacterSet.h"
#include "CFError.h"
#include "CFURL.h"
#include "CFLocale.h"
#include "CFCalendar.h"
#include "CFTimeZone.h"
#include "CFStream.h"
#include "CFAttributedString.h"
#include "CFRunLoop.h"

@interface NSArray : NSObject
    - (NSUInteger)count;  /* CFArray.c:473 */ /* reconciled from (CFIndex) */
@end

@interface NSAttributedString : NSObject
    - (CFDictionaryRef)attributesAtIndex:(NSUInteger)a0 effectiveRange:(NSRange *)a1;  /* CFAttributedString.c:314 */ /* not in split */
    - (CFStringRef)string;  /* CFAttributedString.c:300 */ /* public; measured equivalent */
    - (CFTypeRef)attribute:(NSString *)a0 atIndex:(NSUInteger)a1 effectiveRange:(NSRange *)a2;  /* CFAttributedString.c:322 */ /* not in split */
@end

@interface NSCalendar (CFDerived)
    - (Boolean)_addComponents:(const unsigned char *)a0;  /* CFCalendar.c:1420 */ /* not in split */
    - (Boolean)_composeAbsoluteTime:(const unsigned char *)a0;  /* CFCalendar.c:1386 */ /* not in split */
    - (Boolean)_decomposeAbsoluteTime:(const unsigned char *)a0;  /* CFCalendar.c:1403 */ /* not in split */
    - (Boolean)_diffComponents:(const unsigned char *)a0;  /* CFCalendar.c:1474 */ /* not in split */
    - (CFDateRef)_copyGregorianStartDate;  /* CFCalendar.c:881 */
    - (NSUInteger)firstWeekday;  /* CFCalendar.c:843 */ /* reconciled from (CFIndex) */
    - (NSUInteger)minimumDaysInFirstWeek;  /* CFCalendar.c:862 */ /* reconciled from (CFIndex) */
    - (CFLocaleRef)_copyLocale;  /* CFCalendar.c:759 */
    - (CFStringRef)calendarIdentifier;  /* CFCalendar.c:753 */ /* public; measured equivalent */
    - (CFTimeZoneRef)_copyTimeZone;  /* CFCalendar.c:824 */
    - (void)_setGregorianStartDate:(NSDate *)a0;  /* CFCalendar.c:888 */
    - (void)setFirstWeekday:(NSUInteger)a0;  /* CFCalendar.c:850 */
    - (void)setLocale:(NSLocale *)a0;  /* CFCalendar.c:766 */
    - (void)setMinimumDaysInFirstWeek:(NSUInteger)a0;  /* CFCalendar.c:869 */
    - (void)setTimeZone:(NSTimeZone *)a0;  /* CFCalendar.c:831 */ /* public; measured equivalent */
@end

@interface NSCharacterSet : NSObject
    - (Boolean)hasMemberInPlane:(uint8_t)a0;  /* CFCharacterSet.c:2022 */ /* public; measured equivalent */
    - (Boolean)longCharacterIsMember:(UTF32Char)a0;  /* CFCharacterSet.c:1804, CFCharacterSet.c:1904 */ /* public; measured equivalent */
    - (CFCharacterSetRef)_expandedCFCharacterSet;  /* CFCharacterSet.c:1916 */
    - (CFCharacterSetRef)invertedSet;  /* CFCharacterSet.c:1656 */ /* no public reference; SPI */
    - (CFDataRef)_retainedBitmapRepresentation;  /* CFCharacterSet.c:2100 */
@end

@interface NSData : NSObject
    - (const uint8_t *)bytes;  /* CFData.c:515 */ /* no public reference; SPI */
@end

@interface NSDate (CFDerived)
    - (CFComparisonResult)compare:(NSDate *)a0;  /* CFDate.c:212 */ /* public; measured equivalent */
@end

@interface NSDictionary : NSObject
    - (Boolean)__getValue:(id *)a0 forKey:(id)a1;  /* CFDictionary.c:244 */
    - (NSUInteger)count;  /* CFDictionary.c:215 */ /* reconciled from (CFIndex) */
    - (CFIndex)countForKey:(id)a0;  /* CFDictionary.c:222 */
    - (NSUInteger)countForObject:(id)a0;  /* CFDictionary.c:258 */ /* reconciled from (CFIndex) */
    - (char)containsKey:(id)a0;  /* CFDictionary.c:229 */
    - (BOOL)containsObject:(id)a0;  /* CFDictionary.c:265 */ /* reconciled from (char) */
    - (void const *)objectForKey:(id)a0;  /* CFDictionary.c:236 */ /* public; measured equivalent */
    - (void)__apply:(void (*)(const void *, const void *, void *))a0 context:(void *)a1;  /* CFDictionary.c:295 */
    - (void)getObjects:(id *)a0 andKeys:(id *)a1;  /* CFDictionary.c:286 */
@end

@interface NSError : NSObject
    - (CFDictionaryRef)userInfo;  /* CFError.c:186 */ /* public; measured equivalent */
    - (CFIndex)code;  /* CFError.c:442 */ /* public; measured equivalent */
    - (CFStringRef)domain;  /* CFError.c:436 */ /* public; measured equivalent */
@end

@interface NSInputStream (CFDerived)
    - (BOOL)hasBytesAvailable;  /* CFStream.c:995 */ /* reconciled from (Boolean) */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;  /* CFStream.c:1237 */ /* public; measured equivalent */
    - (CFErrorRef)streamError;  /* CFStream.c:920 */ /* no public reference; SPI */
    - (CFIndex)read:(uint8_t *)a0 maxLength:(NSUInteger)a1;  /* CFStream.c:1025 */ /* public; measured equivalent */
    - (NSStreamStatus)streamStatus;  /* CFStream.c:874 */ /* reconciled from (CFStreamStatus) */
    - (CFTypeRef)propertyForKey:(NSString *)a0;  /* CFStream.c:1213 */ /* public; measured equivalent */
    - (void)close;  /* CFStream.c:985 */
@end

@interface NSLocale : NSObject
    - (Boolean)_doesNotRequireSpecialCaseHandling;  /* CFLocale.c:163 */
    - (CFDictionaryRef)_prefs;  /* CFLocale.c:782 */
    - (CFStringRef)_copyDisplayNameForKey:(id)a0 value:(id)a1;  /* CFLocale.c:959 */
    - (CFStringRef)localeIdentifier;  /* CFLocale.c:901 */ /* no public reference; SPI */
    - (CFTypeRef)objectForKey:(id)a0;  /* CFLocale.c:915 */ /* public; measured equivalent */
    - (void)_setDoesNotRequireSpecialCaseHandling;  /* CFLocale.c:168 */
@end

@interface NSMutableArray : NSObject
    - (void)addObject:(id)a0;  /* CFArray.c:617 */ /* public; measured equivalent */
    - (void)exchangeObjectAtIndex:(NSUInteger)a0 withObjectAtIndex:(NSUInteger)a1;  /* CFArray.c:669 */ /* public; measured equivalent */
    - (void)insertObject:(id)a0 atIndex:(NSUInteger)a1;  /* CFArray.c:655 */ /* public; measured equivalent */
    - (void)removeAllObjects;  /* CFArray.c:697 */
    - (void)removeObjectAtIndex:(NSUInteger)a0;  /* CFArray.c:687 */ /* public; measured equivalent */
    - (void)setObject:(id)a0 atIndex:(NSUInteger)a1;  /* CFArray.c:627 */ /* public; measured equivalent */
@end

@interface NSMutableAttributedString : NSObject
    - (CFMutableStringRef)mutableString;  /* CFAttributedString.c:441 */ /* no public reference; SPI */
    - (void)beginEditing;  /* CFAttributedString.c:643 */
    - (void)endEditing;  /* CFAttributedString.c:647 */
@end

@interface NSMutableCharacterSet : NSObject
    - (void)addCharactersInString:(NSString *)a0;  /* CFCharacterSet.c:2447 */ /* public; measured equivalent */
    - (void)formIntersectionWithCharacterSet:(NSCharacterSet *)a0;  /* CFCharacterSet.c:2762 */ /* public; measured equivalent */
    - (void)formUnionWithCharacterSet:(NSCharacterSet *)a0;  /* CFCharacterSet.c:2625 */ /* public; measured equivalent */
    - (void)invert;  /* CFCharacterSet.c:3005 */
    - (void)removeCharactersInString:(NSString *)a0;  /* CFCharacterSet.c:2540 */ /* public; measured equivalent */
@end

@interface NSMutableData : NSObject
    - (uint8_t *)mutableBytes;  /* CFData.c:521 */ /* no public reference; SPI */
    - (void)appendBytes:(const void *)a0 length:(NSUInteger)a1;  /* CFData.c:613 */ /* public; measured equivalent */
    - (void)increaseLengthBy:(NSUInteger)a0;  /* CFData.c:605 */ /* public; measured equivalent */
    - (void)setLength:(NSUInteger)a0;  /* CFData.c:574 */
@end

@interface NSMutableDictionary : NSObject
    - (void)__addObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:369 */
    - (void)__setObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:395 */
    - (void)removeAllObjects;  /* CFDictionary.c:422 */
    - (void)removeObjectForKey:(id)a0;  /* CFDictionary.c:409 */ /* public; measured equivalent */
    - (void)replaceObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:382 */
@end

@interface NSMutableSet : NSObject
    - (void)addObject:(id)a0;  /* CFSet.c:286 */ /* public; measured equivalent */
    - (void)removeAllObjects;  /* CFSet.c:332 */
    - (void)removeObject:(id)a0;  /* CFSet.c:321 */ /* public; measured equivalent */
    - (void)replaceObject:(id)a0;  /* CFSet.c:298 */
    - (void)setObject:(id)a0;  /* CFSet.c:310 */
@end

@interface NSMutableString : NSObject
    - (void)_cfAppendCString:(const unsigned char *)a0 length:(NSInteger)a1;  /* CFString.c:5122 */
    - (void)_cfCapitalize:(const void *)a0;  /* CFString.c:5583 */
    - (void)_cfLowercase:(const void *)a0;  /* CFString.c:5398 */
    - (void)_cfTrimWS;  /* CFString.c:5362 */
    - (void)_cfUppercase:(const void *)a0;  /* CFString.c:5489 */
    - (void)appendCharacters:(const unichar *)a0 length:(NSUInteger)a1;  /* CFString.c:5124 */
    - (void)appendString:(NSString *)a0;  /* CFString.c:5047 */ /* public; measured equivalent */
    - (void)insertString:(NSString *)a0 atIndex:(NSUInteger)a1;  /* CFString.c:5012 */ /* public; measured equivalent */
    - (void)setString:(NSString *)a0;  /* CFString.c:5039 */ /* public; measured equivalent */
@end

@interface NSNumber : NSObject
    - (Boolean)_getValue:(void *)a0 forType:(CFNumberType)a1;  /* CFNumber.c:1215 */
    - (Boolean)boolValue;  /* CFNumber.c:136 */ /* public; measured equivalent */
    - (CFComparisonResult)_reverseCompare:(NSNumber *)a0;  /* CFNumber.c:1226 */
    - (CFComparisonResult)compare:(NSNumber *)a0;  /* CFNumber.c:1225 */ /* public; measured equivalent */
    - (CFNumberType)_cfNumberType;  /* CFNumber.c:1195 */
@end

@interface NSOutputStream (CFDerived)
    - (BOOL)hasSpaceAvailable;  /* CFStream.c:1131 */ /* reconciled from (Boolean) */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;  /* CFStream.c:1243 */ /* public; measured equivalent */
    - (CFErrorRef)streamError;  /* CFStream.c:925 */ /* no public reference; SPI */
    - (CFIndex)write:(const uint8_t *)a0 maxLength:(NSUInteger)a1;  /* CFStream.c:1159 */ /* public; measured equivalent */
    - (NSStreamStatus)streamStatus;  /* CFStream.c:879 */ /* reconciled from (CFStreamStatus) */
    - (CFTypeRef)propertyForKey:(NSString *)a0;  /* CFStream.c:1218 */ /* public; measured equivalent */
    - (void)close;  /* CFStream.c:990 */
@end

@interface NSSet : NSObject
    - (Boolean)__getValue:(id *)a0 forObj:(id)a1;  /* CFSet.c:226 */
    - (NSUInteger)count;  /* CFSet.c:197 */ /* reconciled from (CFIndex) */
    - (NSUInteger)countForObject:(id)a0;  /* CFSet.c:204 */ /* reconciled from (CFIndex) */
    - (BOOL)containsObject:(id)a0;  /* CFSet.c:211 */ /* reconciled from (char) */
    - (const void *)member:(id)a0;  /* CFSet.c:218 */ /* public; measured equivalent */
    - (void)__applyValues:(void (*)(const void *, void *))a0 context:(void *)a1;  /* CFSet.c:249 */
    - (void)getObjects:(id *)a0;  /* CFSet.c:241 */
@end

@interface NSString (CFDerived)
    - (Boolean)_encodingCantBeStoredInEightBitCFString;  /* CFString.c:1271 */
    - (CFStringEncoding)_fastestEncodingInCFStringEncoding;  /* CFString.c:4967 */
    - (CFStringEncoding)_smallestEncodingInCFStringEncoding;  /* CFString.c:4952 */
    - (unichar)characterAtIndex:(NSUInteger)a0;  /* CFString.c:2135 */ /* reconciled from (UniChar) */
    - (const UniChar *)_fastCharacterContents;  /* CFString.c:2265 */
@end

@interface NSTimeZone : NSObject
    - (CFDataRef)data;  /* CFTimeZone.c:1515 */ /* public; measured equivalent */
    - (CFStringRef)localizedName:(NSTimeZoneNameStyle)a0 locale:(NSLocale *)a1;  /* CFTimeZone.c:1640 */ /* not in split */
    - (CFStringRef)name;  /* CFTimeZone.c:1509 */ /* public; measured equivalent */
@end

@interface NSTimer : NSObject
    - (Boolean)isValid;  /* CFRunLoop.c:4727 */
    - (CFAbsoluteTime)_cffireTime;  /* CFRunLoop.c:4577 */
    - (NSTimeInterval)timeInterval;  /* CFRunLoop.c:4657 */ /* reconciled from (CFTimeInterval) */
    - (NSTimeInterval)tolerance;  /* CFRunLoop.c:4742 */ /* reconciled from (CFTimeInterval) */
    - (void)invalidate;  /* CFRunLoop.c:4676 */
@end

@interface NSURL : NSObject
    - (CFStringRef)relativeString;  /* CFURL.c:2998 */ /* no public reference; SPI */
    - (CFURLRef)_cfurl;  /* CFURL.c:1673 */
    - (CFURLRef)baseURL;  /* CFURL.c:3044 */ /* no public reference; SPI */
@end


#endif
#endif
