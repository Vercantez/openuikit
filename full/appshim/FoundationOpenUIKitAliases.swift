// Notification-family identities exported by the Linux-hosted Mach-O guest
// Foundation umbrella.
//
// OpenUIKit is compiled while a module named Foundation is deliberately
// hidden.  Its notification value, Objective-C carrier, center, and queue are
// consequently the declarations embedded in the already-built framework.
// The app-facing Foundation module is compiled later and must alias those
// exact declarations: defining lookalikes here would make a Foundation-only
// model extension invisible to a UIKit-only consumer and would make a source
// file that imports both modules ambiguous.
//
// This file is intentionally shared by the reusable FoundationGuest umbrella
// and the narrow build_full measuring shim.  Every production compilation of
// either input must include this file so the two paths cannot drift.
import OpenUIKit

public typealias Notification = OpenUIKit.Notification
public typealias NotificationCenter = OpenUIKit.NotificationCenter
public typealias OperationQueue = OpenUIKit.OperationQueue

#if canImport(ObjectiveC)
// This is OpenUIKit's NSObject bridge carrier for its hidden Notification
// value, not a claim that the complete Foundation.NSNotification class has
// been ported.  The bounded contract is construction plus name/object/userInfo
// preservation across the Swift/Objective-C notification bridge.  Coding,
// copying, KVC, and interoperability with an Apple Foundation center remain
// outside this guest umbrella slice.
public typealias NSNotification = OpenUIKit.NSNotification
#endif

// Deliberately no NotificationToken alias.  The hidden OpenUIKit center owns
// its token type; Foundation has no public NotificationToken spelling.
