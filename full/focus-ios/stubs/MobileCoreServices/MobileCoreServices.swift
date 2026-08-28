// MobileCoreServices is iOS-only (deprecated in favour of UniformTypeIdentifiers)
// and does not exist in the macOS SDK, so this stub exists to let the two
// focus-ios share-extension files reach the typechecker at all. It is a
// MEASUREMENT ENABLER, not a port: both consumers only need the UTI constants
// to compare against an NSItemProvider type identifier.
import Foundation
public let kUTTypeURL: CFString = "public.url" as CFString
public let kUTTypeText: CFString = "public.text" as CFString
public let kUTTypePlainText: CFString = "public.plain-text" as CFString
public let kUTTypeItem: CFString = "public.item" as CFString
public let kUTTypeData: CFString = "public.data" as CFString
