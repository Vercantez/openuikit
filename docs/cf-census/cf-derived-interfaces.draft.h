/* DRAFT — machine-derived, NOT the shipping header. Do not paste this in.
 *
 * Produced by scripts/derive_interfaces.py from CoreFoundation's own dispatch
 * call sites: 123 declarations across 24 classes, derived from 178 call sites,
 * with 54 explicitly NOT derived and listed at the end.
 *
 * WHY THIS IS A DRAFT AND NOT THE ANSWER — a qualification to something I got
 * slightly wrong. I claimed a call site "IS the ABI" and is therefore a stronger
 * source than a header. That is true for DISPATCH CORRECTNESS and false for TYPE
 * IDENTITY, and the two are not the same question.
 *
 * Worked example, from this very output:
 *
 *     derived:        - (CFIndex)count;        <- from CFArray.c:473
 *     Apple declares: @property (readonly) NSUInteger count;
 *
 * CFIndex is `signed long`; NSUInteger is `unsigned long`. Same width, so on
 * arm64 both arrive in x0 and the message send is byte-identical — the derived
 * form dispatches correctly and would pass every test we have. But it is not
 * Foundation's contract, and an NS* class of ours declaring `count` as signed
 * is wrong for any consumer that is not CoreFoundation.
 *
 * So the two sources answer different questions, and the public/private split
 * decides which one wins:
 *
 *   PUBLIC (86)   Apple's header is authoritative for the DECLARED TYPE. The
 *                 call site only tells you what CF does with the result, and
 *                 CF's cast to its own type is a normal conversion.
 *   PRIVATE (65)  no header exists, so the call site is authoritative outright.
 *
 * This file therefore needs RECONCILIATION before anything ships: public-half
 * declarations reconciled against Apple's headers, private-half adopted as
 * derived. That is exactly what the split was established for, and this output
 * is the evidence it was worth establishing.
 */

/* Derived from 178 call sites: 123 declarations across 24 classes. */

@interface NSArray : NSObject
    - (CFIndex)count;                                                      /* CFArray.c:473 */
@end

@interface NSAttributedString : NSObject
    - (CFDictionaryRef)attributesAtIndex:(NSUInteger)a0 effectiveRange:(NSRange *)a1; /* CFAttributedString.c:314 */
    - (CFStringRef)string;                                                 /* CFAttributedString.c:300 */
    - (CFTypeRef)attribute:(NSString *)a0 atIndex:(NSUInteger)a1 effectiveRange:(NSRange *)a2; /* CFAttributedString.c:322 */
@end

@interface NSCalendar : NSObject
    - (Boolean)_addComponents:(const unsigned char *)a0;                   /* CFCalendar.c:1420 */
    - (Boolean)_composeAbsoluteTime:(const unsigned char *)a0;             /* CFCalendar.c:1386 */
    - (Boolean)_decomposeAbsoluteTime:(const unsigned char *)a0;           /* CFCalendar.c:1403 */
    - (Boolean)_diffComponents:(const unsigned char *)a0;                  /* CFCalendar.c:1474 */
    - (CFDateRef)_copyGregorianStartDate;                                  /* CFCalendar.c:881 */
    - (CFIndex)firstWeekday;                                               /* CFCalendar.c:843 */
    - (CFIndex)minimumDaysInFirstWeek;                                     /* CFCalendar.c:862 */
    - (CFLocaleRef)_copyLocale;                                            /* CFCalendar.c:759 */
    - (CFStringRef)calendarIdentifier;                                     /* CFCalendar.c:753 */
    - (CFTimeZoneRef)_copyTimeZone;                                        /* CFCalendar.c:824 */
    - (void)_setGregorianStartDate:(NSDate *)a0;                           /* CFCalendar.c:888 */
    - (void)setFirstWeekday:(NSUInteger)a0;                                /* CFCalendar.c:850 */
    - (void)setLocale:(NSLocale *)a0;                                      /* CFCalendar.c:766 */
    - (void)setMinimumDaysInFirstWeek:(NSUInteger)a0;                      /* CFCalendar.c:869 */
    - (void)setTimeZone:(NSTimeZone *)a0;                                  /* CFCalendar.c:831 */
@end

@interface NSCharacterSet : NSObject
    - (Boolean)hasMemberInPlane:(uint8_t)a0;                               /* CFCharacterSet.c:2022 */
    - (Boolean)longCharacterIsMember:(UTF32Char)a0;                        /* CFCharacterSet.c:1804, CFCharacterSet.c:1904 */
    - (CFCharacterSetRef)_expandedCFCharacterSet;                          /* CFCharacterSet.c:1916 */
    - (CFCharacterSetRef)invertedSet;                                      /* CFCharacterSet.c:1656 */
    - (CFDataRef)_retainedBitmapRepresentation;                            /* CFCharacterSet.c:2100 */
@end

@interface NSData : NSObject
    - (const uint8_t *)bytes;                                              /* CFData.c:515 */
@end

@interface NSDate : NSObject
    - (CFComparisonResult)compare:(NSDate *)a0;                            /* CFDate.c:212 */
@end

@interface NSDictionary : NSObject
    - (Boolean)__getValue:(id *)a0 forKey:(id)a1;                          /* CFDictionary.c:244 */
    - (CFIndex)count;                                                      /* CFDictionary.c:215 */
    - (CFIndex)countForKey:(id)a0;                                         /* CFDictionary.c:222 */
    - (CFIndex)countForObject:(id)a0;                                      /* CFDictionary.c:258 */
    - (char)containsKey:(id)a0;                                            /* CFDictionary.c:229 */
    - (char)containsObject:(id)a0;                                         /* CFDictionary.c:265 */
    - (void const *)objectForKey:(id)a0;                                   /* CFDictionary.c:236 */
    - (void)__apply:(void (*)a0 context:(void *)a1;                        /* CFDictionary.c:295 */
    - (void)getObjects:(id *)a0 andKeys:(id *)a1;                          /* CFDictionary.c:286 */
@end

@interface NSError : NSObject
    - (CFDictionaryRef)userInfo;                                           /* CFError.c:186 */
    - (CFIndex)code;                                                       /* CFError.c:442 */
    - (CFStringRef)domain;                                                 /* CFError.c:436 */
@end

@interface NSInputStream : NSObject
    - (Boolean)hasBytesAvailable;                                          /* CFStream.c:995 */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;                   /* CFStream.c:1237 */
    - (CFErrorRef)streamError;                                             /* CFStream.c:920 */
    - (CFIndex)read:(uint8_t *)a0 maxLength:(NSUInteger)a1;                /* CFStream.c:1025 */
    - (CFStreamStatus)streamStatus;                                        /* CFStream.c:874 */
    - (CFTypeRef)propertyForKey:(NSString *)a0;                            /* CFStream.c:1213 */
    - (void)close;                                                         /* CFStream.c:985 */
@end

@interface NSLocale : NSObject
    - (Boolean)_doesNotRequireSpecialCaseHandling;                         /* CFLocale.c:163 */
    - (CFDictionaryRef)_prefs;                                             /* CFLocale.c:782 */
    - (CFStringRef)_copyDisplayNameForKey:(id)a0 value:(id)a1;             /* CFLocale.c:959 */
    - (CFStringRef)localeIdentifier;                                       /* CFLocale.c:901 */
    - (CFTypeRef)objectForKey:(id)a0;                                      /* CFLocale.c:915 */
    - (void)_setDoesNotRequireSpecialCaseHandling;                         /* CFLocale.c:168 */
@end

@interface NSMutableArray : NSObject
    - (void)addObject:(id)a0;                                              /* CFArray.c:617 */
    - (void)exchangeObjectAtIndex:(NSUInteger)a0 withObjectAtIndex:(NSUInteger)a1; /* CFArray.c:669 */
    - (void)insertObject:(id)a0 atIndex:(NSUInteger)a1;                    /* CFArray.c:655 */
    - (void)removeAllObjects;                                              /* CFArray.c:697 */
    - (void)removeObjectAtIndex:(NSUInteger)a0;                            /* CFArray.c:687 */
    - (void)setObject:(id)a0 atIndex:(NSUInteger)a1;                       /* CFArray.c:627 */
@end

@interface NSMutableAttributedString : NSObject
    - (CFMutableStringRef)mutableString;                                   /* CFAttributedString.c:441 */
    - (void)beginEditing;                                                  /* CFAttributedString.c:643 */
    - (void)endEditing;                                                    /* CFAttributedString.c:647 */
@end

@interface NSMutableCharacterSet : NSObject
    - (void)addCharactersInString:(NSString *)a0;                          /* CFCharacterSet.c:2447 */
    - (void)formIntersectionWithCharacterSet:(NSCharacterSet *)a0;         /* CFCharacterSet.c:2762 */
    - (void)formUnionWithCharacterSet:(NSCharacterSet *)a0;                /* CFCharacterSet.c:2625 */
    - (void)invert;                                                        /* CFCharacterSet.c:3005 */
    - (void)removeCharactersInString:(NSString *)a0;                       /* CFCharacterSet.c:2540 */
@end

@interface NSMutableData : NSObject
    - (uint8_t *)mutableBytes;                                             /* CFData.c:521 */
    - (void)appendBytes:(const void *)a0 length:(NSUInteger)a1;            /* CFData.c:613 */
    - (void)increaseLengthBy:(NSUInteger)a0;                               /* CFData.c:605 */
    - (void)setLength:(NSUInteger)a0;                                      /* CFData.c:574 */
@end

@interface NSMutableDictionary : NSObject
    - (void)__addObject:(id)a0 forKey:(id)a1;                              /* CFDictionary.c:369 */
    - (void)__setObject:(id)a0 forKey:(id)a1;                              /* CFDictionary.c:395 */
    - (void)removeAllObjects;                                              /* CFDictionary.c:422 */
    - (void)removeObjectForKey:(id)a0;                                     /* CFDictionary.c:409 */
    - (void)replaceObject:(id)a0 forKey:(id)a1;                            /* CFDictionary.c:382 */
@end

@interface NSMutableSet : NSObject
    - (void)addObject:(id)a0;                                              /* CFSet.c:286 */
    - (void)removeAllObjects;                                              /* CFSet.c:332 */
    - (void)removeObject:(id)a0;                                           /* CFSet.c:321 */
    - (void)replaceObject:(id)a0;                                          /* CFSet.c:298 */
    - (void)setObject:(id)a0;                                              /* CFSet.c:310 */
@end

@interface NSMutableString : NSObject
    - (void)_cfAppendCString:(const unsigned char *)a0 length:(NSInteger)a1; /* CFString.c:5122 */
    - (void)_cfCapitalize:(const void *)a0;                                /* CFString.c:5583 */
    - (void)_cfLowercase:(const void *)a0;                                 /* CFString.c:5398 */
    - (void)_cfTrimWS;                                                     /* CFString.c:5362 */
    - (void)_cfUppercase:(const void *)a0;                                 /* CFString.c:5489 */
    - (void)appendCharacters:(const unichar *)a0 length:(NSUInteger)a1;    /* CFString.c:5124 */
    - (void)appendString:(NSString *)a0;                                   /* CFString.c:5047 */
    - (void)insertString:(NSString *)a0 atIndex:(NSUInteger)a1;            /* CFString.c:5012 */
    - (void)setString:(NSString *)a0;                                      /* CFString.c:5039 */
@end

@interface NSNumber : NSObject
    - (Boolean)_getValue:(void *)a0 forType:(CFNumberType)a1;              /* CFNumber.c:1215 */
    - (Boolean)boolValue;                                                  /* CFNumber.c:136 */
    - (CFComparisonResult)_reverseCompare:(NSNumber *)a0;                  /* CFNumber.c:1226 */
    - (CFComparisonResult)compare:(NSNumber *)a0;                          /* CFNumber.c:1225 */
    - (CFNumberType)_cfNumberType;                                         /* CFNumber.c:1195 */
@end

@interface NSOutputStream : NSObject
    - (Boolean)hasSpaceAvailable;                                          /* CFStream.c:1131 */
    - (Boolean)setProperty:(id)a0 forKey:(NSString *)a1;                   /* CFStream.c:1243 */
    - (CFErrorRef)streamError;                                             /* CFStream.c:925 */
    - (CFIndex)write:(const uint8_t *)a0 maxLength:(NSUInteger)a1;         /* CFStream.c:1159 */
    - (CFStreamStatus)streamStatus;                                        /* CFStream.c:879 */
    - (CFTypeRef)propertyForKey:(NSString *)a0;                            /* CFStream.c:1218 */
    - (void)close;                                                         /* CFStream.c:990 */
@end

@interface NSSet : NSObject
    - (Boolean)__getValue:(id *)a0 forObj:(id)a1;                          /* CFSet.c:226 */
    - (CFIndex)count;                                                      /* CFSet.c:197 */
    - (CFIndex)countForObject:(id)a0;                                      /* CFSet.c:204 */
    - (char)containsObject:(id)a0;                                         /* CFSet.c:211 */
    - (const void *)member:(id)a0;                                         /* CFSet.c:218 */
    - (void)__applyValues:(void (*)a0 context:(void *)a1;                  /* CFSet.c:249 */
    - (void)getObjects:(id *)a0;                                           /* CFSet.c:241 */
@end

@interface NSString : NSObject
    - (Boolean)_encodingCantBeStoredInEightBitCFString;                    /* CFString.c:1271 */
    - (CFStringEncoding)_fastestEncodingInCFStringEncoding;                /* CFString.c:4967 */
    - (CFStringEncoding)_smallestEncodingInCFStringEncoding;               /* CFString.c:4952 */
    - (UniChar)characterAtIndex:(NSUInteger)a0;                            /* CFString.c:2135 */
    - (const UniChar *)_fastCharacterContents;                             /* CFString.c:2265 */
@end

@interface NSTimeZone : NSObject
    - (CFDataRef)data;                                                     /* CFTimeZone.c:1515 */
    - (CFStringRef)localizedName:(NSTimeZoneNameStyle)a0 locale:(NSLocale *)a1; /* CFTimeZone.c:1640 */
    - (CFStringRef)name;                                                   /* CFTimeZone.c:1509 */
@end

@interface NSTimer : NSObject
    - (Boolean)isValid;                                                    /* CFRunLoop.c:4727 */
    - (CFAbsoluteTime)_cffireTime;                                         /* CFRunLoop.c:4577 */
    - (CFTimeInterval)timeInterval;                                        /* CFRunLoop.c:4657 */
    - (CFTimeInterval)tolerance;                                           /* CFRunLoop.c:4742 */
    - (void)invalidate;                                                    /* CFRunLoop.c:4676 */
@end

@interface NSURL : NSObject
    - (CFStringRef)relativeString;                                         /* CFURL.c:2998 */
    - (CFURLRef)_cfurl;                                                    /* CFURL.c:1673 */
    - (CFURLRef)baseURL;                                                   /* CFURL.c:3044 */
@end

/* NOT DERIVED — 54. These need a human, not a guess. */
/*   CFArray.c:534          ?                  -getObjects:range:                 call site not a recognised dispatch macro */
/*   CFArray.c:836          ?                  -replaceObjectsInRange:withObjects:count: call site not a recognised dispatch macro */
/*   CFAttributedString.c:331 ?                  -attributesAtIndex:longestEffectiveRange:inRange: call site not a recognised dispatch macro */
/*   CFAttributedString.c:366 ?                  -attribute:atIndex:longestEffectiveRange:inRange: call site not a recognised dispatch macro */
/*   CFAttributedString.c:446 ?                  -replaceCharactersInRange:withString: call site not a recognised dispatch macro */
/*   CFAttributedString.c:479 ?                  -setAttributes:range:              call site not a recognised dispatch macro */
/*   CFAttributedString.c:481 ?                  -addAttributes:range:              call site not a recognised dispatch macro */
/*   CFAttributedString.c:539 ?                  -addAttribute:value:range:         call site not a recognised dispatch macro */
/*   CFAttributedString.c:580 ?                  -removeAttribute:range:            call site not a recognised dispatch macro */
/*   CFAttributedString.c:619 ?                  -replaceCharactersInRange:withAttributedString: call site not a recognised dispatch macro */
/*   CFCalendar.c:1490      ?                  -_rangeOfUnit:startTime:interval:forAT: call site not a recognised dispatch macro */
/*   CFCalendar.c:3004      ?                  -_ordinalityOfUnit:inUnit:forAT:   call site not a recognised dispatch macro */
/*   CFCharacterSet.c:2300  ?                  -addCharactersInRange:             call site not a recognised dispatch macro */
/*   CFCharacterSet.c:2369  ?                  -removeCharactersInRange:          call site not a recognised dispatch macro */
/*   CFData.c:528           ?                  -getBytes:range:                   call site not a recognised dispatch macro */
/*   CFData.c:620           ?                  -replaceBytesInRange:withBytes:length: call site not a recognised dispatch macro */
/*   CFData.c:627           ?                  -replaceBytesInRange:withBytes:length: call site not a recognised dispatch macro */
/*   CFDictionary.c:189     ?                  -_cfMutableCopy                    call site not a recognised dispatch macro */
/*   CFDictionary.c:305     ?                  -enumerateKeysAndObjectsWithOptions:usingBlock: call site not a recognised dispatch macro */
/*   CFError.c:456          NSError            -localizedDescription              CF_OBJC_CALLV: return type from context */
/*   CFError.c:465          NSError            -localizedFailureReason            CF_OBJC_CALLV: return type from context */
/*   CFError.c:474          NSError            -localizedRecoverySuggestion       CF_OBJC_CALLV: return type from context */
/*   CFRunLoop.c:4753       ?                  -setTolerance:                     call site not a recognised dispatch macro */
/*   CFRuntime.c:755        ?                  -_cfTypeID                         call site not a recognised dispatch macro */
/*   CFStream.c:970         NSInputStream      -open                              CF_OBJC_CALLV: return type from context */
/*   CFStream.c:978         NSOutputStream     -open                              CF_OBJC_CALLV: return type from context */
/*   CFStream.c:1073        NSInputStream      -getBuffer:length:                 CF_OBJC_CALLV: return type from context */
/*   CFString.c:1213        NSString           -getCharacters:range:              CF_OBJC_CALLV: return type from context */
/*   CFString.c:1216        NSString           -getCharacters:range:              CF_OBJC_CALLV: return type from context */
/*   CFString.c:1217        NSString           -getCharacters:range:              CF_OBJC_CALLV: return type from context */
/*   CFString.c:1218        NSString           -getCharacters:range:              CF_OBJC_CALLV: return type from context */
/*   CFString.c:2167        ?                  -getCharacters:range:              call site not a recognised dispatch macro */
/*   CFString.c:2236        ?                  -_fastCStringContents:             call site not a recognised dispatch macro */
/*   CFString.c:2324        ?                  -_getCString:maxLength:encoding:   call site not a recognised dispatch macro */
/*   CFString.c:4764        ?                  -getLineStart:end:contentsEnd:forRange: call site not a recognised dispatch macro */
/*   CFString.c:4769        ?                  -getParagraphStart:end:contentsEnd:forRange: call site not a recognised dispatch macro */
/*   CFString.c:5021        ?                  -deleteCharactersInRange:          call site not a recognised dispatch macro */
/*   CFString.c:5030        ?                  -replaceCharactersInRange:withString: call site not a recognised dispatch macro */
/*   CFString.c:5058        ?                  -appendCharacters:length:          call site not a recognised dispatch macro */
/*   CFString.c:5188        ?                  -replaceOccurrencesOfString:withString:options:range: call site not a recognised dispatch macro */
/*   CFString.c:5278        ?                  -_cfPad:length:padIndex:           call site not a recognised dispatch macro */
/*   CFString.c:5329        ?                  -_cfTrim:                          call site not a recognised dispatch macro */
/*   CFString.c:5722        ?                  -_cfNormalize:                     call site not a recognised dispatch macro */
/*   CFTimeZone.c:1597      ?                  -_daylightSavingTimeOffsetForAbsoluteTime: call site not a recognised dispatch macro */
/*   CFTimeZone.c:1612      ?                  -_nextDaylightSavingTimeTransitionAfterAbsoluteTime: call site not a recognised dispatch macro */
/*   CFURL.c:2926           NSURL              -absoluteURL                       CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3133           NSURL              -scheme                            CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3359           NSURL              -host                              CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3386           NSURL              -port                              CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3414           NSURL              -user                              CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3433           NSURL              -password                          CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3462           NSURL              -query                             CF_OBJC_CALLV: return type from context */
/*   CFURL.c:3499           NSURL              -fragment                          CF_OBJC_CALLV: return type from context */
/*   CFURL.c:5221           NSURL              -isFileReferenceURL                CF_OBJC_CALLV: return type from context */
