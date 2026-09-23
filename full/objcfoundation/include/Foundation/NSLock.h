// NSLock = the Swift facade's Foundation.NSLock.
#ifndef OF_FOUNDATION_NSLOCK_H
#define OF_FOUNDATION_NSLOCK_H

#import <Foundation/NSObject.h>

@class NSString, NSDate;

#if !defined(__swift__)
@protocol NSLocking
- (void)lock;
- (void)unlock;
@end
#endif

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation6NSLock", "Foundation")
@interface NSLock : NSObject
#if !defined(__swift__)
<NSLocking>
- (void)lock;
- (void)unlock;
- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
@property (nullable, copy) NSString *name;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
