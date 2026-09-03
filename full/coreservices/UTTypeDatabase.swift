import Foundation

struct UTTypeRecord: Sendable {
    let identifier: String
    let parents: [String]
    let description: String
    let filenameExtensions: [String]
    let mimeTypes: [String]
}

enum UTTypeDatabase {
    static func record(for identifier: String) -> UTTypeRecord? {
        records[identifier]
    }

    static func conforms(_ identifier: String, to other: String) -> Bool {
        if identifier == other {
            return true
        }
        var pending = records[identifier]?.parents ?? []
        var visited: Set<String> = []
        while let candidate = pending.popLast() {
            if candidate == other {
                return true
            }
            guard visited.insert(candidate).inserted else { continue }
            pending.append(contentsOf: records[candidate]?.parents ?? [])
        }
        return false
    }

    static func tags(for identifier: String, tagClass: String) -> [String] {
        guard let record = records[identifier] else { return [] }
        switch tagClass {
        case "public.filename-extension":
            return record.filenameExtensions
        case "public.mime-type":
            return record.mimeTypes
        default:
            return []
        }
    }

    /// Preferred identifier is the first among matches that list `tag` as their
    /// preferred (first) tag, otherwise the first identifier in UTF-8 order.
    /// Unknown tags return `[]` rather than minting a `dyn.*` identifier.
    static func identifiers(
        tagClass: String,
        tag: String,
        conformingTo: String?
    ) -> [String] {
        let needle = normalizedTag(tag, tagClass: tagClass)
        guard !needle.isEmpty else { return [] }

        var preferred: [String] = []
        var others: [String] = []
        for identifier in records.keys.sorted() {
            let values = tags(for: identifier, tagClass: tagClass).map {
                normalizedTag($0, tagClass: tagClass)
            }
            guard let index = values.firstIndex(of: needle) else { continue }
            if let conformingTo, !conforms(identifier, to: conformingTo) {
                continue
            }
            if index == 0 {
                preferred.append(identifier)
            } else {
                others.append(identifier)
            }
        }
        return preferred + others
    }

    private static func normalizedTag(_ tag: String, tagClass: String) -> String {
        var value = tag
        if tagClass == "public.filename-extension", value.hasPrefix(".") {
            value.removeFirst()
        }
        return value.lowercased()
    }

    private static let records: [String: UTTypeRecord] = makeRecords()

    private static func makeRecords() -> [String: UTTypeRecord] {
        var result: [String: UTTypeRecord] = [:]
        func add(
            _ identifier: String,
            parents: [String],
            description: String,
            ext: [String] = [],
            mime: [String] = []
        ) {
            result[identifier] = UTTypeRecord(
                identifier: identifier,
                parents: parents,
                description: description,
                filenameExtensions: ext,
                mimeTypes: mime
            )
        }

        add("public.item", parents: [], description: "Item")
        add("public.content", parents: ["public.item"], description: "Content")
        add("public.composite-content", parents: ["public.content"], description: "Composite content")
        add("public.data", parents: ["public.item"], description: "Data")
        add("public.directory", parents: ["public.item"], description: "Directory")
        add("public.folder", parents: ["public.directory"], description: "Folder")
        add("public.volume", parents: ["public.folder"], description: "Volume")
        add("public.executable", parents: ["public.item"], description: "Executable")
        add("public.archive", parents: ["public.item"], description: "Archive")
        add("public.disk-image", parents: ["public.archive"], description: "Disk image", ext: ["dmg", "iso"])
        add("com.apple.resolvable", parents: ["public.item"], description: "Resolvable")
        add("public.symlink", parents: ["com.apple.resolvable", "public.item"], description: "Symbolic link")
        add("com.apple.mount-point", parents: ["com.apple.resolvable", "public.item"], description: "Mount point")
        add("com.apple.alias-file", parents: ["com.apple.resolvable", "public.data"], description: "Alias file")
        add("com.apple.alias-record", parents: ["com.apple.resolvable", "public.data"], description: "Alias record")
        add("com.apple.bookmark", parents: ["com.apple.resolvable", "public.data"], description: "Bookmark data")
        add("public.bookmark", parents: ["public.item"], description: "Bookmark")
        add("public.url", parents: ["public.data"], description: "URL", mime: ["text/uri-list"])
        add("public.file-url", parents: ["public.url"], description: "File URL")
        add("com.apple.internet-location", parents: ["public.data"], description: "Internet location")
        add("com.apple.package", parents: ["public.directory"], description: "Package")
        add("com.apple.bundle", parents: ["public.directory"], description: "Bundle")
        add("com.apple.plugin", parents: ["com.apple.bundle", "com.apple.package"], description: "Plug-in", ext: ["plugin"])
        add("com.apple.metadata-importer", parents: ["com.apple.plugin"], description: "Spotlight importer", ext: ["mdimporter"])
        add("com.apple.quicklook-generator", parents: ["com.apple.plugin"], description: "Quick Look generator", ext: ["qlgenerator"])
        add("com.apple.xpc-service", parents: ["com.apple.bundle", "com.apple.package"], description: "XPC service", ext: ["xpc"])
        add("com.apple.framework", parents: ["com.apple.bundle"], description: "Framework", ext: ["framework"])
        add("com.apple.application", parents: ["public.executable"], description: "Application")
        add("com.apple.application-bundle", parents: ["com.apple.application", "com.apple.bundle", "com.apple.package"], description: "Application bundle", ext: ["app"])
        add("com.apple.application-file", parents: ["com.apple.application", "public.data"], description: "Application file")
        add("com.apple.systempreference.prefpane", parents: ["com.apple.bundle", "com.apple.package"], description: "System Preferences pane", ext: ["prefpane"])
        add("public.unix-executable", parents: ["public.data", "public.executable"], description: "Unix executable")
        add("com.microsoft.windows-executable", parents: ["public.data", "public.executable"], description: "Windows executable", ext: ["exe"], mime: ["application/x-msdownload"])
        add("com.sun.java-class", parents: ["public.data"], description: "Java class", ext: ["class"])
        add("com.sun.java-archive", parents: ["public.zip-archive"], description: "Java archive", ext: ["jar"], mime: ["application/java-archive"])

        add("public.text", parents: ["public.data", "public.content"], description: "Text", mime: ["text/plain"])
        add("public.plain-text", parents: ["public.text"], description: "Plain text", ext: ["txt"], mime: ["text/plain"])
        add("public.utf8-plain-text", parents: ["public.plain-text"], description: "UTF-8 plain text", mime: ["text/plain;charset=utf-8"])
        add("public.utf16-plain-text", parents: ["public.plain-text"], description: "UTF-16 plain text", mime: ["text/plain;charset=utf-16"])
        add("public.utf16-external-plain-text", parents: ["public.plain-text"], description: "UTF-16 external plain text")
        add("public.delimited-values-text", parents: ["public.text"], description: "Delimited text")
        add("public.comma-separated-values-text", parents: ["public.delimited-values-text"], description: "Comma-separated text", ext: ["csv"], mime: ["text/csv"])
        add("public.tab-separated-values-text", parents: ["public.delimited-values-text"], description: "Tab-separated text", ext: ["tsv"], mime: ["text/tab-separated-values"])
        add("public.utf8-tab-separated-values-text", parents: ["public.tab-separated-values-text", "public.utf8-plain-text"], description: "UTF-8 tab-separated text")
        add("public.rtf", parents: ["public.text"], description: "Rich Text Format", ext: ["rtf"], mime: ["text/rtf"])
        add("public.html", parents: ["public.text"], description: "HTML", ext: ["html", "htm"], mime: ["text/html"])
        add("public.xml", parents: ["public.text"], description: "XML", ext: ["xml"], mime: ["application/xml", "text/xml"])
        add("public.source-code", parents: ["public.plain-text"], description: "Source code")
        add("public.assembly-source", parents: ["public.source-code"], description: "Assembly source", ext: ["s", "asm"])
        add("public.c-source", parents: ["public.source-code"], description: "C source", ext: ["c"])
        add("public.objective-c-source", parents: ["public.source-code"], description: "Objective-C source", ext: ["m"])
        add("public.swift-source", parents: ["public.source-code"], description: "Swift source", ext: ["swift"])
        add("public.c-plus-plus-source", parents: ["public.source-code"], description: "C++ source", ext: ["cp", "cpp", "cc", "cxx"])
        add("public.objective-c-plus-plus-source", parents: ["public.source-code"], description: "Objective-C++ source", ext: ["mm"])
        add("public.c-header", parents: ["public.source-code"], description: "C header", ext: ["h"])
        add("public.c-plus-plus-header", parents: ["public.source-code"], description: "C++ header", ext: ["hh", "hpp"])
        add("com.sun.java-source", parents: ["public.source-code"], description: "Java source", ext: ["java"])
        add("public.script", parents: ["public.source-code"], description: "Script")
        add("com.apple.applescript.text", parents: ["public.script"], description: "AppleScript text", ext: ["applescript"])
        add("com.apple.applescript.script", parents: ["public.script"], description: "AppleScript", ext: ["scpt"])
        add("com.apple.applescript.script-bundle", parents: ["com.apple.bundle", "com.apple.package"], description: "AppleScript bundle", ext: ["scptd"])
        add("com.netscape.javascript-source", parents: ["public.script", "public.executable"], description: "JavaScript", ext: ["js"], mime: ["text/javascript"])
        add("public.shell-script", parents: ["public.script"], description: "Shell script", ext: ["sh", "command"])
        add("public.perl-script", parents: ["public.shell-script"], description: "Perl script", ext: ["pl"], mime: ["text/x-perl-script"])
        add("public.python-script", parents: ["public.shell-script"], description: "Python script", ext: ["py"], mime: ["text/x-python-script"])
        add("public.ruby-script", parents: ["public.shell-script"], description: "Ruby script", ext: ["rb"], mime: ["text/x-ruby-script"])
        add("public.php-script", parents: ["public.shell-script"], description: "PHP script", ext: ["php"], mime: ["text/php"])
        add("public.json", parents: ["public.text"], description: "JSON", ext: ["json"], mime: ["application/json"])
        add("com.apple.property-list", parents: ["public.data"], description: "Property list", ext: ["plist"])
        add("com.apple.xml-property-list", parents: ["com.apple.property-list", "public.xml"], description: "XML property list", ext: ["plist"])
        add("com.apple.binary-property-list", parents: ["com.apple.property-list"], description: "Binary property list", ext: ["plist"])
        add("com.adobe.pdf", parents: ["public.data", "public.composite-content"], description: "PDF", ext: ["pdf"], mime: ["application/pdf"])
        add("com.apple.rtfd", parents: ["com.apple.package", "public.composite-content"], description: "Rich Text Format Directory", ext: ["rtfd"])
        add("com.apple.flat-rtfd", parents: ["public.composite-content", "public.data"], description: "Flat RTFD")
        add("com.apple.traditional-mac-plain-text", parents: ["public.text"], description: "Traditional Mac text")
        add("com.apple.webarchive", parents: ["public.composite-content", "public.data"], description: "Web archive", ext: ["webarchive"], mime: ["application/x-webarchive"])
        add("com.apple.ink-text", parents: ["public.data"], description: "Ink text")

        add("public.image", parents: ["public.data", "public.content"], description: "Image")
        add("public.jpeg", parents: ["public.image"], description: "JPEG image", ext: ["jpeg", "jpg", "jpe"], mime: ["image/jpeg"])
        add("public.jpeg-2000", parents: ["public.image"], description: "JPEG 2000 image", ext: ["jp2"], mime: ["image/jp2"])
        add("public.tiff", parents: ["public.image"], description: "TIFF image", ext: ["tiff", "tif"], mime: ["image/tiff"])
        add("com.apple.pict", parents: ["public.image"], description: "PICT image", ext: ["pict", "pct", "pic"])
        add("com.compuserve.gif", parents: ["public.image"], description: "GIF image", ext: ["gif"], mime: ["image/gif"])
        add("public.png", parents: ["public.image"], description: "PNG image", ext: ["png"], mime: ["image/png"])
        add("com.apple.quicktime-image", parents: ["public.image"], description: "QuickTime image", ext: ["qtif", "qti"], mime: ["image/x-quicktime"])
        add("com.apple.icns", parents: ["public.image"], description: "Apple icon image", ext: ["icns"])
        add("com.microsoft.bmp", parents: ["public.image"], description: "Windows bitmap image", ext: ["bmp"], mime: ["image/bmp"])
        add("com.microsoft.ico", parents: ["public.image"], description: "Windows icon image", ext: ["ico"], mime: ["image/vnd.microsoft.icon"])
        add("public.camera-raw-image", parents: ["public.image"], description: "Raw image")
        add("public.svg-image", parents: ["public.image", "public.xml"], description: "SVG image", ext: ["svg"], mime: ["image/svg+xml"])
        add("com.apple.live-photo", parents: ["public.image"], description: "Live Photo")

        add("public.audiovisual-content", parents: ["public.data", "public.content"], description: "Audiovisual content")
        add("public.movie", parents: ["public.audiovisual-content"], description: "Movie")
        add("public.video", parents: ["public.movie"], description: "Video")
        add("public.audio", parents: ["public.audiovisual-content"], description: "Audio")
        add("com.apple.quicktime-movie", parents: ["public.movie"], description: "QuickTime movie", ext: ["mov", "qt"], mime: ["video/quicktime"])
        add("public.mpeg", parents: ["public.movie"], description: "MPEG movie", ext: ["mpeg", "mpg", "mpe"], mime: ["video/mpeg"])
        add("public.mpeg-2-video", parents: ["public.video"], description: "MPEG-2 video", ext: ["m2v"], mime: ["video/mpeg2"])
        add("public.mpeg-2-transport-stream", parents: ["public.movie"], description: "MPEG-2 transport stream", ext: ["ts", "mts"])
        add("public.mp3", parents: ["public.audio"], description: "MP3 audio", ext: ["mp3", "mpga"], mime: ["audio/mpeg"])
        add("public.mpeg-4", parents: ["public.movie"], description: "MPEG-4 movie", ext: ["mp4"], mime: ["video/mp4"])
        add("public.mpeg-4-audio", parents: ["public.audio"], description: "MPEG-4 audio", ext: ["m4a"], mime: ["audio/mp4"])
        add("com.apple.protected-mpeg-4-audio", parents: ["public.audio"], description: "Protected MPEG-4 audio", ext: ["m4p"])
        add("com.apple.protected-mpeg-4-video", parents: ["public.mpeg-4"], description: "Protected MPEG-4 video", ext: ["m4v"])
        add("public.avi", parents: ["public.movie"], description: "AVI movie", ext: ["avi"], mime: ["video/avi"])
        add("public.aiff-audio", parents: ["public.audio"], description: "AIFF audio", ext: ["aiff", "aif", "aifc"], mime: ["audio/aiff"])
        add("com.microsoft.waveform-audio", parents: ["public.audio"], description: "Waveform audio", ext: ["wav", "wave"], mime: ["audio/vnd.wave"])
        add("public.midi-audio", parents: ["public.audio"], description: "MIDI audio", ext: ["midi", "mid"], mime: ["audio/midi"])
        add("public.playlist", parents: ["public.item"], description: "Playlist")
        add("public.m3u-playlist", parents: ["public.playlist", "public.plain-text"], description: "M3U playlist", ext: ["m3u", "m3u8"], mime: ["audio/mpegurl"])

        add("org.gnu.gnu-zip-archive", parents: ["public.archive", "public.data"], description: "gzip archive", ext: ["gz", "gzip"], mime: ["application/x-gzip"])
        add("public.bzip2-archive", parents: ["public.archive", "public.data"], description: "bzip2 archive", ext: ["bz2"], mime: ["application/x-bzip2"])
        add("public.zip-archive", parents: ["public.archive", "public.data"], description: "ZIP archive", ext: ["zip"], mime: ["application/zip"])
        add("public.spreadsheet", parents: ["public.content"], description: "Spreadsheet")
        add("public.presentation", parents: ["public.content"], description: "Presentation")
        add("public.database", parents: ["public.item"], description: "Database")
        add("public.calendar-event", parents: ["public.content"], description: "Calendar event", ext: ["ics"], mime: ["text/calendar"])
        add("public.to-do-item", parents: ["public.content"], description: "To-do item")
        add("public.contact", parents: ["public.content"], description: "Contact")
        add("public.vcard", parents: ["public.contact", "public.text"], description: "vCard", ext: ["vcf", "vcard"], mime: ["text/vcard"])
        add("public.message", parents: ["public.content"], description: "Message")
        add("public.email-message", parents: ["public.message"], description: "Email message", ext: ["eml"], mime: ["message/rfc822"])
        add("public.font", parents: ["public.data", "public.content"], description: "Font")
        add("public.3d-content", parents: ["public.content"], description: "3D content")
        add("com.rsa.pkcs-12", parents: ["public.data"], description: "PKCS #12", ext: ["p12", "pfx"], mime: ["application/x-pkcs12"])
        add("public.x509-certificate", parents: ["public.data"], description: "X.509 certificate", ext: ["cer", "crt", "der"], mime: ["application/x-x509-ca-cert"])
        add("org.idpf.epub-container", parents: ["public.composite-content", "public.data"], description: "EPUB publication", ext: ["epub"], mime: ["application/epub+zip"])
        add("public.log", parents: ["public.plain-text", "public.item"], description: "Log file", ext: ["log"])

        return result
    }
}
