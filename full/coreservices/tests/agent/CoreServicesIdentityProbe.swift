import CoreFoundation
import CoreServices
import Foundation

func sameIdentity<T>(_: T.Type, _: T.Type) {}

sameIdentity(String.self, CFString.self)
sameIdentity(URL.self, CFURL.self)
sameIdentity([String: Any].self, CFDictionary.self)

let _: (CFString, CFString) -> Bool = UTTypeEqual
let _: (CFString, CFString) -> Bool = UTTypeConformsTo
let _: (CFString) -> Bool = UTTypeIsDeclared
let _: (CFString) -> Bool = UTTypeIsDynamic
let _: (CFString, CFString) -> CFString? = UTTypeCopyPreferredTagWithClass
let _: (CFString, CFString) -> [CFString]? = UTTypeCopyAllTagsWithClass
let _: (CFString) -> CFDictionary? = UTTypeCopyDeclaration
let _: (CFString) -> CFURL? = UTTypeCopyDeclaringBundleURL
let _: (CFString) -> CFString? = UTTypeCopyDescription
let _: (CFString, CFString, CFString?) -> CFString? = UTTypeCreatePreferredIdentifierForTag
let _: (CFString, CFString, CFString?) -> [CFString]? = UTTypeCreateAllIdentifiersForTag

let _: CFString = kUTTypePNG
let _: CFString = kUTTagClassFilenameExtension

print("CORESERVICES_CF_IDENTITY_OK")
