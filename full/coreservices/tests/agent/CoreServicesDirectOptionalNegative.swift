import CoreServices
import Foundation

// Expected to fail: direct-optional substitutes must not occupy the pinned
// Copy/Create names. takeRetainedValue() callers are not source-compatible
// until Unmanaged CF signatures exist.
let _: (String, String) -> String? = UTTypeCopyPreferredTagWithClass
let _: (String, String) -> [String]? = UTTypeCopyAllTagsWithClass
let _: (String) -> [String: Any]? = UTTypeCopyDeclaration
let _: (String) -> URL? = UTTypeCopyDeclaringBundleURL
let _: (String) -> String? = UTTypeCopyDescription
let _: (String, String, String?) -> String? = UTTypeCreatePreferredIdentifierForTag
let _: (String, String, String?) -> [String]? = UTTypeCreateAllIdentifiersForTag
