#import <Foundation/Foundation.h>
/// Runs `block`; returns nil, or "Name: reason" of an Objective-C exception
/// it raised. Lets the probe record UIKit's NSUnknownKeyException for an
/// archive whose custom class is absent instead of terminating.
NSString *_Nullable OUKTry(void (NS_NOESCAPE ^_Nonnull block)(void));
