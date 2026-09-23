/* Route-(b) UIKit umbrella for CocoaPods Objective-C sources
 * (Tools/ingest/objc_pods_package.py). OpenUIKit-Swift.h is emitted by
 * SwiftPM for the OpenUIKit target; the support header carries the
 * enums/structs/protocols it cannot. */
#ifndef OPENUIKIT_ROUTE_B_UIKIT_H
#define OPENUIKIT_ROUTE_B_UIKIT_H
#import <Foundation/Foundation.h>
/* Apple's <UIKit/UIKit.h> imports QuartzCore, and on Apple toolchains
 * OpenUIKit's Core Animation classes ARE QuartzCore's (cg-unify phase 3). */
#if __has_include(<QuartzCore/QuartzCore.h>)
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#endif
#import "OpenUIKit-Swift.h"
#import "UIKitObjCSupport.h"
#if !__swift__
#import "OpenUIKitObjCBridge-Swift.h"
/* UIKit classes implemented in Objective-C over OpenUIKit (UIAlertView). */
#if __has_include("OpenUIKitObjCClasses.h")
#import "OpenUIKitObjCClasses.h"
#endif
#endif
#endif
