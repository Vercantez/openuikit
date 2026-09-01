@_spi(OpenUIKitHost) import CoreServices
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

precondition(
    OpenUIKitHostUTType.copyPreferredTag(
        for: kUTTypePNG,
        tagClass: kUTTagClassFilenameExtension
    ) == "png"
)
precondition(
    OpenUIKitHostUTType.copyPreferredTag(
        for: kUTTypePNG,
        tagClass: kUTTagClassMIMEType
    ) == "image/png"
)
precondition(
    OpenUIKitHostUTType.copyPreferredTag(
        for: kUTTypeJPEG,
        tagClass: kUTTagClassFilenameExtension
    ) == "jpeg"
)
precondition(
    OpenUIKitHostUTType.copyAllTags(
        for: kUTTypeJPEG,
        tagClass: kUTTagClassFilenameExtension
    ) == ["jpeg", "jpg", "jpe"]
)
precondition(
    OpenUIKitHostUTType.copyPreferredTag(
        for: kUTTypeItem,
        tagClass: kUTTagClassFilenameExtension
    ) == nil
)
precondition(
    OpenUIKitHostUTType.copyAllTags(
        for: "com.example.unknown-type",
        tagClass: kUTTagClassMIMEType
    ) == nil
)

precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: "png",
        conformingTo: nil
    ) == "public.png"
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: ".PNG",
        conformingTo: nil
    ) == "public.png"
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassMIMEType,
        tag: "image/jpeg",
        conformingTo: nil
    ) == "public.jpeg"
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: "jpg",
        conformingTo: kUTTypeImage
    ) == "public.jpeg"
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: "plist",
        conformingTo: nil
    ) == "com.apple.property-list"
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: "not-a-real-extension",
        conformingTo: nil
    ) == nil
)
precondition(
    OpenUIKitHostUTType.createPreferredIdentifier(
        tagClass: kUTTagClassFilenameExtension,
        tag: "png",
        conformingTo: kUTTypeAudio
    ) == nil
)

precondition(
    OpenUIKitHostUTType.createAllIdentifiers(
        tagClass: kUTTagClassFilenameExtension,
        tag: "png",
        conformingTo: nil
    ) == ["public.png"]
)
precondition(
    OpenUIKitHostUTType.createAllIdentifiers(
        tagClass: kUTTagClassFilenameExtension,
        tag: "plist",
        conformingTo: nil
    ) == [
        "com.apple.binary-property-list",
        "com.apple.property-list",
        "com.apple.xml-property-list",
    ]
)

guard let declaration = OpenUIKitHostUTType.copyDeclaration(for: kUTTypePNG) else {
    fatalError("declared PNG type must produce a declaration dictionary")
}
precondition(declaration[kUTTypeIdentifierKey] as? String == "public.png")
precondition(declaration[kUTTypeConformsToKey] as? String == "public.image")
guard let tags = declaration[kUTTypeTagSpecificationKey] as? [String: Any] else {
    fatalError("PNG declaration must include tag specification")
}
precondition(tags[kUTTagClassFilenameExtension] as? String == "png")
precondition(tags[kUTTagClassMIMEType] as? String == "image/png")
precondition(OpenUIKitHostUTType.copyDeclaration(for: "com.example.unknown-type") == nil)
precondition(OpenUIKitHostUTType.copyDeclaration(for: "dyn.example") == nil)

precondition(OpenUIKitHostUTType.copyDeclaringBundleURL(for: kUTTypePNG) == nil)
precondition(OpenUIKitHostUTType.copyDeclaringBundleURL(for: "dyn.example") == nil)
precondition(OpenUIKitHostUTType.copyDescription(for: kUTTypePNG) == nil)
precondition(OpenUIKitHostUTType.copyDescription(for: kUTTypeItem) == nil)

precondition(UTTypeConformsTo("com.example.unknown-type", "com.example.unknown-type"))
precondition(!UTTypeConformsTo("com.example.unknown-type", kUTTypeItem))

print("CORESERVICES_AGENT_RUNTIME_OK")
