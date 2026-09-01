import CoreServices
import Foundation

// Expected to fail: pinned Copy/Create APIs are Unmanaged CF returns.
// Staged Foundation CFString is String and CFArray is absent, so these
// canonical names must not exist as a weakened public surface either.
let _: (String, String) -> Unmanaged<String>? = UTTypeCopyPreferredTagWithClass
let _: (String, String) -> Unmanaged<[Any]>? = UTTypeCopyAllTagsWithClass
let _: (String) -> Unmanaged<[String: Any]>? = UTTypeCopyDeclaration
let _: (String) -> Unmanaged<URL>? = UTTypeCopyDeclaringBundleURL
let _: (String) -> Unmanaged<String>? = UTTypeCopyDescription
let _: (String, String, String?) -> Unmanaged<String>? = UTTypeCreatePreferredIdentifierForTag
let _: (String, String, String?) -> Unmanaged<[Any]>? = UTTypeCreateAllIdentifiersForTag
