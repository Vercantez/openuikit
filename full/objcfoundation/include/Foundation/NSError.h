// NSError / NSNull = the Swift facade's classes.
#ifndef OF_FOUNDATION_NSERROR_H
#define OF_FOUNDATION_NSERROR_H

#import <Foundation/NSObject.h>

@class NSDictionary<KeyType, ObjectType>, NSString;

#if !defined(__swift__)
typedef NSString *NSErrorDomain;
typedef NSString *NSErrorUserInfoKey;
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSErrorDomain const NSCocoaErrorDomain;
FOUNDATION_EXPORT NSErrorDomain const NSPOSIXErrorDomain;
FOUNDATION_EXPORT NSErrorDomain const NSOSStatusErrorDomain;
FOUNDATION_EXPORT NSErrorUserInfoKey const NSUnderlyingErrorKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NSLocalizedDescriptionKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NSLocalizedFailureReasonErrorKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NSLocalizedRecoverySuggestionErrorKey;
FOUNDATION_EXPORT NSErrorUserInfoKey const NSFilePathErrorKey;
NS_ASSUME_NONNULL_END
#endif

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation7NSError", "Foundation")
@interface NSError : NSObject
#if !defined(__swift__)
- (instancetype)initWithDomain:(NSErrorDomain)domain code:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict NS_DESIGNATED_INITIALIZER;
+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict;
@property (readonly, copy) NSErrorDomain domain;
@property (readonly) NSInteger code;
@property (readonly, copy) NSDictionary<NSErrorUserInfoKey, id> *userInfo;
@property (readonly, copy) NSString *localizedDescription;
@property (nullable, readonly, copy) NSString *localizedFailureReason;
@property (readonly, copy) NSString *description;
#endif
@end

OF_SWIFT_CLASS("_TtC10Foundation6NSNull", "Foundation")
@interface NSNull : NSObject
#if !defined(__swift__)
+ (NSNull *)null;
@property (readonly, copy) NSString *description;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
