// OUKFlowLayoutScenario — Objective-C subclasses of UICollectionViewFlowLayout
// (shaped like ARCollectionViewMasonryLayout 2.0.0, Eidolon's listings grid)
// driving a UICollectionView in a window, producing a call trace.
//
// The SAME translation unit is compiled twice:
//   * against Apple's UIKit for the iOS 26.1 simulator (../run.sh), which
//     writes ../transcript-ios26.1.txt;
//   * against OpenUIKit's generated Objective-C header (SwiftPM target
//     `OpenUIKitFlowLayoutFixtures`, OUK_OPENUIKIT=1), where
//     Tests/ObjCSubclassingTests/FlowLayoutObjCTests.swift compares traces.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs every section and returns the trace, one event per element.
FOUNDATION_EXPORT NSArray<NSString *> *OUKRunFlowLayoutScenario(void);

NS_ASSUME_NONNULL_END
