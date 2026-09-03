import Foundation
import UniformTypeIdentifiers

func testUTTypeWellKnownIdentifiers() {
    let wellKnown: [(UTType, String)] = [
        (.item, "public.item"),
        (.content, "public.content"),
        (.compositeContent, "public.composite-content"),
        (.data, "public.data"),
        (.directory, "public.directory"),
        (.folder, "public.folder"),
        (.volume, "public.volume"),
        (.package, "com.apple.package"),
        (.bundle, "com.apple.bundle"),
        (.application, "com.apple.application"),
        (.applicationBundle, "com.apple.application-bundle"),
        (.applicationExtension, "com.apple.application-and-system-extension"),
        (.framework, "com.apple.framework"),
        (.pluginBundle, "com.apple.plugin"),
        (.xpcService, "com.apple.xpc-service"),
        (.systemPreferencesPane, "com.apple.systempreference.prefpane"),
        (.quickLookGenerator, "com.apple.quicklook-generator"),
        (.spotlightImporter, "com.apple.metadata-importer"),
        (.executable, "public.executable"),
        (.unixExecutable, "public.unix-executable"),
        (.exe, "com.microsoft.windows-executable"),
        (.archive, "public.archive"),
        (.appleArchive, "com.apple.archive"),
        (.diskImage, "public.disk-image"),
        (.url, "public.url"),
        (.fileURL, "public.file-url"),
        (.bookmark, "public.bookmark"),
        (.resolvable, "com.apple.resolvable"),
        (.symbolicLink, "public.symlink"),
        (.mountPoint, "com.apple.mount-point"),
        (.aliasFile, "com.apple.alias-file"),
        (.urlBookmarkData, "com.apple.bookmark"),
        (.internetLocation, "com.apple.internet-location"),
        (.internetShortcut, "com.microsoft.internet-shortcut"),
        (.text, "public.text"),
        (.plainText, "public.plain-text"),
        (.utf8PlainText, "public.utf8-plain-text"),
        (.utf16PlainText, "public.utf16-plain-text"),
        (.utf16ExternalPlainText, "public.utf16-external-plain-text"),
        (.delimitedText, "public.delimited-values-text"),
        (.commaSeparatedText, "public.comma-separated-values-text"),
        (.tabSeparatedText, "public.tab-separated-values-text"),
        (.utf8TabSeparatedText, "public.utf8-tab-separated-values-text"),
        (.rtf, "public.rtf"),
        (.rtfd, "com.apple.rtfd"),
        (.flatRTFD, "com.apple.flat-rtfd"),
        (.html, "public.html"),
        (.xml, "public.xml"),
        (.yaml, "public.yaml"),
        (.css, "public.css"),
        (.sourceCode, "public.source-code"),
        (.assemblyLanguageSource, "public.assembly-source"),
        (.cHeader, "public.c-header"),
        (.cSource, "public.c-source"),
        (.objectiveCSource, "public.objective-c-source"),
        (.objectiveCPlusPlusSource, "public.objective-c-plus-plus-source"),
        (.swiftSource, "public.swift-source"),
        (.cPlusPlusHeader, "public.c-plus-plus-header"),
        (.cPlusPlusSource, "public.c-plus-plus-source"),
        (.script, "public.script"),
        (.shellScript, "public.shell-script"),
        (.javaScript, "com.netscape.javascript-source"),
        (.appleScript, "com.apple.applescript.text"),
        (.osaScript, "com.apple.applescript.script"),
        (.osaScriptBundle, "com.apple.applescript.script-bundle"),
        (.perlScript, "public.perl-script"),
        (.phpScript, "public.php-script"),
        (.pythonScript, "public.python-script"),
        (.rubyScript, "public.ruby-script"),
        (.makefile, "public.make-source"),
        (.json, "public.json"),
        (.geoJSON, "public.geojson"),
        (.propertyList, "com.apple.property-list"),
        (.binaryPropertyList, "com.apple.binary-property-list"),
        (.xmlPropertyList, "com.apple.xml-property-list"),
        (.pdf, "com.adobe.pdf"),
        (.webArchive, "com.apple.webarchive"),
        (.epub, "org.idpf.epub-container"),
        (.presentation, "public.presentation"),
        (.spreadsheet, "public.spreadsheet"),
        (.message, "public.message"),
        (.emailMessage, "public.email-message"),
        (.contact, "public.contact"),
        (.vCard, "public.vcard"),
        (.toDoItem, "public.to-do-item"),
        (.calendarEvent, "public.calendar-event"),
        (.log, "public.log"),
        (.image, "public.image"),
        (.jpeg, "public.jpeg"),
        (.tiff, "public.tiff"),
        (.gif, "com.compuserve.gif"),
        (.png, "public.png"),
        (.icns, "com.apple.icns"),
        (.bmp, "com.microsoft.bmp"),
        (.ico, "com.microsoft.ico"),
        (.svg, "public.svg-image"),
        (.heif, "public.heif"),
        (.heic, "public.heic"),
        (.heics, "public.heics"),
        (.webP, "org.webmproject.webp"),
        (.jpeg2000, "public.jpeg-2000"),
        (.jpegxl, "public.jpeg-xl"),
        (.rawImage, "public.camera-raw-image"),
        (.dng, "com.adobe.raw-image"),
        (.exr, "com.ilm.openexr-image"),
        (.audiovisualContent, "public.audiovisual-content"),
        (.movie, "public.movie"),
        (.video, "public.video"),
        (.audio, "public.audio"),
        (.quickTimeMovie, "com.apple.quicktime-movie"),
        (.mpeg, "public.mpeg"),
        (.mpeg2Video, "public.mpeg-2-video"),
        (.mpeg2TransportStream, "public.mpeg-2-transport-stream"),
        (.mpeg4Movie, "public.mpeg-4"),
        (.appleProtectedMPEG4Video, "com.apple.protected-mpeg-4-video"),
        (.mp3, "public.mp3"),
        (.mpeg4Audio, "public.mpeg-4-audio"),
        (.appleProtectedMPEG4Audio, "com.apple.protected-mpeg-4-audio"),
        (.avi, "public.avi"),
        (.aiff, "public.aiff-audio"),
        (.wav, "com.microsoft.waveform-audio"),
        (.midi, "public.midi-audio"),
        (.playlist, "public.playlist"),
        (.m3uPlaylist, "public.m3u-playlist"),
        (.zip, "public.zip-archive"),
        (.gzip, "org.gnu.gnu-zip-archive"),
        (.bz2, "public.bzip2-archive"),
        (.tar, "public.tar-archive"),
        (.tarArchive, "public.tar-archive"),
        (.font, "public.font"),
        (.database, "public.database"),
        (.x509Certificate, "public.x509-certificate"),
        (.pkcs12, "com.rsa.pkcs-12"),
        (.threeDContent, "public.3d-content"),
        (.usd, "com.pixar.universal-scene-description"),
        (.usdz, "com.pixar.universal-scene-description-mobile"),
        (.realityFile, "com.apple.reality"),
        (.sceneKitScene, "com.apple.scenekit.scene"),
        (.arReferenceObject, "com.apple.arobject"),
        (.livePhoto, "com.apple.live-photo"),
        (.linkPresentationMetadata, "com.apple.linkpresentation.metadata"),
        (.ahap, "com.apple.haptics.ahap"),
    ]
    for (type, identifier) in wellKnown {
        precondition(type.identifier == identifier)
        precondition(UTType(identifier) == type)
    }
    precondition(UTType.tar == UTType.tarArchive)
}

func testUTTypeInitializers() {
    precondition(UTType("public.png") == .png)
    precondition(UTType("not.registered") == nil)
    precondition(UTType(filenameExtension: "JPG") == .jpeg)
    precondition(UTType(filenameExtension: "png", conformingTo: .image) == .png)
    precondition(UTType(filenameExtension: "png", conformingTo: .movie) == nil)
    precondition(UTType(mimeType: "IMAGE/GIF") == .gif)
    precondition(UTType(mimeType: "image/png", conformingTo: .image) == .png)
    precondition(UTType(tag: "swift", tagClass: .filenameExtension, conformingTo: .sourceCode) == .swiftSource)
    precondition(UTType(tag: "swift", tagClass: .filenameExtension, conformingTo: .audio) == nil)
}

func testUTTypeConformance() {
    precondition(UTType.jpeg.conforms(to: .jpeg))
    precondition(UTType.jpeg.conforms(to: .image))
    precondition(UTType.jpeg.conforms(to: .data))
    precondition(UTType.jpeg.conforms(to: .content))
    precondition(UTType.jpeg.conforms(to: .item))
    precondition(!UTType.jpeg.conforms(to: .movie))
    precondition(UTType.jpeg.isSubtype(of: .image))
    precondition(!UTType.jpeg.isSubtype(of: .jpeg))
    precondition(UTType.image.isSupertype(of: .jpeg))
    precondition(!UTType.jpeg.isSupertype(of: .image))
    precondition(UTType.jpeg.supertypes == [.image, .data, .content, .item])
    precondition(UTType.mpeg4Movie.conforms(to: .movie))
    precondition(UTType.usdz.conforms(to: .threeDContent))
    precondition(UTType.vCard.conforms(to: .contact))
    precondition(UTType.heic.conforms(to: .image))
    precondition(!UTType.heic.conforms(to: .movie))
}

func testUTTypeTagsAndMetadata() {
    precondition(UTType.png.preferredFilenameExtension == "png")
    precondition(UTType.jpeg.preferredFilenameExtension == "jpeg")
    precondition(UTType.jpeg.preferredMIMEType == "image/jpeg")
    precondition(UTType.yaml.preferredFilenameExtension == "yml")
    precondition(UTType.geoJSON.preferredMIMEType == "application/geo+json")
    precondition(UTType.gzip.preferredMIMEType == "application/x-gzip")
    precondition(UTType.wav.preferredMIMEType == "audio/vnd.wave")
    precondition(UTType.applicationBundle.preferredFilenameExtension == "app")
    precondition(UTType.jpeg.tags[.filenameExtension]?.contains("jpeg") == true)
    precondition(UTType.jpeg.tags[.mimeType]?.contains("image/jpeg") == true)
    precondition(UTType.png.isDeclared)
    precondition(UTType.png.isPublic)
    precondition(!UTType.png.isDynamic)
    precondition(UTType("dyn.example") == nil)
    let exported = UTType(exportedAs: "com.example.tags", conformingTo: .image)
    precondition(!exported.isDeclared)
    precondition(!exported.isPublic)
    precondition(exported.identifier == "com.example.tags")
    precondition(UTType.png.localizedDescription == nil)
    precondition(UTType.png.referenceURL == nil)
    precondition(UTType.png.version == nil)
}

func testUTTypeTagLookup() {
    let jpegs = UTType.types(tag: "jpeg", tagClass: .filenameExtension, conformingTo: nil)
    precondition(jpegs.contains(.jpeg))
    let images = UTType.types(tag: "png", tagClass: .filenameExtension, conformingTo: .image)
    precondition(images.contains(.png))
    let none = UTType.types(tag: "png", tagClass: .filenameExtension, conformingTo: .audio)
    precondition(none.isEmpty)
    let mime = UTType.types(tag: "image/gif", tagClass: .mimeType)
    precondition(mime.contains(.gif))
}

func testUTTypeCustomExportedImported() {
    let exported = UTType(exportedAs: "com.example.portable", conformingTo: .image)
    precondition(exported.identifier == "com.example.portable")
    precondition(exported.conforms(to: .image))
    precondition(exported.conforms(to: .content))
    precondition(!exported.isDeclared)
    let imported = UTType(importedAs: "com.example.imported", conformingTo: .data)
    precondition(imported.identifier == "com.example.imported")
    precondition(imported.conforms(to: .data))
    let bare = UTType(exportedAs: "com.example.bare")
    precondition(bare.identifier == "com.example.bare")
    precondition(!bare.conforms(to: .data))
}

func testUTTypeCodable() {
    let encoded = try! JSONEncoder().encode(UTType.jpeg)
    let decoded = try! JSONDecoder().decode(UTType.self, from: encoded)
    precondition(decoded == .jpeg)
    let text = String(data: encoded, encoding: .utf8)
    precondition(text?.contains("public.jpeg") == true)
}

func testUTTypeHashable() {
    precondition(UTType.jpeg == UTType.jpeg)
    precondition(UTType.jpeg != UTType.png)
    precondition(!(UTType.jpeg != UTType.jpeg))
    var hasherA = Hasher()
    var hasherB = Hasher()
    UTType.jpeg.hash(into: &hasherA)
    UTType.jpeg.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(UTType.jpeg.hashValue == UTType.jpeg.hashValue)
    precondition(Set([UTType.jpeg, UTType.png, UTType.jpeg]).count == 2)
}

func testUTTypeDescription() {
    precondition(UTType.png.description == "public.png")
    precondition(UTType.png.debugDescription == "UTType(public.png)")
}

func testUTTypeReferenceType() {
    precondition(UTType.ReferenceType.self == UTTypeReference.self)
}

func testUTTagClass() {
    precondition(UTTagClass.filenameExtension.rawValue == "public.filename-extension")
    precondition(UTTagClass.mimeType.rawValue == "public.mime-type")
    precondition(UTTagClass(rawValue: "public.filename-extension") == .filenameExtension)
    precondition(UTTagClass.filenameExtension.description == "public.filename-extension")
    precondition(UTTagClass.mimeType.debugDescription == "UTTagClass(public.mime-type)")
    precondition(UTTagClass.RawValue.self == String.self)
}

func testUTTagClassHashable() {
    precondition(UTTagClass.filenameExtension == UTTagClass.filenameExtension)
    precondition(UTTagClass.filenameExtension != UTTagClass.mimeType)
    var hasher = Hasher()
    UTTagClass.filenameExtension.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(UTTagClass.filenameExtension.hashValue == UTTagClass.filenameExtension.hashValue)
}

func testUTTagClassCodable() {
    let encoded = try! JSONEncoder().encode(UTTagClass.filenameExtension)
    let decoded = try! JSONDecoder().decode(UTTagClass.self, from: encoded)
    precondition(decoded == .filenameExtension)
}

func testUTTypeReference() {
    let png = UTTypeReference("public.png")
    precondition(png?.identifier == "public.png")
    precondition(png?.preferredFilenameExtension == "png")
    precondition(png?.preferredMIMEType == "image/png")
    precondition(png?.isDeclared == true)
    precondition(png?.isPublic == true)
    precondition(png?.isDynamic == false)
    precondition(png?.conforms(to: .image) == true)
    precondition(png?.isSubtype(of: .image) == true)
    precondition(UTTypeReference("public.image")?.isSupertype(of: .jpeg) == true)
    precondition(png?.supertypes == UTType.png.supertypes)
    precondition(png?.tags["public.filename-extension"]?.contains("png") == true)
    precondition(png?.localizedDescription == nil)
    precondition(png?.referenceURL == nil)
    precondition(png?.version == nil)

    let exported = UTTypeReference(exportedAs: "com.example.ref")
    precondition(exported.identifier == "com.example.ref")
    let exportedParent = UTTypeReference(exportedAs: "com.example.ref-image", conformingTo: .image)
    precondition(exportedParent.conforms(to: .image))
    let imported = UTTypeReference(importedAs: "com.example.ref-import")
    precondition(imported.identifier == "com.example.ref-import")
    let importedParent = UTTypeReference(importedAs: "com.example.ref-data", conformingTo: .data)
    precondition(importedParent.conforms(to: .data))

    precondition(UTTypeReference(filenameExtension: "png")?.identifier == "public.png")
    precondition(UTTypeReference(filenameExtension: "png", conformingTo: .image)?.identifier == "public.png")
    precondition(UTTypeReference(mimeType: "image/jpeg")?.identifier == "public.jpeg")
    precondition(UTTypeReference(mimeType: "image/jpeg", conformingTo: .image)?.identifier == "public.jpeg")
    let byTag = UTTypeReference.types(
        tag: "gif",
        tagClass: UTTagClass.filenameExtension.rawValue,
        conformingTo: .image
    )
    precondition(byTag.contains(.gif))
    precondition(UTTypeReference("missing.type") == nil)
}

func testUTTypeReferenceSynthesizedInits() {
    precondition(UTTypeReference(identifier: "public.png")?.identifier == "public.png")
    precondition(
        UTTypeReference(filenameExtension: "png", conformingToType: .image)?.identifier == "public.png"
    )
    precondition(UTTypeReference(MIMEType: "image/gif")?.identifier == "com.compuserve.gif")
    precondition(
        UTTypeReference(MIMEType: "image/png", conformingToType: .image)?.identifier == "public.png"
    )
    precondition(
        UTTypeReference(
            tag: "mp3",
            tagClass: UTTagClass.filenameExtension.rawValue,
            conformingToType: .audio
        )?.identifier == "public.mp3"
    )
}

func testUTTypeReferenceCoder() {
    let decoded = UTTypeReference(coder: NSCoder())
    precondition(decoded == nil)
}

func testURLAdditions() {
    let base = URL(fileURLWithPath: "/tmp/photo")
    let jpeg = base.appendingPathExtension(for: .jpeg)
    precondition(jpeg.pathExtension == "jpeg")
    let png = base.appendingPathComponent("shot", conformingTo: .png)
    precondition(png.lastPathComponent == "shot.png")
    var mutable = base
    mutable.appendPathExtension(for: .gif)
    precondition(mutable.pathExtension == "gif")
    mutable = base
    mutable.appendPathComponent("clip", conformingTo: .mpeg4Movie)
    precondition(mutable.lastPathComponent.hasPrefix("clip"))
    let noExt = URL(fileURLWithPath: "/tmp/item").appendingPathExtension(for: .item)
    precondition(noExt.pathExtension.isEmpty)
}

func testNSStringAdditions() {
    let name: NSString = "report"
    let pdf = name.appendingPathExtension(for: .pdf)
    precondition(pdf.hasSuffix(".pdf"))
    let csv = name.appendingPathComponent("table", conformingTo: .commaSeparatedText)
    precondition((csv as NSString).pathExtension == "csv")
    let unchanged = name.appendingPathExtension(for: .item)
    precondition(unchanged == "report")
}

func testNSURLAdditions() {
    let url = NSURL(fileURLWithPath: "/tmp/doc")
    let xml = url.appendingPathExtension(for: .xml)
    precondition(xml.pathExtension == "xml")
    let app = url.appendingPathComponent("MyApp", conformingTo: .applicationBundle)
    precondition(app.pathExtension == "app")
}

func testURLResourceValuesContentType() {
    let values = URLResourceValues()
    precondition(values.contentType == nil)
}
