import Foundation
import CoreServices

private func takeString(_ value: Unmanaged<CFString>?) -> String? {
    value?.takeRetainedValue() as String?
}

private func takeStrings(_ value: Unmanaged<CFArray>?) -> [String] {
    guard let array = value?.takeRetainedValue() as NSArray? else {
        return []
    }
    return array.map { String(describing: $0) }
}

private func takeDictionary(_ value: Unmanaged<CFDictionary>?) -> NSDictionary? {
    value?.takeRetainedValue() as NSDictionary?
}

private func assertKeys() {
    precondition((kUTExportedTypeDeclarationsKey as String) == "UTExportedTypeDeclarations")
    precondition((kUTImportedTypeDeclarationsKey as String) == "UTImportedTypeDeclarations")
    precondition((kUTTypeIdentifierKey as String) == "UTTypeIdentifier")
    precondition((kUTTypeTagSpecificationKey as String) == "UTTypeTagSpecification")
    precondition((kUTTypeConformsToKey as String) == "UTTypeConformsTo")
    precondition((kUTTypeDescriptionKey as String) == "UTTypeDescription")
    precondition((kUTTypeIconFileKey as String) == "UTTypeIconFile")
    precondition((kUTTypeReferenceURLKey as String) == "UTTypeReferenceURL")
    precondition((kUTTypeVersionKey as String) == "UTTypeVersion")
    precondition((kUTTagClassFilenameExtension as String) == "public.filename-extension")
    precondition((kUTTagClassMIMEType as String) == "public.mime-type")
}

private func assertTypeConstants() {
    let constants: [(CFString, String)] = [
        (kUTTypeItem, "public.item"),
        (kUTTypeContent, "public.content"),
        (kUTTypeCompositeContent, "public.composite-content"),
        (kUTTypeMessage, "public.message"),
        (kUTTypeContact, "public.contact"),
        (kUTTypeArchive, "public.archive"),
        (kUTTypeDiskImage, "public.disk-image"),
        (kUTTypeData, "public.data"),
        (kUTTypeDirectory, "public.directory"),
        (kUTTypeResolvable, "com.apple.resolvable"),
        (kUTTypeSymLink, "public.symlink"),
        (kUTTypeExecutable, "public.executable"),
        (kUTTypeMountPoint, "com.apple.mount-point"),
        (kUTTypeAliasFile, "com.apple.alias-file"),
        (kUTTypeAliasRecord, "com.apple.alias-record"),
        (kUTTypeURLBookmarkData, "com.apple.bookmark"),
        (kUTTypeURL, "public.url"),
        (kUTTypeFileURL, "public.file-url"),
        (kUTTypeText, "public.text"),
        (kUTTypePlainText, "public.plain-text"),
        (kUTTypeUTF8PlainText, "public.utf8-plain-text"),
        (kUTTypeUTF16ExternalPlainText, "public.utf16-external-plain-text"),
        (kUTTypeUTF16PlainText, "public.utf16-plain-text"),
        (kUTTypeDelimitedText, "public.delimited-values-text"),
        (kUTTypeCommaSeparatedText, "public.comma-separated-values-text"),
        (kUTTypeTabSeparatedText, "public.tab-separated-values-text"),
        (kUTTypeUTF8TabSeparatedText, "public.utf8-tab-separated-values-text"),
        (kUTTypeRTF, "public.rtf"),
        (kUTTypeHTML, "public.html"),
        (kUTTypeXML, "public.xml"),
        (kUTTypeSourceCode, "public.source-code"),
        (kUTTypeAssemblyLanguageSource, "public.assembly-source"),
        (kUTTypeCSource, "public.c-source"),
        (kUTTypeObjectiveCSource, "public.objective-c-source"),
        (kUTTypeSwiftSource, "public.swift-source"),
        (kUTTypeCPlusPlusSource, "public.c-plus-plus-source"),
        (kUTTypeObjectiveCPlusPlusSource, "public.objective-c-plus-plus-source"),
        (kUTTypeCHeader, "public.c-header"),
        (kUTTypeCPlusPlusHeader, "public.c-plus-plus-header"),
        (kUTTypeJavaSource, "com.sun.java-source"),
        (kUTTypeScript, "public.script"),
        (kUTTypeAppleScript, "com.apple.applescript.text"),
        (kUTTypeOSAScript, "com.apple.applescript.script"),
        (kUTTypeOSAScriptBundle, "com.apple.applescript.script-bundle"),
        (kUTTypeJavaScript, "com.netscape.javascript-source"),
        (kUTTypeShellScript, "public.shell-script"),
        (kUTTypePerlScript, "public.perl-script"),
        (kUTTypePythonScript, "public.python-script"),
        (kUTTypeRubyScript, "public.ruby-script"),
        (kUTTypePHPScript, "public.php-script"),
        (kUTTypeJSON, "public.json"),
        (kUTTypePropertyList, "com.apple.property-list"),
        (kUTTypeXMLPropertyList, "com.apple.xml-property-list"),
        (kUTTypeBinaryPropertyList, "com.apple.binary-property-list"),
        (kUTTypePDF, "com.adobe.pdf"),
        (kUTTypeRTFD, "com.apple.rtfd"),
        (kUTTypeFlatRTFD, "com.apple.flat-rtfd"),
        (kUTTypeTXNTextAndMultimediaData, "com.apple.traditional-mac-plain-text"),
        (kUTTypeWebArchive, "com.apple.webarchive"),
        (kUTTypeImage, "public.image"),
        (kUTTypeJPEG, "public.jpeg"),
        (kUTTypeJPEG2000, "public.jpeg-2000"),
        (kUTTypeTIFF, "public.tiff"),
        (kUTTypePICT, "com.apple.pict"),
        (kUTTypeGIF, "com.compuserve.gif"),
        (kUTTypePNG, "public.png"),
        (kUTTypeQuickTimeImage, "com.apple.quicktime-image"),
        (kUTTypeAppleICNS, "com.apple.icns"),
        (kUTTypeBMP, "com.microsoft.bmp"),
        (kUTTypeICO, "com.microsoft.ico"),
        (kUTTypeRawImage, "public.camera-raw-image"),
        (kUTTypeScalableVectorGraphics, "public.svg-image"),
        (kUTTypeLivePhoto, "com.apple.live-photo"),
        (kUTTypeAudiovisualContent, "public.audiovisual-content"),
        (kUTTypeMovie, "public.movie"),
        (kUTTypeVideo, "public.video"),
        (kUTTypeAudio, "public.audio"),
        (kUTTypeQuickTimeMovie, "com.apple.quicktime-movie"),
        (kUTTypeMPEG, "public.mpeg"),
        (kUTTypeMPEG2Video, "public.mpeg-2-video"),
        (kUTTypeMPEG2TransportStream, "public.mpeg-2-transport-stream"),
        (kUTTypeMP3, "public.mp3"),
        (kUTTypeMPEG4, "public.mpeg-4"),
        (kUTTypeMPEG4Audio, "public.mpeg-4-audio"),
        (kUTTypeAppleProtectedMPEG4Audio, "com.apple.protected-mpeg-4-audio"),
        (kUTTypeAppleProtectedMPEG4Video, "com.apple.protected-mpeg-4-video"),
        (kUTTypeAVIMovie, "public.avi"),
        (kUTTypeAudioInterchangeFileFormat, "public.aiff-audio"),
        (kUTTypeWaveformAudio, "com.microsoft.waveform-audio"),
        (kUTTypeMIDIAudio, "public.midi-audio"),
        (kUTTypePlaylist, "public.playlist"),
        (kUTTypeM3UPlaylist, "public.m3u-playlist"),
        (kUTTypeFolder, "public.folder"),
        (kUTTypeVolume, "public.volume"),
        (kUTTypePackage, "com.apple.package"),
        (kUTTypeBundle, "com.apple.bundle"),
        (kUTTypePluginBundle, "com.apple.plugin"),
        (kUTTypeSpotlightImporter, "com.apple.metadata-importer"),
        (kUTTypeQuickLookGenerator, "com.apple.quicklook-generator"),
        (kUTTypeXPCService, "com.apple.xpc-service"),
        (kUTTypeFramework, "com.apple.framework"),
        (kUTTypeApplication, "com.apple.application"),
        (kUTTypeApplicationBundle, "com.apple.application-bundle"),
        (kUTTypeApplicationFile, "com.apple.application-file"),
        (kUTTypeUnixExecutable, "public.unix-executable"),
        (kUTTypeWindowsExecutable, "com.microsoft.windows-executable"),
        (kUTTypeJavaClass, "com.sun.java-class"),
        (kUTTypeJavaArchive, "com.sun.java-archive"),
        (kUTTypeSystemPreferencesPane, "com.apple.systempreference.prefpane"),
        (kUTTypeGNUZipArchive, "org.gnu.gnu-zip-archive"),
        (kUTTypeBzip2Archive, "public.bzip2-archive"),
        (kUTTypeZipArchive, "public.zip-archive"),
        (kUTTypeSpreadsheet, "public.spreadsheet"),
        (kUTTypePresentation, "public.presentation"),
        (kUTTypeDatabase, "public.database"),
        (kUTTypeCalendarEvent, "public.calendar-event"),
        (kUTTypeToDoItem, "public.to-do-item"),
        (kUTTypeVCard, "public.vcard"),
        (kUTTypeEmailMessage, "public.email-message"),
        (kUTTypeInternetLocation, "com.apple.internet-location"),
        (kUTTypeInkText, "com.apple.ink-text"),
        (kUTTypeFont, "public.font"),
        (kUTTypeBookmark, "public.bookmark"),
        (kUTType3DContent, "public.3d-content"),
        (kUTTypePKCS12, "com.rsa.pkcs-12"),
        (kUTTypeX509Certificate, "public.x509-certificate"),
        (kUTTypeElectronicPublication, "org.idpf.epub-container"),
        (kUTTypeLog, "public.log"),
    ]
    precondition(constants.count == 128)
    for (value, expected) in constants {
        precondition((value as String) == expected, expected)
        precondition(UTTypeIsDeclared(value), expected)
        precondition(!UTTypeIsDynamic(value), expected)
        precondition(UTTypeEqual(value, expected as CFString), expected)
        precondition(takeString(UTTypeCopyDescription(value)) != nil, expected)
    }
}

private func assertConformance() {
    precondition(UTTypeConformsTo(kUTTypeJPEG, kUTTypeJPEG))
    precondition(UTTypeConformsTo(kUTTypeJPEG, kUTTypeImage))
    precondition(UTTypeConformsTo(kUTTypeJPEG, kUTTypeData))
    precondition(UTTypeConformsTo(kUTTypeJPEG, kUTTypeContent))
    precondition(UTTypeConformsTo(kUTTypeJPEG, kUTTypeItem))
    precondition(!UTTypeConformsTo(kUTTypeJPEG, kUTTypeAudio))
    precondition(UTTypeConformsTo(kUTTypePNG, kUTTypeImage))
    precondition(UTTypeConformsTo(kUTTypeMP3, kUTTypeAudio))
    precondition(UTTypeConformsTo(kUTTypeMP3, kUTTypeAudiovisualContent))
    precondition(UTTypeConformsTo(kUTTypeMPEG4, kUTTypeMovie))
    precondition(UTTypeConformsTo(kUTTypeSwiftSource, kUTTypeSourceCode))
    precondition(UTTypeConformsTo(kUTTypeSwiftSource, kUTTypePlainText))
    precondition(UTTypeConformsTo(kUTTypeSwiftSource, kUTTypeText))
    precondition(UTTypeConformsTo(kUTTypePDF, kUTTypeCompositeContent))
    precondition(UTTypeConformsTo(kUTTypeApplicationBundle, kUTTypeApplication))
    precondition(UTTypeConformsTo(kUTTypeApplicationBundle, kUTTypeBundle))
    precondition(UTTypeConformsTo(kUTTypeFolder, kUTTypeDirectory))
    precondition(UTTypeConformsTo(kUTTypeJavaArchive, kUTTypeZipArchive))
    precondition(UTTypeConformsTo(kUTTypeXMLPropertyList, kUTTypePropertyList))
    precondition(UTTypeConformsTo(kUTTypeXMLPropertyList, kUTTypeXML))
    precondition(!UTTypeEqual(kUTTypeJPEG, kUTTypePNG))
}

private func assertTagLookup() {
    precondition(takeString(UTTypeCopyPreferredTagWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension)) == "jpeg")
    let jpegExtensions = takeStrings(UTTypeCopyAllTagsWithClass(kUTTypeJPEG, kUTTagClassFilenameExtension))
    precondition(jpegExtensions == ["jpeg", "jpg", "jpe"])
    precondition(takeString(UTTypeCopyPreferredTagWithClass(kUTTypeJPEG, kUTTagClassMIMEType)) == "image/jpeg")

    precondition(
        takeString(
            UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                "jpg" as CFString,
                nil
            )
        ) == "public.jpeg"
    )
    precondition(
        takeString(
            UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                ".PNG" as CFString,
                kUTTypeImage
            )
        ) == "public.png"
    )
    precondition(
        takeString(
            UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassMIMEType,
                "application/pdf" as CFString,
                nil
            )
        ) == "com.adobe.pdf"
    )

    let pngMatches = takeStrings(
        UTTypeCreateAllIdentifiersForTag(
            kUTTagClassFilenameExtension,
            "png" as CFString,
            kUTTypeImage
        )
    )
    precondition(pngMatches == ["public.png"])

    let unknown = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        "not-a-registered-extension" as CFString,
        nil
    )
    precondition(unknown == nil)

    let unknownClass = UTTypeCopyPreferredTagWithClass(kUTTypeJPEG, "public.ostype" as CFString)
    precondition(unknownClass == nil)

    let itemTags = UTTypeCopyAllTagsWithClass(kUTTypeItem, kUTTagClassFilenameExtension)
    precondition(itemTags == nil)
}

private func assertDeclarationAndDynamic() {
    let declaration = takeDictionary(UTTypeCopyDeclaration(kUTTypePNG))
    precondition(declaration != nil)
    precondition((declaration?[kUTTypeIdentifierKey] as? String) == "public.png")
    precondition((declaration?[kUTTypeDescriptionKey] as? String) == "PNG image")
    let parents = declaration?[kUTTypeConformsToKey] as? NSArray
    precondition(parents?.contains("public.image") == true)
    let tags = declaration?[kUTTypeTagSpecificationKey] as? NSDictionary
    let extensions = tags?[kUTTagClassFilenameExtension] as? NSArray
    precondition(extensions?.contains("png") == true)

    precondition(UTTypeCopyDeclaration("dyn.example" as CFString) == nil)
    precondition(UTTypeCopyDeclaringBundleURL(kUTTypeJPEG) == nil)
    precondition(UTTypeCopyDeclaringBundleURL("dyn.example" as CFString) == nil)
    precondition(UTTypeIsDynamic("dyn.age8u" as CFString))
    precondition(!UTTypeIsDeclared("dyn.age8u" as CFString))
    precondition(!UTTypeIsDynamic(kUTTypeItem))
    precondition(UTTypeCopyDescription("missing.example" as CFString) == nil)
}

assertKeys()
assertTypeConstants()
assertConformance()
assertTagLookup()
assertDeclarationAndDynamic()
print("CORESERVICES_AGENT_RUNTIME_OK")
