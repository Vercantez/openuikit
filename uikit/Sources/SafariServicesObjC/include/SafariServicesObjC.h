/* SafariServicesObjC.h — the Objective-C view of OpenUIKit's SafariServices
 * (see module.modulemap). The declarations are those swiftc emits for the
 * Swift module in SafariServices-Swift.h, restated here because that header
 * belongs to a module map without `export *`. They carry the same
 * external_source_symbol(defined_in="SafariServices", generated_declaration)
 * attribute, so a Swift importer (an app's bridging header) resolves them to
 * the Swift classes rather than to new Clang ones, and an Objective-C
 * category declared on them attaches to the Swift class at run time (its
 * runtime name is UIKit's `SFSafariViewController`).
 *
 * Tests/SafariObjCTests checks every method declared here against the Swift
 * class's Objective-C methods. */
#ifndef OPENUIKIT_SAFARISERVICES_OBJC_H
#define OPENUIKIT_SAFARISERVICES_OBJC_H

#import <Foundation/Foundation.h>
#if !__swift__
/* Objective-C: OpenUIKit's Objective-C interfaces (UIViewController and the
 * rest of UIKit), re-exported like the SDK framework's UIKit import. */
@import OpenUIKit;
#else
/* Swift (an app's bridging header): Swift has no Clang module `OpenUIKit`
 * (SwiftPM generates that map for Clang targets only; MEASURED "module
 * 'OpenUIKit' not found"). The superclass chain is declared as OpenUIKit's
 * Swift-generated declarations, so Swift resolves it to the native classes. */
#pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="OpenUIKit", generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
@interface UIResponder : NSObject
@end
@interface UIViewController : UIResponder
@end
#pragma clang attribute pop
#endif

#pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="SafariServices", generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))

NS_ASSUME_NONNULL_BEGIN

__attribute__((swift_name("SFSafariViewController.Configuration")))
@interface SFSafariViewControllerConfiguration : NSObject
@property (nonatomic) BOOL entersReaderIfAvailable;
@property (nonatomic) BOOL barCollapsingEnabled;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
@end

typedef NS_ENUM(NSInteger, SFSafariViewControllerDismissButtonStyle) {
    SFSafariViewControllerDismissButtonStyleDone = 0,
    SFSafariViewControllerDismissButtonStyleClose = 1,
    SFSafariViewControllerDismissButtonStyleCancel = 2,
} NS_SWIFT_NAME(SFSafariViewController.DismissButtonStyle);

/* iOS 26.1 (Tools/oracle2/safariobjcprobe): -initWithURL: accepts http and
 * https only and raises NSInvalidArgumentException for any other scheme. */
@interface SFSafariViewController : UIViewController
@property (nonatomic, readonly, strong) SFSafariViewControllerConfiguration *configuration;
@property (nonatomic) SFSafariViewControllerDismissButtonStyle dismissButtonStyle;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL configuration:(SFSafariViewControllerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END

#pragma clang attribute pop

#endif
