#import <Foundation/NSObject.h>

#include <stdio.h>

@interface OpenFoundationHeaderProbe : NSObject <NSCopying, NSSecureCoding>
@end

@implementation OpenFoundationHeaderProbe

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    (void)zone;
    return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    (void)coder;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    (void)coder;
    return [self init];
}

@end

int main(void) {
    OpenFoundationHeaderProbe *value = [[OpenFoundationHeaderProbe alloc] init];
    if (value == nil || ![value isKindOfClass:[NSObject class]]) {
        return 10;
    }
    id copied = [value copyWithZone:NULL];
    if (copied != value) {
        return 11;
    }
    [copied release];
    [value release];
    puts("FOUNDATION_OBJC_NSOBJECT_HEADER_OK protocols=copying,coding,secure-coding runtime=objc-root");
    return 0;
}
