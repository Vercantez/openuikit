@_exported import Foundation

/// The class of a tag used to identify a uniform type.
public struct UTTagClass: RawRepresentable, Hashable, Sendable, Codable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let filenameExtension = UTTagClass(
        rawValue: "public.filename-extension"
    )
    public static let mimeType = UTTagClass(rawValue: "public.mime-type")
    public static let osType = UTTagClass(rawValue: "com.apple.ostype")

    public var description: String { rawValue }
    public var debugDescription: String { "UTTagClass(\(rawValue))" }
}

private struct _UTRecord: Sendable {
    let parents: [String]
    let filenameExtensions: [String]
    let mimeTypes: [String]

    init(
        parents: [String],
        filenameExtensions: [String] = [],
        mimeTypes: [String] = []
    ) {
        self.parents = parents
        self.filenameExtensions = filenameExtensions
        self.mimeTypes = mimeTypes
    }
}

/// A portable, value-semantic uniform type identifier.
///
/// The built-in registry covers the common system types used by application
/// and package sources. Custom exported/imported identifiers retain their
/// declared conformance in the value, while unknown lookups fail instead of
/// pretending that the host operating system registered them.
public struct UTType: Hashable, Sendable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public let identifier: String
    private let declaredParent: String?

    private init(unchecked identifier: String, parent: String? = nil) {
        self.identifier = identifier
        self.declaredParent = parent
    }

    public init?(_ identifier: String) {
        guard Self._registry[identifier] != nil else { return nil }
        self.init(unchecked: identifier)
    }

    public init(exportedAs identifier: String, conformingTo parentType: UTType? = nil) {
        self.init(unchecked: identifier, parent: parentType?.identifier)
    }

    public init(importedAs identifier: String, conformingTo parentType: UTType? = nil) {
        self.init(unchecked: identifier, parent: parentType?.identifier)
    }

    public init?(
        tag: String,
        tagClass: UTTagClass,
        conformingTo parentType: UTType? = nil
    ) {
        guard let value = Self.types(
            tag: tag,
            tagClass: tagClass,
            conformingTo: parentType
        ).first else { return nil }
        self = value
    }

    public init?(filenameExtension: String, conformingTo parentType: UTType = .data) {
        self.init(
            tag: filenameExtension,
            tagClass: .filenameExtension,
            conformingTo: parentType
        )
    }

    public init?(mimeType: String, conformingTo parentType: UTType = .data) {
        self.init(tag: mimeType, tagClass: .mimeType, conformingTo: parentType)
    }

    public static func types(
        tag: String,
        tagClass: UTTagClass,
        conformingTo parentType: UTType? = nil
    ) -> [UTType] {
        let needle = tag.lowercased()
        return _registry.keys.sorted().compactMap { identifier in
            guard let record = _registry[identifier] else { return nil }
            let values: [String]
            switch tagClass {
            case .filenameExtension:
                values = record.filenameExtensions
            case .mimeType:
                values = record.mimeTypes
            default:
                values = []
            }
            guard values.contains(where: { $0.lowercased() == needle }) else {
                return nil
            }
            let type = UTType(unchecked: identifier)
            guard parentType.map({ type.conforms(to: $0) }) ?? true else {
                return nil
            }
            return type
        }
    }

    public var preferredFilenameExtension: String? {
        Self._registry[identifier]?.filenameExtensions.first
    }

    public var preferredMIMEType: String? {
        Self._registry[identifier]?.mimeTypes.first
    }

    public var tags: [UTTagClass: [String]] {
        guard let record = Self._registry[identifier] else { return [:] }
        var result: [UTTagClass: [String]] = [:]
        if !record.filenameExtensions.isEmpty {
            result[.filenameExtension] = record.filenameExtensions
        }
        if !record.mimeTypes.isEmpty {
            result[.mimeType] = record.mimeTypes
        }
        return result
    }

    public var supertypes: Set<UTType> {
        var pending = Self._registry[identifier]?.parents ?? []
        if let declaredParent { pending.append(declaredParent) }
        var identifiers: Set<String> = []
        while let candidate = pending.popLast() {
            guard identifiers.insert(candidate).inserted else { continue }
            pending.append(contentsOf: Self._registry[candidate]?.parents ?? [])
        }
        return Set(identifiers.map { UTType(unchecked: $0) })
    }

    public var isDeclared: Bool { Self._registry[identifier] != nil }
    public var isDynamic: Bool { identifier.hasPrefix("dyn.") }
    public var isPublic: Bool { identifier.hasPrefix("public.") }
    public var localizedDescription: String? { nil }
    public var referenceURL: URL? { nil }
    public var version: Int? { nil }

    public func conforms(to otherType: UTType) -> Bool {
        if identifier == otherType.identifier { return true }
        var pending = Self._registry[identifier]?.parents ?? []
        if let declaredParent { pending.append(declaredParent) }
        var visited: Set<String> = []
        while let candidate = pending.popLast() {
            if candidate == otherType.identifier { return true }
            guard visited.insert(candidate).inserted else { continue }
            pending.append(contentsOf: Self._registry[candidate]?.parents ?? [])
        }
        return false
    }

    public func isSubtype(of type: UTType) -> Bool {
        self != type && conforms(to: type)
    }

    public func isSupertype(of type: UTType) -> Bool {
        self != type && type.conforms(to: self)
    }

    public static func == (lhs: UTType, rhs: UTType) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(unchecked: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }

    public var description: String { identifier }
    public var debugDescription: String { "UTType(\(identifier))" }

    private static func known(_ identifier: String) -> UTType {
        precondition(_registry[identifier] != nil)
        return UTType(unchecked: identifier)
    }

    public static let item = known("public.item")
    public static let content = known("public.content")
    public static let compositeContent = known("public.composite-content")
    public static let data = known("public.data")
    public static let directory = known("public.directory")
    public static let folder = known("public.folder")
    public static let volume = known("public.volume")
    public static let package = known("com.apple.package")
    public static let bundle = known("com.apple.bundle")
    public static let application = known("com.apple.application")
    public static let applicationBundle = known("com.apple.application-bundle")
    public static let applicationExtension = known(
        "com.apple.application-and-system-extension"
    )
    public static let framework = known("com.apple.framework")
    public static let pluginBundle = known("com.apple.plugin")
    public static let xpcService = known("com.apple.xpc-service")
    public static let systemPreferencesPane = known(
        "com.apple.systempreference.prefpane"
    )
    public static let quickLookGenerator = known("com.apple.quicklook-generator")
    public static let spotlightImporter = known("com.apple.metadata-importer")
    public static let executable = known("public.executable")
    public static let unixExecutable = known("public.unix-executable")
    public static let exe = known("com.microsoft.windows-executable")
    public static let archive = known("public.archive")
    public static let appleArchive = known("com.apple.archive")
    public static let diskImage = known("public.disk-image")
    public static let url = known("public.url")
    public static let fileURL = known("public.file-url")
    public static let bookmark = known("public.bookmark")
    public static let resolvable = known("com.apple.resolvable")
    public static let symbolicLink = known("public.symlink")
    public static let mountPoint = known("com.apple.mount-point")
    public static let aliasFile = known("com.apple.alias-file")
    public static let urlBookmarkData = known("com.apple.bookmark")
    public static let internetLocation = known("com.apple.internet-location")
    public static let internetShortcut = known(
        "com.microsoft.internet-shortcut"
    )

    public static let text = known("public.text")
    public static let plainText = known("public.plain-text")
    public static let utf8PlainText = known("public.utf8-plain-text")
    public static let utf16PlainText = known("public.utf16-plain-text")
    public static let utf16ExternalPlainText = known(
        "public.utf16-external-plain-text"
    )
    public static let delimitedText = known("public.delimited-values-text")
    public static let commaSeparatedText = known("public.comma-separated-values-text")
    public static let tabSeparatedText = known("public.tab-separated-values-text")
    public static let utf8TabSeparatedText = known(
        "public.utf8-tab-separated-values-text"
    )
    public static let rtf = known("public.rtf")
    public static let rtfd = known("com.apple.rtfd")
    public static let flatRTFD = known("com.apple.flat-rtfd")
    public static let html = known("public.html")
    public static let xml = known("public.xml")
    public static let yaml = known("public.yaml")
    public static let css = known("public.css")
    public static let sourceCode = known("public.source-code")
    public static let assemblyLanguageSource = known("public.assembly-source")
    public static let cHeader = known("public.c-header")
    public static let cSource = known("public.c-source")
    public static let objectiveCSource = known("public.objective-c-source")
    public static let objectiveCPlusPlusSource = known(
        "public.objective-c-plus-plus-source"
    )
    public static let swiftSource = known("public.swift-source")
    public static let cPlusPlusHeader = known("public.c-plus-plus-header")
    public static let cPlusPlusSource = known("public.c-plus-plus-source")
    public static let script = known("public.script")
    public static let shellScript = known("public.shell-script")
    public static let javaScript = known("com.netscape.javascript-source")
    public static let appleScript = known("com.apple.applescript.text")
    public static let osaScript = known("com.apple.applescript.script")
    public static let osaScriptBundle = known("com.apple.applescript.script-bundle")
    public static let perlScript = known("public.perl-script")
    public static let phpScript = known("public.php-script")
    public static let pythonScript = known("public.python-script")
    public static let rubyScript = known("public.ruby-script")
    public static let makefile = known("public.make-source")
    public static let json = known("public.json")
    public static let geoJSON = known("public.geojson")
    public static let propertyList = known("com.apple.property-list")
    public static let binaryPropertyList = known("com.apple.binary-property-list")
    public static let xmlPropertyList = known("com.apple.xml-property-list")
    public static let pdf = known("com.adobe.pdf")
    public static let webArchive = known("com.apple.webarchive")
    public static let epub = known("org.idpf.epub-container")
    public static let presentation = known("public.presentation")
    public static let spreadsheet = known("public.spreadsheet")
    public static let message = known("public.message")
    public static let emailMessage = known("public.email-message")
    public static let contact = known("public.contact")
    public static let vCard = known("public.vcard")
    public static let toDoItem = known("public.to-do-item")
    public static let calendarEvent = known("public.calendar-event")
    public static let log = known("public.log")

    public static let image = known("public.image")
    public static let jpeg = known("public.jpeg")
    public static let tiff = known("public.tiff")
    public static let gif = known("com.compuserve.gif")
    public static let png = known("public.png")
    public static let icns = known("com.apple.icns")
    public static let bmp = known("com.microsoft.bmp")
    public static let ico = known("com.microsoft.ico")
    public static let svg = known("public.svg-image")
    public static let heif = known("public.heif")
    public static let heic = known("public.heic")
    public static let heics = known("public.heics")
    public static let webP = known("org.webmproject.webp")
    public static let jpeg2000 = known("public.jpeg-2000")
    public static let jpegxl = known("public.jpeg-xl")
    public static let rawImage = known("public.camera-raw-image")
    public static let dng = known("com.adobe.raw-image")
    public static let exr = known("com.ilm.openexr-image")

    public static let audiovisualContent = known("public.audiovisual-content")
    public static let movie = known("public.movie")
    public static let video = known("public.video")
    public static let audio = known("public.audio")
    public static let quickTimeMovie = known("com.apple.quicktime-movie")
    public static let mpeg = known("public.mpeg")
    public static let mpeg2Video = known("public.mpeg-2-video")
    public static let mpeg2TransportStream = known(
        "public.mpeg-2-transport-stream"
    )
    public static let mpeg4Movie = known("public.mpeg-4")
    public static let appleProtectedMPEG4Video = known(
        "com.apple.protected-mpeg-4-video"
    )
    public static let mp3 = known("public.mp3")
    public static let mpeg4Audio = known("public.mpeg-4-audio")
    public static let appleProtectedMPEG4Audio = known(
        "com.apple.protected-mpeg-4-audio"
    )
    public static let avi = known("public.avi")
    public static let aiff = known("public.aiff-audio")
    public static let wav = known("com.microsoft.waveform-audio")
    public static let midi = known("public.midi-audio")
    public static let playlist = known("public.playlist")
    public static let m3uPlaylist = known("public.m3u-playlist")

    public static let zip = known("public.zip-archive")
    public static let gzip = known("org.gnu.gnu-zip-archive")
    public static let bz2 = known("public.bzip2-archive")
    public static let tar = known("public.tar-archive")
    public static let font = known("public.font")
    public static let database = known("public.database")
    public static let x509Certificate = known("public.x509-certificate")
    public static let pkcs12 = known("com.rsa.pkcs-12")

    public static let threeDContent = known("public.3d-content")
    public static let usd = known("com.pixar.universal-scene-description")
    public static let usdz = known(
        "com.pixar.universal-scene-description-mobile"
    )
    public static let realityFile = known("com.apple.reality")
    public static let sceneKitScene = known("com.apple.scenekit.scene")
    public static let arReferenceObject = known("com.apple.arobject")
    public static let livePhoto = known("com.apple.live-photo")
    public static let linkPresentationMetadata = known(
        "com.apple.linkpresentation.metadata"
    )
    public static let ahap = known("com.apple.haptics.ahap")

    private static let _registry: [String: _UTRecord] = [
        "public.item": .init(parents: []),
        "public.content": .init(parents: []),
        "public.composite-content": .init(parents: ["public.content"]),
        "public.data": .init(parents: ["public.item"]),
        "public.directory": .init(parents: ["public.item"]),
        "public.folder": .init(parents: ["public.directory"]),
        "public.volume": .init(parents: ["public.folder"]),
        "com.apple.package": .init(parents: ["public.directory"]),
        "com.apple.bundle": .init(parents: ["public.directory"]),
        "com.apple.application": .init(parents: ["public.executable"]),
        "com.apple.application-bundle": .init(
            parents: ["com.apple.application", "com.apple.bundle", "com.apple.package"],
            filenameExtensions: ["app"]
        ),
        "com.apple.application-and-system-extension": .init(
            parents: ["com.apple.bundle", "com.apple.xpc-service"],
            filenameExtensions: ["appex"]
        ),
        "com.apple.framework": .init(
            parents: ["com.apple.bundle"],
            filenameExtensions: ["framework"]
        ),
        "com.apple.plugin": .init(
            parents: ["com.apple.bundle", "com.apple.package"],
            filenameExtensions: ["plugin"]
        ),
        "com.apple.xpc-service": .init(
            parents: ["com.apple.bundle", "com.apple.package"],
            filenameExtensions: ["xpc"]
        ),
        "com.apple.systempreference.prefpane": .init(
            parents: ["com.apple.bundle", "com.apple.package"],
            filenameExtensions: ["prefpane"]
        ),
        "com.apple.quicklook-generator": .init(
            parents: ["com.apple.plugin"],
            filenameExtensions: ["qlgenerator"]
        ),
        "com.apple.metadata-importer": .init(
            parents: ["com.apple.plugin"],
            filenameExtensions: ["mdimporter"]
        ),
        "public.executable": .init(parents: []),
        "public.unix-executable": .init(parents: ["public.data", "public.executable"]),
        "com.microsoft.windows-executable": .init(
            parents: ["public.data", "public.executable"],
            filenameExtensions: ["exe"],
            mimeTypes: ["application/x-msdownload"]
        ),
        "public.archive": .init(parents: []),
        "com.apple.archive": .init(
            parents: ["public.archive", "public.data"],
            filenameExtensions: ["aar"]
        ),
        "public.disk-image": .init(parents: ["public.archive"]),
        "public.url": .init(parents: ["public.data"], mimeTypes: ["text/uri-list"]),
        "public.file-url": .init(parents: ["public.url"]),
        "public.bookmark": .init(parents: []),
        "com.apple.resolvable": .init(parents: []),
        "public.symlink": .init(parents: ["com.apple.resolvable", "public.item"]),
        "com.apple.mount-point": .init(parents: ["com.apple.resolvable", "public.item"]),
        "com.apple.alias-file": .init(parents: ["com.apple.resolvable", "public.data"]),
        "com.apple.bookmark": .init(parents: ["com.apple.resolvable", "public.data"]),
        "com.apple.internet-location": .init(
            parents: ["public.data", "public.stored-url"]
        ),
        "com.microsoft.internet-shortcut": .init(
            parents: ["public.data", "public.stored-url"],
            filenameExtensions: ["url"]
        ),

        "public.text": .init(parents: ["public.data", "public.content"], mimeTypes: ["text/plain"]),
        "public.plain-text": .init(parents: ["public.text"], filenameExtensions: ["txt"], mimeTypes: ["text/plain"]),
        "public.utf8-plain-text": .init(
            parents: ["public.plain-text"],
            mimeTypes: ["text/plain;charset=utf-8"]
        ),
        "public.utf16-plain-text": .init(
            parents: ["public.plain-text"],
            mimeTypes: ["text/plain;charset=utf-16"]
        ),
        "public.utf16-external-plain-text": .init(parents: ["public.plain-text"]),
        "public.delimited-values-text": .init(parents: ["public.text"]),
        "public.comma-separated-values-text": .init(parents: ["public.delimited-values-text"], filenameExtensions: ["csv"], mimeTypes: ["text/csv"]),
        "public.tab-separated-values-text": .init(parents: ["public.delimited-values-text"], filenameExtensions: ["tsv"], mimeTypes: ["text/tab-separated-values"]),
        "public.utf8-tab-separated-values-text": .init(
            parents: ["public.tab-separated-values-text", "public.utf8-plain-text"]
        ),
        "public.rtf": .init(parents: ["public.text"], filenameExtensions: ["rtf"], mimeTypes: ["text/rtf"]),
        "com.apple.rtfd": .init(
            parents: ["com.apple.package", "public.composite-content"],
            filenameExtensions: ["rtfd"]
        ),
        "com.apple.flat-rtfd": .init(parents: ["public.composite-content"]),
        "public.html": .init(parents: ["public.text"], filenameExtensions: ["html", "htm"], mimeTypes: ["text/html"]),
        "public.xml": .init(parents: ["public.text"], filenameExtensions: ["xml"], mimeTypes: ["application/xml", "text/xml"]),
        "public.yaml": .init(parents: ["public.text"], filenameExtensions: ["yml", "yaml"], mimeTypes: ["application/x-yaml"]),
        "public.css": .init(parents: ["public.text"], filenameExtensions: ["css"], mimeTypes: ["text/css"]),
        "public.source-code": .init(parents: ["public.plain-text"]),
        "public.assembly-source": .init(parents: ["public.source-code"], filenameExtensions: ["s"]),
        "public.c-header": .init(parents: ["public.source-code"], filenameExtensions: ["h"]),
        "public.c-source": .init(parents: ["public.source-code"], filenameExtensions: ["c"]),
        "public.objective-c-source": .init(parents: ["public.source-code"], filenameExtensions: ["m"]),
        "public.objective-c-plus-plus-source": .init(parents: ["public.source-code"], filenameExtensions: ["mm"]),
        "public.swift-source": .init(parents: ["public.source-code"], filenameExtensions: ["swift"]),
        "public.c-plus-plus-header": .init(parents: ["public.source-code"], filenameExtensions: ["hh"]),
        "public.c-plus-plus-source": .init(parents: ["public.source-code"], filenameExtensions: ["cp", "cpp", "cc", "cxx"]),
        "public.script": .init(parents: ["public.source-code"]),
        "public.shell-script": .init(parents: ["public.script"], filenameExtensions: ["sh"]),
        "com.netscape.javascript-source": .init(
            parents: ["public.executable", "public.script"],
            filenameExtensions: ["js"],
            mimeTypes: ["text/javascript"]
        ),
        "com.apple.applescript.text": .init(
            parents: ["public.script"],
            filenameExtensions: ["applescript"]
        ),
        "com.apple.applescript.script": .init(
            parents: ["public.script"],
            filenameExtensions: ["scpt"]
        ),
        "com.apple.applescript.script-bundle": .init(
            parents: ["com.apple.bundle", "com.apple.package"],
            filenameExtensions: ["scptd"]
        ),
        "public.perl-script": .init(
            parents: ["public.shell-script"],
            filenameExtensions: ["pl"],
            mimeTypes: ["text/x-perl-script"]
        ),
        "public.php-script": .init(
            parents: ["public.shell-script"],
            filenameExtensions: ["php"],
            mimeTypes: ["text/php"]
        ),
        "public.python-script": .init(
            parents: ["public.shell-script"],
            filenameExtensions: ["py"],
            mimeTypes: ["text/x-python-script"]
        ),
        "public.ruby-script": .init(
            parents: ["public.shell-script"],
            filenameExtensions: ["rb"],
            mimeTypes: ["text/x-ruby-script"]
        ),
        "public.make-source": .init(parents: ["public.script"], filenameExtensions: ["make"]),
        "public.json": .init(parents: ["public.text"], filenameExtensions: ["json"], mimeTypes: ["application/json"]),
        "public.geojson": .init(
            parents: ["public.json"],
            filenameExtensions: ["geojson"],
            mimeTypes: ["application/geo+json"]
        ),
        "com.apple.property-list": .init(
            parents: ["public.data"],
            filenameExtensions: ["plist"]
        ),
        "com.apple.binary-property-list": .init(
            parents: ["com.apple.property-list"],
            filenameExtensions: ["plist"]
        ),
        "com.apple.xml-property-list": .init(
            parents: ["com.apple.property-list", "public.xml"],
            filenameExtensions: ["plist"]
        ),
        "com.adobe.pdf": .init(parents: ["public.data", "public.composite-content"], filenameExtensions: ["pdf"], mimeTypes: ["application/pdf"]),
        "com.apple.webarchive": .init(
            parents: ["public.composite-content", "public.data"],
            filenameExtensions: ["webarchive"],
            mimeTypes: ["application/x-webarchive"]
        ),
        "org.idpf.epub-container": .init(
            parents: ["public.composite-content", "public.data"],
            filenameExtensions: ["epub"],
            mimeTypes: ["application/epub+zip"]
        ),
        "public.presentation": .init(parents: []),
        "public.spreadsheet": .init(parents: []),
        "public.message": .init(parents: []),
        "public.email-message": .init(parents: ["public.message"]),
        "public.contact": .init(parents: []),
        "public.vcard": .init(
            parents: ["public.contact", "public.text"],
            filenameExtensions: ["vcf"],
            mimeTypes: ["text/vcard"]
        ),
        "public.to-do-item": .init(parents: []),
        "public.calendar-event": .init(parents: []),
        "public.log": .init(parents: ["public.item"]),

        "public.image": .init(parents: ["public.data", "public.content"]),
        "public.jpeg": .init(parents: ["public.image"], filenameExtensions: ["jpeg", "jpg", "jpe"], mimeTypes: ["image/jpeg"]),
        "public.tiff": .init(parents: ["public.image"], filenameExtensions: ["tiff", "tif"], mimeTypes: ["image/tiff"]),
        "com.compuserve.gif": .init(parents: ["public.image"], filenameExtensions: ["gif"], mimeTypes: ["image/gif"]),
        "public.png": .init(parents: ["public.image"], filenameExtensions: ["png"], mimeTypes: ["image/png"]),
        "com.apple.icns": .init(parents: ["public.image"], filenameExtensions: ["icns"]),
        "com.microsoft.bmp": .init(parents: ["public.image"], filenameExtensions: ["bmp"], mimeTypes: ["image/bmp"]),
        "com.microsoft.ico": .init(parents: ["public.image"], filenameExtensions: ["ico"], mimeTypes: ["image/vnd.microsoft.icon"]),
        "public.svg-image": .init(parents: ["public.image", "public.xml"], filenameExtensions: ["svg"], mimeTypes: ["image/svg+xml"]),
        "public.heif": .init(parents: ["public.image", "public.heif-standard"], filenameExtensions: ["heif"], mimeTypes: ["image/heif"]),
        "public.heic": .init(parents: ["public.heif"], filenameExtensions: ["heic"], mimeTypes: ["image/heic"]),
        "public.heics": .init(
            parents: ["public.image", "public.heif-standard"],
            filenameExtensions: ["heics"],
            mimeTypes: ["image/heic-sequence"]
        ),
        "org.webmproject.webp": .init(parents: ["public.image"], filenameExtensions: ["webp"], mimeTypes: ["image/webp"]),
        "public.jpeg-2000": .init(parents: ["public.image"], filenameExtensions: ["jp2"], mimeTypes: ["image/jp2"]),
        "public.jpeg-xl": .init(parents: ["public.image"], filenameExtensions: ["jxl"], mimeTypes: ["image/jxl"]),
        "public.camera-raw-image": .init(parents: ["public.image"]),
        "com.adobe.raw-image": .init(
            parents: ["public.camera-raw-image"],
            filenameExtensions: ["dng"],
            mimeTypes: ["image/x-adobe-dng"]
        ),
        "com.ilm.openexr-image": .init(
            parents: ["public.image"],
            filenameExtensions: ["exr"]
        ),

        "public.audiovisual-content": .init(parents: ["public.data", "public.content"]),
        "public.movie": .init(parents: ["public.audiovisual-content"]),
        "public.video": .init(parents: ["public.movie"]),
        "public.audio": .init(parents: ["public.audiovisual-content"]),
        "com.apple.quicktime-movie": .init(parents: ["public.movie"], filenameExtensions: ["mov", "qt"], mimeTypes: ["video/quicktime"]),
        "public.mpeg": .init(parents: ["public.movie"], filenameExtensions: ["mpeg", "mpg"], mimeTypes: ["video/mpeg"]),
        "public.mpeg-2-video": .init(parents: ["public.video"], filenameExtensions: ["m2v"], mimeTypes: ["video/mpeg2"]),
        "public.mpeg-2-transport-stream": .init(
            parents: ["public.movie"],
            filenameExtensions: ["ts"]
        ),
        "public.mpeg-4": .init(parents: ["public.movie"], filenameExtensions: ["mp4"], mimeTypes: ["video/mp4"]),
        "com.apple.m4v-video": .init(parents: ["public.movie"], filenameExtensions: ["m4v"], mimeTypes: ["video/x-m4v"]),
        "com.apple.protected-mpeg-4-video": .init(
            parents: ["com.apple.m4v-video", "public.mpeg-4"]
        ),
        "public.mp3": .init(parents: ["public.audio"], filenameExtensions: ["mp3"], mimeTypes: ["audio/mpeg"]),
        "public.mpeg-4-audio": .init(parents: ["public.audio"], filenameExtensions: ["mp4", "m4a"], mimeTypes: ["audio/mp4"]),
        "com.apple.protected-mpeg-4-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["m4p"]
        ),
        "public.avi": .init(parents: ["public.movie"], filenameExtensions: ["avi"], mimeTypes: ["video/avi"]),
        "public.aiff-audio": .init(parents: ["public.audio"], filenameExtensions: ["aiff", "aif"], mimeTypes: ["audio/aiff"]),
        "com.microsoft.waveform-audio": .init(parents: ["public.audio"], filenameExtensions: ["wav"], mimeTypes: ["audio/vnd.wave"]),
        "public.midi-audio": .init(parents: ["public.audio"], filenameExtensions: ["midi", "mid"], mimeTypes: ["audio/midi"]),
        "public.playlist": .init(parents: []),
        "public.m3u-playlist": .init(parents: ["public.playlist", "public.plain-text"], filenameExtensions: ["m3u"], mimeTypes: ["audio/mpegurl"]),

        "public.zip-archive": .init(parents: ["public.archive", "public.data"], filenameExtensions: ["zip"], mimeTypes: ["application/zip"]),
        "org.gnu.gnu-zip-archive": .init(parents: ["public.archive", "public.data"], filenameExtensions: ["gz"], mimeTypes: ["application/x-gzip"]),
        "public.bzip2-archive": .init(parents: ["public.archive", "public.data"], filenameExtensions: ["bz2"], mimeTypes: ["application/x-bzip2"]),
        "public.tar-archive": .init(parents: ["public.archive", "public.data"], filenameExtensions: ["tar"], mimeTypes: ["application/x-tar"]),
        "public.font": .init(parents: ["public.data", "public.content"]),
        "public.database": .init(parents: []),
        "public.x509-certificate": .init(
            parents: ["public.data"],
            filenameExtensions: ["cer"],
            mimeTypes: ["application/x-x509-ca-cert"]
        ),
        "com.rsa.pkcs-12": .init(
            parents: ["public.data"],
            filenameExtensions: ["p12"],
            mimeTypes: ["application/x-pkcs12"]
        ),

        "public.3d-content": .init(parents: ["public.content"]),
        "com.pixar.universal-scene-description": .init(
            parents: ["public.3d-content", "public.data"],
            filenameExtensions: ["usd"]
        ),
        "com.pixar.universal-scene-description-mobile": .init(
            parents: ["com.pixar.universal-scene-description"],
            filenameExtensions: ["usdz"],
            mimeTypes: ["model/vnd.usdz+zip"]
        ),
        "com.apple.reality": .init(
            parents: ["public.data"],
            filenameExtensions: ["reality"],
            mimeTypes: ["model/vnd.reality"]
        ),
        "com.apple.scenekit.scene": .init(
            parents: ["public.3d-content", "public.data"],
            filenameExtensions: ["scn"]
        ),
        "com.apple.arobject": .init(
            parents: ["public.data"],
            filenameExtensions: ["arobject"]
        ),
        "com.apple.live-photo": .init(parents: []),
        "com.apple.linkpresentation.metadata": .init(parents: ["public.data"]),
        "com.apple.haptics.ahap": .init(
            parents: ["public.haptics-content", "public.json"],
            filenameExtensions: ["ahap"]
        ),
    ]
}
