// The guest's <Foundation/Foundation.h>: the Objective-C view of the one
// Foundation in the process (full/foundation's Swift facade plus
// full/objcfoundation/bridge). See NSObjCRuntime.h for how the two languages
// meet, and docs/agent_reports/guest-objc-foundation.md for what is covered.
#ifndef OF_FOUNDATION_FOUNDATION_H
#define OF_FOUNDATION_FOUNDATION_H

#include <assert.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#if !defined(__swift__)
// Objective-C code reaches dispatch_once & co. through Foundation.h, as with
// the SDK. Swift has the guest's own Dispatch module.
#include <Block.h>
#include <dispatch/dispatch.h>
#endif

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSError.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSHFSFileTypes.h>

#endif
