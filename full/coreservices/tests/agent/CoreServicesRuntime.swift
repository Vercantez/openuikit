import CoreServices
import Foundation

precondition(kUTTypePNG == "public.png")
precondition(kUTTypeJPEG == "public.jpeg")
precondition(kUTTypeGIF == "com.compuserve.gif")
precondition(kUTTypePDF == "com.adobe.pdf")
precondition(kUTTypeURL == "public.url")
precondition(kUTTypeFileURL == "public.file-url")
precondition(kUTTypeSwiftSource == "public.swift-source")
precondition(kUTTagClassFilenameExtension == "public.filename-extension")
precondition(kUTTagClassMIMEType == "public.mime-type")
precondition(kUTTypeIdentifierKey == "UTTypeIdentifier")
precondition(kUTExportedTypeDeclarationsKey == "UTExportedTypeDeclarations")

precondition(UTTypeEqual(kUTTypePNG, kUTTypePNG))
precondition(UTTypeEqual(kUTTypePNG, "public.png"))
precondition(UTTypeEqual(kUTTypePNG, "PUBLIC.PNG"))
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
precondition(!UTTypeIsDeclared("com.example.unknown-type"))
precondition(!UTTypeIsDynamic(kUTTypePNG))
precondition(UTTypeIsDynamic("dyn.example"))
precondition(!UTTypeIsDeclared("dyn.example"))

precondition(UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassFilenameExtension) == "png")
precondition(UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassMIMEType) == "image/png")
precondition(UTTypeCopyPreferredTagWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension) == "jpeg")
precondition(UTTypeCopyAllTagsWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension) == ["jpeg", "jpg", "jpe"])
precondition(UTTypeCopyPreferredTagWithClass(kUTTypeItem, kUTTagClassFilenameExtension) == nil)
precondition(UTTypeCopyAllTagsWithClass("com.example.unknown-type", kUTTagClassMIMEType) == nil)

precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "png", nil) == "public.png")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ".PNG", nil) == "public.png")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "image/jpeg", nil) == "public.jpeg")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "jpg", kUTTypeImage) == "public.jpeg")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "plist", nil) == "com.apple.property-list")
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "not-a-real-extension", nil) == nil)
precondition(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "png", kUTTypeAudio) == nil)

precondition(
    UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, "png", nil) == ["public.png"]
)
precondition(
    UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, "plist", nil) == [
        "com.apple.binary-property-list",
        "com.apple.property-list",
        "com.apple.xml-property-list",
    ]
)

guard let declaration = UTTypeCopyDeclaration(kUTTypePNG) else {
    fatalError("declared PNG type must produce a declaration dictionary")
}
precondition(declaration[kUTTypeIdentifierKey] as? String == "public.png")
precondition(declaration[kUTTypeConformsToKey] as? String == "public.image")
guard let tags = declaration[kUTTypeTagSpecificationKey] as? [String: Any] else {
    fatalError("PNG declaration must include tag specification")
}
precondition(tags[kUTTagClassFilenameExtension] as? String == "png")
precondition(tags[kUTTagClassMIMEType] as? String == "image/png")
precondition(UTTypeCopyDeclaration("com.example.unknown-type") == nil)
precondition(UTTypeCopyDeclaration("dyn.example") == nil)

precondition(UTTypeCopyDeclaringBundleURL(kUTTypePNG) == nil)
precondition(UTTypeCopyDeclaringBundleURL("dyn.example") == nil)
precondition(UTTypeCopyDescription(kUTTypePNG) == nil)
precondition(UTTypeCopyDescription(kUTTypeItem) == nil)

precondition(UTTypeConformsTo("com.example.unknown-type", "com.example.unknown-type"))
precondition(!UTTypeConformsTo("com.example.unknown-type", kUTTypeItem))

print("CORESERVICES_AGENT_RUNTIME_OK")
