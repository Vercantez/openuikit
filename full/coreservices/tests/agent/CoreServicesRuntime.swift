import CoreServices
import Foundation

func takeString(_ value: Unmanaged<CFString>?) -> String? {
    value.map { $0.takeRetainedValue() as String }
}

func takeStrings(_ value: Unmanaged<CFArray>?) -> [String]? {
    guard let array = value?.takeRetainedValue() as? [Any] else { return nil }
    return array.map { String(describing: $0) }
}

func takeDictionary(_ value: Unmanaged<CFDictionary>?) -> NSDictionary? {
    value?.takeRetainedValue()
}

precondition((kUTTypePNG as String) == "public.png")
precondition((kUTTypeJPEG as String) == "public.jpeg")
precondition((kUTTypeGIF as String) == "com.compuserve.gif")
precondition((kUTTypePDF as String) == "com.adobe.pdf")
precondition((kUTTypeURL as String) == "public.url")
precondition((kUTTypeFileURL as String) == "public.file-url")
precondition((kUTTypeSwiftSource as String) == "public.swift-source")
precondition((kUTTagClassFilenameExtension as String) == "public.filename-extension")
precondition((kUTTagClassMIMEType as String) == "public.mime-type")
precondition((kUTTypeIdentifierKey as String) == "UTTypeIdentifier")
precondition((kUTExportedTypeDeclarationsKey as String) == "UTExportedTypeDeclarations")

precondition(UTTypeEqual(kUTTypePNG, kUTTypePNG))
precondition(UTTypeEqual(kUTTypePNG, "public.png" as CFString))
precondition(UTTypeEqual(kUTTypePNG, "PUBLIC.PNG" as CFString))
precondition(!UTTypeEqual(kUTTypePNG, kUTTypeJPEG))

precondition(UTTypeConformsTo(kUTTypePNG, kUTTypePNG))
precondition(UTTypeConformsTo(kUTTypePNG, kUTTypeImage))
precondition(UTTypeConformsTo(kUTTypePNG, kUTTypeData))
precondition(UTTypeConformsTo(kUTTypePNG, kUTTypeItem))
precondition(UTTypeConformsTo(kUTTypePNG, kUTTypeContent))
precondition(!UTTypeConformsTo(kUTTypePNG, kUTTypeAudio))
precondition(!UTTypeConformsTo(kUTTypeImage, kUTTypePNG))
precondition(UTTypeConformsTo(kUTTypeSwiftSource, kUTTypeSourceCode))
precondition(UTTypeConformsTo(kUTTypeSwiftSource, kUTTypeText))
precondition(UTTypeConformsTo(kUTTypeMPEG4, kUTTypeMovie))
precondition(UTTypeConformsTo(kUTTypeApplicationBundle, kUTTypeApplication))

precondition(UTTypeIsDeclared(kUTTypePNG))
precondition(UTTypeIsDeclared(kUTTypeItem))
precondition(!UTTypeIsDeclared("com.example.unknown-type" as CFString))
precondition(!UTTypeIsDynamic(kUTTypePNG))
precondition(UTTypeIsDynamic("dyn.example" as CFString))
precondition(!UTTypeIsDeclared("dyn.example" as CFString))

precondition(takeString(UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassFilenameExtension)) == "png")
precondition(takeString(UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassMIMEType)) == "image/png")
precondition(takeString(UTTypeCopyPreferredTagWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension)) == "jpeg")
precondition(takeStrings(UTTypeCopyAllTagsWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension)) == ["jpeg", "jpg", "jpe"])
precondition(UTTypeCopyPreferredTagWithClass(kUTTypeItem, kUTTagClassFilenameExtension) == nil)
precondition(UTTypeCopyAllTagsWithClass("com.example.unknown-type" as CFString, kUTTagClassMIMEType) == nil)

precondition(takeString(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "png" as CFString, nil)) == "public.png")
precondition(takeString(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ".PNG" as CFString, nil)) == "public.png")
precondition(takeString(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "image/jpeg" as CFString, nil)) == "public.jpeg")
precondition(takeString(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "jpg" as CFString, kUTTypeImage)) == "public.jpeg")
precondition(takeString(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "plist" as CFString, nil)) == "com.apple.property-list")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "not-a-real-extension" as CFString, nil) == nil)
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "png" as CFString, kUTTypeAudio) == nil)

let pngIdentifiers = takeStrings(
    UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, "png" as CFString, nil)
)
precondition(pngIdentifiers == ["public.png"])

let plistIdentifiers = takeStrings(
    UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, "plist" as CFString, nil)
)
precondition(plistIdentifiers == [
    "com.apple.binary-property-list",
    "com.apple.property-list",
    "com.apple.xml-property-list",
])

guard let declaration = takeDictionary(UTTypeCopyDeclaration(kUTTypePNG)) else {
    fatalError("declared PNG type must produce a declaration dictionary")
}
precondition(declaration[kUTTypeIdentifierKey] as? String == "public.png")
precondition(declaration[kUTTypeConformsToKey] as? String == "public.image")
guard let tags = declaration[kUTTypeTagSpecificationKey] as? NSDictionary else {
    fatalError("PNG declaration must include tag specification")
}
precondition(tags[kUTTagClassFilenameExtension] as? String == "png")
precondition(tags[kUTTagClassMIMEType] as? String == "image/png")
precondition(UTTypeCopyDeclaration("com.example.unknown-type" as CFString) == nil)
precondition(UTTypeCopyDeclaration("dyn.example" as CFString) == nil)

precondition(UTTypeCopyDeclaringBundleURL(kUTTypePNG) == nil)
precondition(UTTypeCopyDeclaringBundleURL("dyn.example" as CFString) == nil)
precondition(UTTypeCopyDescription(kUTTypePNG) == nil)
precondition(UTTypeCopyDescription(kUTTypeItem) == nil)

precondition(UTTypeConformsTo("com.example.unknown-type" as CFString, "com.example.unknown-type" as CFString))
precondition(!UTTypeConformsTo("com.example.unknown-type" as CFString, kUTTypeItem))

print("CORESERVICES_AGENT_RUNTIME_OK")
