#import "Stripe.h"

NSString *const STPShimErrorDomain = @"STPShimServiceUnavailable";

@implementation STPAddress
@end

@implementation STPCardParams
- (instancetype)init {
    if ((self = [super init])) {
        _address = [STPAddress new];
    }
    return self;
}
@end

@implementation STPCard
@end

@implementation STPToken
@end

@implementation Stripe
+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    // Accepting configuration neither enables a service nor retains the key.
}
@end

@implementation STPAPIClient
+ (instancetype)sharedClient {
    static STPAPIClient *client;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ client = [self new]; });
    return client;
}

- (void)createTokenWithCard:(STPCardParams *)card completion:(STPTokenCompletionBlock)completion {
    // StripeManager.swift force-unwraps the error when token is nil: always one
    // failure callback with a nonnil error; never a token.
    if (completion) {
        completion(nil, [NSError errorWithDomain:STPShimErrorDomain code:1 userInfo:nil]);
    }
}
@end

@implementation STPCardValidator
+ (STPCardValidationState)validationStateForNumber:(NSString *)cardNumber
                               validatingCardBrand:(BOOL)validatingCardBrand {
    // Fail closed: no number is ever reported valid.
    return STPCardValidationStateInvalid;
}
@end
