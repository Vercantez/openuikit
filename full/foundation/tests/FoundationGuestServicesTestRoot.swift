// Test-only app-facing Foundation root. OpenUIKit remains the sole owner of
// every UIKit-visible reference identity while FoundationEssentials supplies
// value and filesystem services.
@_exported import FoundationEssentials
import OpenUIKit

public typealias Bundle = OpenUIKit.Bundle
