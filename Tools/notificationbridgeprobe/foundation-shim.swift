// Minimal app-facing Foundation identity shim used only by this fail-closed
// guest oracle. Production's FoundationGuest.swift must publish the same
// aliases before unchanged Foundation+UIKit apps use this slice end to end.

@_exported import FoundationEssentials
import OpenUIKit

public typealias Notification = OpenUIKit.Notification
public typealias NSNotification = OpenUIKit.NSNotification
public typealias NotificationCenter = OpenUIKit.NotificationCenter
public typealias OperationQueue = OpenUIKit.OperationQueue
