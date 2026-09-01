import Foundation

struct _UTRecord: Sendable {
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

enum _UTRegistry {
    static func identifiersEqual(_ lhs: String, _ rhs: String) -> Bool {
        lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }

    static func isDynamic(_ identifier: String) -> Bool {
        identifier.lowercased().hasPrefix("dyn.")
    }

    static func isDeclared(_ identifier: String) -> Bool {
        record(for: identifier) != nil
    }

    static func conforms(_ identifier: String, to parent: String) -> Bool {
        if identifiersEqual(identifier, parent) {
            return true
        }
        guard let start = canonicalIdentifier(identifier) else {
            return false
        }
        let target = canonicalIdentifier(parent) ?? parent.lowercased()
        var pending = record(for: start)?.parents ?? []
        var visited: Set<String> = []
        while let candidate = pending.popLast() {
            if candidate.lowercased() == target {
                return true
            }
            guard visited.insert(candidate.lowercased()).inserted else { continue }
            pending.append(contentsOf: record(for: candidate)?.parents ?? [])
        }
        return false
    }

    static func preferredTag(_ identifier: String, tagClass: String) -> String? {
        allTags(identifier, tagClass: tagClass).first
    }

    static func allTags(_ identifier: String, tagClass: String) -> [String] {
        guard let record = record(for: identifier) else { return [] }
        switch classify(tagClass) {
        case .filenameExtension:
            return record.filenameExtensions
        case .mimeType:
            return record.mimeTypes
        case .unknown:
            return []
        }
    }

    static func declaration(_ identifier: String) -> NSDictionary? {
        guard let canonical = canonicalIdentifier(identifier),
              let record = records[canonical]
        else {
            return nil
        }
        let declaration = NSMutableDictionary()
        declaration.setObject(canonical as NSString, forKey: kUTTypeIdentifierKey)
        if record.parents.count == 1 {
            declaration.setObject(record.parents[0] as NSString, forKey: kUTTypeConformsToKey)
        } else if record.parents.count > 1 {
            declaration.setObject(
                record.parents.map { $0 as NSString } as NSArray,
                forKey: kUTTypeConformsToKey
            )
        }
        let tags = NSMutableDictionary()
        if !record.filenameExtensions.isEmpty {
            tags.setObject(tagValue(record.filenameExtensions), forKey: kUTTagClassFilenameExtension)
        }
        if !record.mimeTypes.isEmpty {
            tags.setObject(tagValue(record.mimeTypes), forKey: kUTTagClassMIMEType)
        }
        if tags.count > 0 {
            declaration.setObject(tags, forKey: kUTTypeTagSpecificationKey)
        }
        return declaration
    }

    static func allIdentifiers(
        tagClass: String,
        tag: String,
        conformingTo: String?
    ) -> [String] {
        let needle = normalize(tag, tagClass: tagClass)
        guard !needle.isEmpty else { return [] }
        var matches: [String] = []
        for (identifier, record) in records {
            let values: [String]
            switch classify(tagClass) {
            case .filenameExtension:
                values = record.filenameExtensions
            case .mimeType:
                values = record.mimeTypes
            case .unknown:
                return []
            }
            let hasTag = values.contains { value in
                normalize(value, tagClass: tagClass) == needle
            }
            guard hasTag else { continue }
            if let conformingTo, !conforms(identifier, to: conformingTo) {
                continue
            }
            matches.append(identifier)
        }
        return matches.sorted()
    }

    static func preferredIdentifier(
        tagClass: String,
        tag: String,
        conformingTo: String?
    ) -> String? {
        let matches = allIdentifiers(
            tagClass: tagClass,
            tag: tag,
            conformingTo: conformingTo
        )
        guard !matches.isEmpty else { return nil }
        for candidate in matches {
            if matches.allSatisfy({ conforms($0, to: candidate) }) {
                return candidate
            }
        }
        return matches.first
    }

    private enum TagClass {
        case filenameExtension
        case mimeType
        case unknown
    }

    private static func classify(_ tagClass: String) -> TagClass {
        if identifiersEqual(tagClass, kUTTagClassFilenameExtension as String) {
            return .filenameExtension
        }
        if identifiersEqual(tagClass, kUTTagClassMIMEType as String) {
            return .mimeType
        }
        return .unknown
    }

    private static func normalize(_ tag: String, tagClass: String) -> String {
        var value = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if classify(tagClass) == .filenameExtension, value.hasPrefix(".") {
            value.removeFirst()
        }
        return value
    }

    private static func tagValue(_ tags: [String]) -> Any {
        if tags.count == 1 {
            return tags[0] as NSString
        }
        return tags.map { $0 as NSString } as NSArray
    }

    private static func record(for identifier: String) -> _UTRecord? {
        guard let canonical = canonicalIdentifier(identifier) else { return nil }
        return records[canonical]
    }

    private static func canonicalIdentifier(_ identifier: String) -> String? {
        let lowered = identifier.lowercased()
        if records[identifier] != nil {
            return identifier
        }
        return records.keys.first { $0.lowercased() == lowered }
    }

    static let records: [String: _UTRecord] = [
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
        "com.apple.application-file": .init(
            parents: ["com.apple.application", "public.data"]
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
        "public.disk-image": .init(parents: ["public.archive"]),
        "public.url": .init(parents: ["public.data"], mimeTypes: ["text/uri-list"]),
        "public.file-url": .init(parents: ["public.url"]),
        "public.bookmark": .init(parents: []),
        "com.apple.resolvable": .init(parents: []),
        "public.symlink": .init(parents: ["com.apple.resolvable", "public.item"]),
        "com.apple.mount-point": .init(parents: ["com.apple.resolvable", "public.item"]),
        "com.apple.alias-file": .init(parents: ["com.apple.resolvable", "public.data"]),
        "com.apple.alias-record": .init(parents: ["public.data"]),
        "com.apple.bookmark": .init(parents: ["com.apple.resolvable", "public.data"]),
        "com.apple.internet-location": .init(parents: ["public.data"]),

        "public.text": .init(
            parents: ["public.data", "public.content"],
            mimeTypes: ["text/plain"]
        ),
        "public.plain-text": .init(
            parents: ["public.text"],
            filenameExtensions: ["txt"],
            mimeTypes: ["text/plain"]
        ),
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
        "public.comma-separated-values-text": .init(
            parents: ["public.delimited-values-text"],
            filenameExtensions: ["csv"],
            mimeTypes: ["text/csv"]
        ),
        "public.tab-separated-values-text": .init(
            parents: ["public.delimited-values-text"],
            filenameExtensions: ["tsv"],
            mimeTypes: ["text/tab-separated-values"]
        ),
        "public.utf8-tab-separated-values-text": .init(
            parents: ["public.tab-separated-values-text", "public.utf8-plain-text"]
        ),
        "public.rtf": .init(
            parents: ["public.text"],
            filenameExtensions: ["rtf"],
            mimeTypes: ["text/rtf"]
        ),
        "com.apple.rtfd": .init(
            parents: ["com.apple.package", "public.composite-content"],
            filenameExtensions: ["rtfd"]
        ),
        "com.apple.flat-rtfd": .init(parents: ["public.composite-content"]),
        "public.html": .init(
            parents: ["public.text"],
            filenameExtensions: ["html", "htm"],
            mimeTypes: ["text/html"]
        ),
        "public.xml": .init(
            parents: ["public.text"],
            filenameExtensions: ["xml"],
            mimeTypes: ["application/xml", "text/xml"]
        ),
        "public.source-code": .init(parents: ["public.plain-text"]),
        "public.assembly-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["s"]
        ),
        "public.c-header": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["h"]
        ),
        "public.c-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["c"]
        ),
        "public.objective-c-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["m"]
        ),
        "public.objective-c-plus-plus-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["mm"]
        ),
        "public.swift-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["swift"]
        ),
        "public.c-plus-plus-header": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["hh", "hpp"]
        ),
        "public.c-plus-plus-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["cp", "cpp", "cc", "cxx"]
        ),
        "com.sun.java-source": .init(
            parents: ["public.source-code"],
            filenameExtensions: ["java"],
            mimeTypes: ["text/x-java-source"]
        ),
        "public.script": .init(parents: ["public.source-code"]),
        "public.shell-script": .init(
            parents: ["public.script"],
            filenameExtensions: ["sh"]
        ),
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
        "public.json": .init(
            parents: ["public.text"],
            filenameExtensions: ["json"],
            mimeTypes: ["application/json"]
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
        "com.adobe.pdf": .init(
            parents: ["public.data", "public.composite-content"],
            filenameExtensions: ["pdf"],
            mimeTypes: ["application/pdf"]
        ),
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
        "com.apple.ink.inktext": .init(parents: ["public.data"]),
        "com.apple.txn.text-multimedia-data": .init(
            parents: ["public.data", "public.composite-content"]
        ),

        "public.image": .init(parents: ["public.data", "public.content"]),
        "public.jpeg": .init(
            parents: ["public.image"],
            filenameExtensions: ["jpeg", "jpg", "jpe"],
            mimeTypes: ["image/jpeg"]
        ),
        "public.tiff": .init(
            parents: ["public.image"],
            filenameExtensions: ["tiff", "tif"],
            mimeTypes: ["image/tiff"]
        ),
        "com.compuserve.gif": .init(
            parents: ["public.image"],
            filenameExtensions: ["gif"],
            mimeTypes: ["image/gif"]
        ),
        "public.png": .init(
            parents: ["public.image"],
            filenameExtensions: ["png"],
            mimeTypes: ["image/png"]
        ),
        "com.apple.icns": .init(
            parents: ["public.image"],
            filenameExtensions: ["icns"]
        ),
        "com.microsoft.bmp": .init(
            parents: ["public.image"],
            filenameExtensions: ["bmp"],
            mimeTypes: ["image/bmp"]
        ),
        "com.microsoft.ico": .init(
            parents: ["public.image"],
            filenameExtensions: ["ico"],
            mimeTypes: ["image/vnd.microsoft.icon"]
        ),
        "public.svg-image": .init(
            parents: ["public.image", "public.xml"],
            filenameExtensions: ["svg"],
            mimeTypes: ["image/svg+xml"]
        ),
        "public.jpeg-2000": .init(
            parents: ["public.image"],
            filenameExtensions: ["jp2"],
            mimeTypes: ["image/jp2"]
        ),
        "public.camera-raw-image": .init(parents: ["public.image"]),
        "com.apple.pict": .init(
            parents: ["public.image"],
            filenameExtensions: ["pict", "pct", "pic"]
        ),
        "com.apple.quicktime-image": .init(
            parents: ["public.image"],
            filenameExtensions: ["qtif", "qti"],
            mimeTypes: ["image/x-quicktime"]
        ),
        "com.apple.live-photo": .init(parents: []),

        "public.audiovisual-content": .init(parents: ["public.data", "public.content"]),
        "public.movie": .init(parents: ["public.audiovisual-content"]),
        "public.video": .init(parents: ["public.movie"]),
        "public.audio": .init(parents: ["public.audiovisual-content"]),
        "com.apple.quicktime-movie": .init(
            parents: ["public.movie"],
            filenameExtensions: ["mov", "qt"],
            mimeTypes: ["video/quicktime"]
        ),
        "public.mpeg": .init(
            parents: ["public.movie"],
            filenameExtensions: ["mpeg", "mpg"],
            mimeTypes: ["video/mpeg"]
        ),
        "public.mpeg-2-video": .init(
            parents: ["public.video"],
            filenameExtensions: ["m2v"],
            mimeTypes: ["video/mpeg2"]
        ),
        "public.mpeg-2-transport-stream": .init(
            parents: ["public.movie"],
            filenameExtensions: ["ts"]
        ),
        "public.mpeg-4": .init(
            parents: ["public.movie"],
            filenameExtensions: ["mp4"],
            mimeTypes: ["video/mp4"]
        ),
        "com.apple.m4v-video": .init(
            parents: ["public.movie"],
            filenameExtensions: ["m4v"],
            mimeTypes: ["video/x-m4v"]
        ),
        "com.apple.protected-mpeg-4-video": .init(
            parents: ["com.apple.m4v-video", "public.mpeg-4"]
        ),
        "public.mp3": .init(
            parents: ["public.audio"],
            filenameExtensions: ["mp3"],
            mimeTypes: ["audio/mpeg"]
        ),
        "public.mpeg-4-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["m4a"],
            mimeTypes: ["audio/mp4"]
        ),
        "com.apple.protected-mpeg-4-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["m4p"]
        ),
        "public.avi": .init(
            parents: ["public.movie"],
            filenameExtensions: ["avi"],
            mimeTypes: ["video/avi"]
        ),
        "public.aiff-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["aiff", "aif"],
            mimeTypes: ["audio/aiff"]
        ),
        "com.microsoft.waveform-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["wav"],
            mimeTypes: ["audio/vnd.wave"]
        ),
        "public.midi-audio": .init(
            parents: ["public.audio"],
            filenameExtensions: ["midi", "mid"],
            mimeTypes: ["audio/midi"]
        ),
        "public.playlist": .init(parents: []),
        "public.m3u-playlist": .init(
            parents: ["public.playlist", "public.plain-text"],
            filenameExtensions: ["m3u"],
            mimeTypes: ["audio/mpegurl"]
        ),

        "public.zip-archive": .init(
            parents: ["public.archive", "public.data"],
            filenameExtensions: ["zip"],
            mimeTypes: ["application/zip"]
        ),
        "org.gnu.gnu-zip-archive": .init(
            parents: ["public.archive", "public.data"],
            filenameExtensions: ["gz"],
            mimeTypes: ["application/gzip"]
        ),
        "public.bzip2-archive": .init(
            parents: ["public.archive", "public.data"],
            filenameExtensions: ["bz2"],
            mimeTypes: ["application/x-bzip2"]
        ),
        "public.font": .init(parents: ["public.data", "public.content"]),
        "public.database": .init(parents: []),
        "public.x509-certificate": .init(
            parents: ["public.data"],
            filenameExtensions: ["cer"],
            mimeTypes: ["application/x-x509-ca-cert"]
        ),
        "com.rsa.pkcs-12": .init(
            parents: ["public.data"],
            filenameExtensions: ["p12", "pfx"],
            mimeTypes: ["application/x-pkcs12"]
        ),
        "com.sun.java-class": .init(
            parents: ["public.data", "public.executable"],
            filenameExtensions: ["class"]
        ),
        "com.sun.java-archive": .init(
            parents: ["public.archive", "public.data"],
            filenameExtensions: ["jar"],
            mimeTypes: ["application/java-archive"]
        ),
        "public.3d-content": .init(parents: ["public.content"]),
    ]
}
