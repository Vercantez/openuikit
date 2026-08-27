/* CFDerivedMethods.h -- machine-derived, reconciled against the public/private split.
 * Categories where CFFoundationInterfaces.h already declares the class;
 * a real @interface otherwise (a category needs a full @interface, not a @class). */
#ifndef _CF_DERIVED_METHODS_H
#define _CF_DERIVED_METHODS_H
#if defined(__OBJC__)
#include "CFFoundationInterfaces.h"

/* SELF-CONTAINED. This header is force-included, so it lands before CF's own
 * headers and must bring its own types -- CFNumberType, CFComparisonResult,
 * CFStreamStatus and the rest appear in derived signatures because CF's call
 * sites use them. The FIFTH census wipeout tonight was this exact omission, and
 * the fourth was its twin. Include what you reference; never assume ordering. */
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
    - (CFStringRef)string;  /* CFAttributedString.c:300 */ /* PUBLIC, UNREVIEWED */
    - (CFTypeRef)attribute:(NSString *)a0 atIndex:(NSUInteger)a1 effectiveRange:(NSRange *)a2;  /* CFAttributedString.c:322 */ /* not in split */
@end

@interface NSCalendar (CFDerived)
    - (Boolean)_addComponents:(const unsigned char *)a0;  /* CFCalendar.c:1420 */ /* not in split */
    - (Boolean)_composeAbsoluteTime:(const unsigned char *)a0;  /* CFCalendar.c:1386 */ /* not in split */
    - (Boolean)_decomposeAbsoluteTime:(const unsigned char *)a0;  /* CFCalendar.c:1403 */ /* not in split */
    - (Boolean)_diffComponents:(const unsigned char *)a0;  /* CFCalendar.c:1474 */ /* not in split */
    - (CFDateRef)_copyGregorianStartDate;  /* CFCalendar.c:881 */
    - (CFIndex)firstWeekday;  /* CFCalendar.c:843 */ /* PUBLIC, UNREVIEWED */
    - (CFIndex)minimumDaysInFirstWeek;  /* CFCalendar.c:862 */ /* PUBLIC, UNREVIEWED */
    - (CFLocaleRef)_copyLocale;  /* CFCalendar.c:759 */
    - (CFStringRef)calendarIdentifier;  /* CFCalendar.c:753 */ /* PUBLIC, UNREVIEWED */
    - (CFTimeZoneRef)_copyTimeZone;  /* CFCalendar.c:824 */
    - (void)_setGregorianStartDate:(NSDate *)a0;  /* CFCalendar.c:888 */
    - (void)setFirstWeekday:(NSUInteger)a0;  /* CFCalendar.c:850 */
    - (void)setLocale:(NSLocale *)a0;  /* CFCalendar.c:766 */
    - (void)setMinimumDaysInFirstWeek:(NSUInteger)a0;  /* CFCalendar.c:869 */
    - (void)setTimeZone:(NSTimeZone *)a0;  /* CFCalendar.c:831 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSCharacterSet : NSObject
    - (Boolean)hasMemberInPlane:(uint8_t)a0;  /* CFCharacterSet.c:2022 */ /* PUBLIC, UNREVIEWED */
    - (Boolean)longCharacterIsMember:(UTF32Char)a0;  /* CFCharacterSet.c:1804, CFCharacterSet.c:1904 */ /* PUBLIC, UNREVIEWED */
    - (CFCharacterSetRef)_expandedCFCharacterSet;  /* CFCharacterSet.c:1916 */
    - (CFCharacterSetRef)invertedSet;  /* CFCharacterSet.c:1656 */ /* PUBLIC, UNREVIEWED */
    - (CFDataRef)_retainedBitmapRepresentation;  /* CFCharacterSet.c:2100 */
@end

@interface NSData : NSObject
    - (const uint8_t *)bytes;  /* CFData.c:515 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSDate (CFDerived)
    - (CFComparisonResult)compare:(NSDate *)a0;  /* CFDate.c:212 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSDictionary : NSObject
    - (Boolean)__getValue:(id *)a0 forKey:(id)a1;  /* CFDictionary.c:244 */
    - (NSUInteger)count;  /* CFDictionary.c:215 */ /* reconciled from (CFIndex) */
    - (CFIndex)countForKey:(id)a0;  /* CFDictionary.c:222 */
    - (NSUInteger)countForObject:(id)a0;  /* CFDictionary.c:258 */ /* reconciled from (CFIndex) */
    - (char)containsKey:(id)a0;  /* CFDictionary.c:229 */
    - (BOOL)containsObject:(id)a0;  /* CFDictionary.c:265 */ /* reconciled from (char) */
    - (void const *)objectForKey:(id)a0;  /* CFDictionary.c:236 */ /* PUBLIC, UNREVIEWED */
    - (void)__apply:(void (*)(const void *, const void *, void *))a0 context:(void *)a1;  /* CFDictionary.c:295 */
    - (void)getObjects:(id *)a0 andKeys:(id *)a1;  /* CFDictionary.c:286 */
@end

@interface NSError : NSObject
    - (CFDictionaryRef)userInfo;  /* CFError.c:186 */ /* PUBLIC, UNREVIEWED */
    - (CFIndex)code;  /* CFError.c:442 */ /* PUBLIC, UNREVIEWED */
    - (CFStringRef)domain;  /* CFError.c:436 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSInputStream (CFDerived)
    - (BOOL)hasBytesAvailable;  /* CFStream.c:995 */ /* reconciled from (Boolean) */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;  /* CFStream.c:1237 */ /* PUBLIC, UNREVIEWED */
    - (CFErrorRef)streamError;  /* CFStream.c:920 */ /* PUBLIC, UNREVIEWED */
    - (CFIndex)read:(uint8_t *)a0 maxLength:(NSUInteger)a1;  /* CFStream.c:1025 */ /* PUBLIC, UNREVIEWED */
    - (CFStreamStatus)streamStatus;  /* CFStream.c:874 */ /* PUBLIC, UNREVIEWED */
    - (CFTypeRef)propertyForKey:(NSString *)a0;  /* CFStream.c:1213 */ /* PUBLIC, UNREVIEWED */
    - (void)close;  /* CFStream.c:985 */
@end

@interface NSLocale : NSObject
    - (Boolean)_doesNotRequireSpecialCaseHandling;  /* CFLocale.c:163 */
    - (CFDictionaryRef)_prefs;  /* CFLocale.c:782 */
    - (CFStringRef)_copyDisplayNameForKey:(id)a0 value:(id)a1;  /* CFLocale.c:959 */
    - (CFStringRef)localeIdentifier;  /* CFLocale.c:901 */ /* PUBLIC, UNREVIEWED */
    - (CFTypeRef)objectForKey:(id)a0;  /* CFLocale.c:915 */ /* PUBLIC, UNREVIEWED */
    - (void)_setDoesNotRequireSpecialCaseHandling;  /* CFLocale.c:168 */
@end

@interface NSMutableArray : NSObject
    - (void)addObject:(id)a0;  /* CFArray.c:617 */ /* PUBLIC, UNREVIEWED */
    - (void)exchangeObjectAtIndex:(NSUInteger)a0 withObjectAtIndex:(NSUInteger)a1;  /* CFArray.c:669 */ /* PUBLIC, UNREVIEWED */
    - (void)insertObject:(id)a0 atIndex:(NSUInteger)a1;  /* CFArray.c:655 */ /* PUBLIC, UNREVIEWED */
    - (void)removeAllObjects;  /* CFArray.c:697 */
    - (void)removeObjectAtIndex:(NSUInteger)a0;  /* CFArray.c:687 */ /* PUBLIC, UNREVIEWED */
    - (void)setObject:(id)a0 atIndex:(NSUInteger)a1;  /* CFArray.c:627 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSMutableAttributedString : NSObject
    - (CFMutableStringRef)mutableString;  /* CFAttributedString.c:441 */ /* PUBLIC, UNREVIEWED */
    - (void)beginEditing;  /* CFAttributedString.c:643 */
    - (void)endEditing;  /* CFAttributedString.c:647 */
@end

@interface NSMutableCharacterSet : NSObject
    - (void)addCharactersInString:(NSString *)a0;  /* CFCharacterSet.c:2447 */ /* PUBLIC, UNREVIEWED */
    - (void)formIntersectionWithCharacterSet:(NSCharacterSet *)a0;  /* CFCharacterSet.c:2762 */ /* PUBLIC, UNREVIEWED */
    - (void)formUnionWithCharacterSet:(NSCharacterSet *)a0;  /* CFCharacterSet.c:2625 */ /* PUBLIC, UNREVIEWED */
    - (void)invert;  /* CFCharacterSet.c:3005 */
    - (void)removeCharactersInString:(NSString *)a0;  /* CFCharacterSet.c:2540 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSMutableData : NSObject
    - (uint8_t *)mutableBytes;  /* CFData.c:521 */ /* PUBLIC, UNREVIEWED */
    - (void)appendBytes:(const void *)a0 length:(NSUInteger)a1;  /* CFData.c:613 */ /* PUBLIC, UNREVIEWED */
    - (void)increaseLengthBy:(NSUInteger)a0;  /* CFData.c:605 */ /* PUBLIC, UNREVIEWED */
    - (void)setLength:(NSUInteger)a0;  /* CFData.c:574 */
@end

@interface NSMutableDictionary : NSObject
    - (void)__addObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:369 */
    - (void)__setObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:395 */
    - (void)removeAllObjects;  /* CFDictionary.c:422 */
    - (void)removeObjectForKey:(id)a0;  /* CFDictionary.c:409 */ /* PUBLIC, UNREVIEWED */
    - (void)replaceObject:(id)a0 forKey:(id)a1;  /* CFDictionary.c:382 */
@end

@interface NSMutableSet : NSObject
    - (void)addObject:(id)a0;  /* CFSet.c:286 */ /* PUBLIC, UNREVIEWED */
    - (void)removeAllObjects;  /* CFSet.c:332 */
    - (void)removeObject:(id)a0;  /* CFSet.c:321 */ /* PUBLIC, UNREVIEWED */
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
    - (void)appendString:(NSString *)a0;  /* CFString.c:5047 */ /* PUBLIC, UNREVIEWED */
    - (void)insertString:(NSString *)a0 atIndex:(NSUInteger)a1;  /* CFString.c:5012 */ /* PUBLIC, UNREVIEWED */
    - (void)setString:(NSString *)a0;  /* CFString.c:5039 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSNumber : NSObject
    - (Boolean)_getValue:(void *)a0 forType:(CFNumberType)a1;  /* CFNumber.c:1215 */
    - (Boolean)boolValue;  /* CFNumber.c:136 */ /* PUBLIC, UNREVIEWED */
    - (CFComparisonResult)_reverseCompare:(NSNumber *)a0;  /* CFNumber.c:1226 */
    - (CFComparisonResult)compare:(NSNumber *)a0;  /* CFNumber.c:1225 */ /* PUBLIC, UNREVIEWED */
    - (CFNumberType)_cfNumberType;  /* CFNumber.c:1195 */
@end

@interface NSOutputStream (CFDerived)
    - (BOOL)hasSpaceAvailable;  /* CFStream.c:1131 */ /* reconciled from (Boolean) */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;  /* CFStream.c:1243 */ /* PUBLIC, UNREVIEWED */
    - (CFErrorRef)streamError;  /* CFStream.c:925 */ /* PUBLIC, UNREVIEWED */
    - (CFIndex)write:(const uint8_t *)a0 maxLength:(NSUInteger)a1;  /* CFStream.c:1159 */ /* PUBLIC, UNREVIEWED */
    - (CFStreamStatus)streamStatus;  /* CFStream.c:879 */ /* PUBLIC, UNREVIEWED */
    - (CFTypeRef)propertyForKey:(NSString *)a0;  /* CFStream.c:1218 */ /* PUBLIC, UNREVIEWED */
    - (void)close;  /* CFStream.c:990 */
@end

@interface NSSet : NSObject
    - (Boolean)__getValue:(id *)a0 forObj:(id)a1;  /* CFSet.c:226 */
    - (NSUInteger)count;  /* CFSet.c:197 */ /* reconciled from (CFIndex) */
    - (NSUInteger)countForObject:(id)a0;  /* CFSet.c:204 */ /* reconciled from (CFIndex) */
    - (BOOL)containsObject:(id)a0;  /* CFSet.c:211 */ /* reconciled from (char) */
    - (const void *)member:(id)a0;  /* CFSet.c:218 */ /* PUBLIC, UNREVIEWED */
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
    - (CFDataRef)data;  /* CFTimeZone.c:1515 */ /* PUBLIC, UNREVIEWED */
    - (CFStringRef)localizedName:(NSTimeZoneNameStyle)a0 locale:(NSLocale *)a1;  /* CFTimeZone.c:1640 */ /* not in split */
    - (CFStringRef)name;  /* CFTimeZone.c:1509 */ /* PUBLIC, UNREVIEWED */
@end

@interface NSTimer : NSObject
    - (Boolean)isValid;  /* CFRunLoop.c:4727 */
    - (CFAbsoluteTime)_cffireTime;  /* CFRunLoop.c:4577 */
    - (NSTimeInterval)timeInterval;  /* CFRunLoop.c:4657 */ /* reconciled from (CFTimeInterval) */
    - (NSTimeInterval)tolerance;  /* CFRunLoop.c:4742 */ /* reconciled from (CFTimeInterval) */
    - (void)invalidate;  /* CFRunLoop.c:4676 */
@end

@interface NSURL : NSObject
    - (CFStringRef)relativeString;  /* CFURL.c:2998 */ /* PUBLIC, UNREVIEWED */
    - (CFURLRef)_cfurl;  /* CFURL.c:1673 */
    - (CFURLRef)baseURL;  /* CFURL.c:3044 */ /* PUBLIC, UNREVIEWED */
@end


#endif
#endif
