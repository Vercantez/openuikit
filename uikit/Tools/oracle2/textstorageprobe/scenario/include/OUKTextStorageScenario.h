// OUKTextStorageScenario — Foundation attributed strings and UIKit's
// NSTextStorage driven from Objective-C, producing a trace.
//
// The SAME translation unit is compiled twice:
//   * against Apple's UIKit for the iOS 26.1 simulator (run.sh), which writes
//     transcript-ios26.1.txt next to this directory;
//   * against OpenUIKit's generated Objective-C header (SwiftPM target
//     `OpenUIKitTextStorageFixtures`, OUK_OPENUIKIT=1), where
//     Tests/AttributedStringUnifyTests compares its trace with that transcript.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Plain Foundation NSMutableAttributedString semantics OpenUIKit relies on
/// (run coalescing, enumeration, replacement attributes, UTF-16 indices).
FOUNDATION_EXPORT NSArray<NSString *> *OUKRunAttributedStringScenarios(void);

/// NSTextStorage: class facts, edit/processEditing/delegate/notification
/// ordering, and an Objective-C subclass over a backing store (the shape of
/// Simplenote's SPInteractiveTextStorage).
FOUNDATION_EXPORT NSArray<NSString *> *OUKRunTextStorageScenarios(void);

/// A fresh instance of the scenario's Objective-C NSTextStorage subclass.
FOUNDATION_EXPORT id OUKMakeObjCTextStorage(void);

NS_ASSUME_NONNULL_END
