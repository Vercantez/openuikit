// Umbrella of the Clang side of the UIKit module. Every UIKit declaration is
// Swift (Sources/UIKitShim re-exports OpenUIKit) except the one below.
#ifndef OPENUIKIT_UIKIT_CLANG_MODULE_H
#define OPENUIKIT_UIKIT_CLANG_MODULE_H

// The Foundation-hidden Mach-O guest builds this module too (no Foundation):
// there the declaration is absent, as is its @_cdecl implementation.
#if __has_include(<Foundation/Foundation.h>)
#import <Foundation/Foundation.h>

// UIApplication.h's C entry point, verbatim in shape. Swift's
// `@UIApplicationMain` attribute synthesizes `main` as a call to THIS
// declaration: SILGen looks `UIApplicationMain` up in the UIKit module and
// takes the result that has a Clang node (Eidolon's AppDelegate.swift:8;
// without it swift-frontend crashed in SILDeclRef::mangle while emitting
// `Kiosk_main`, docs/agent_reports/eidolon-kiosk.md). A `main.swift` that
// calls `UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
// NSStringFromClass(AppDelegate.self))` binds to it too. OpenUIKit implements
// it (@_cdecl, UIApplicationMainEntry.swift): the delegate class by name,
// then the same headless launch and main loop as `@main`.
FOUNDATION_EXPORT int UIApplicationMain(int argc, char * _Nullable argv[_Nonnull],
                                        NSString * _Nullable principalClassName,
                                        NSString * _Nullable delegateClassName);
#endif

#endif
