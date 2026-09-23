// FAIL-CLOSED shim for Stripe 12.1.0 (Eidolon Podfile.lock; Podfile asks 14.0.1).
// Same surface as uikit/Sources/EidolonServiceShims/Stripe/Stripe.swift, plus
// STPCardValidator, which Kiosk/App/CreditCardValidation.m calls from ObjC.
// Names follow Stripe 12.1.0 public headers (STPAPIClient.h, STPCardParams.h,
// STPAddress.h, STPCard.h, STPToken.h, STPCardBrand.h, STPCardValidator.h,
// STPCardValidationState.h). No network, no token, no card is ever produced.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPCardBrand) {
    STPCardBrandVisa,
    STPCardBrandAmex,
    STPCardBrandMasterCard,
    STPCardBrandDiscover,
    STPCardBrandJCB,
    STPCardBrandDinersClub,
    STPCardBrandUnknown,
};

typedef NS_ENUM(NSInteger, STPCardValidationState) {
    STPCardValidationStateValid,
    STPCardValidationStateInvalid,
    STPCardValidationStateIncomplete,
};

@interface STPAddress : NSObject
@property (nonatomic, copy, nullable) NSString *postalCode;
@end

@interface STPCardParams : NSObject
@property (nonatomic, copy, nullable) NSString *number;
@property (nonatomic) NSUInteger expMonth;
@property (nonatomic) NSUInteger expYear;
@property (nonatomic, copy, nullable) NSString *cvc;
@property (nonatomic, strong) STPAddress *address;
@end

@interface STPCard : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly) NSString *last4;
@property (nonatomic, readonly) STPCardBrand brand;
@end

@interface STPToken : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property (nonatomic, readonly) NSString *tokenId;
@property (nonatomic, readonly, nullable) STPCard *card;
@end

typedef void (^STPTokenCompletionBlock)(STPToken * __nullable token, NSError * __nullable error);

extern NSString *const STPShimErrorDomain;

@interface Stripe : NSObject
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;
@end

@interface STPAPIClient : NSObject
+ (instancetype)sharedClient;
- (void)createTokenWithCard:(STPCardParams *)card completion:(nullable STPTokenCompletionBlock)completion;
@end

@interface STPCardValidator : NSObject
+ (STPCardValidationState)validationStateForNumber:(nullable NSString *)cardNumber
                               validatingCardBrand:(BOOL)validatingCardBrand;
@end

NS_ASSUME_NONNULL_END
