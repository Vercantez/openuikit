// OUKSubclassScenario — Objective-C subclasses of UIKit classes, driven from
// Objective-C, producing a call trace.
//
// The SAME translation unit is compiled twice:
//   * against Apple's UIKit for the iOS 26.1 simulator (run.sh), which writes
//     the oracle transcript next to this directory;
//   * against OpenUIKit's generated Objective-C header (SwiftPM target
//     `OpenUIKitObjCSubclassFixtures`, OUK_OPENUIKIT=1), where
//     Tests/ObjCSubclassingTests compares its trace with that transcript.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs every scenario and returns the trace, one event per element.
FOUNDATION_EXPORT NSArray<NSString *> *OUKRunSubclassScenarios(void);

/// Superclass names (class_getSuperclass) of the UIKit types whose class
/// kind OpenUIKit changes, as "Type:Superclass" lines.
FOUNDATION_EXPORT NSArray<NSString *> *OUKSuperclassFacts(void);

/// A fresh instance of the scenario's Objective-C UIView subclass (for the
/// Swift-side tests: casts, Swift extension dispatch, rendering).
FOUNDATION_EXPORT id OUKMakeObjCView(void);

/// The scenario's trace buffer (cleared by OUKRunSubclassScenarios).
FOUNDATION_EXPORT NSMutableArray<NSString *> *OUKTrace(void);

NS_ASSUME_NONNULL_END
