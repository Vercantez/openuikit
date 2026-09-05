import Foundation

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// Host-only stand-ins for types owned by modules that are not declared
// dependencies of this isolated Foundation gate (UniformTypeIdentifiers,
// CoreGraphics, PDFKit, UIKit). Compiled out when the real modules are
// importable. Do not treat these as Apple runtime evidence.

#if !canImport(UniformTypeIdentifiers)
public struct UTType: Hashable, Sendable {
  public let identifier: String
  private let declaredParent: String?

  private init(unchecked identifier: String, parent: String? = nil) {
    self.identifier = identifier
    self.declaredParent = parent
  }

  public init?(filenameExtension: String, conformingTo parentType: UTType = .data) {
    let needle = filenameExtension.lowercased()
    guard let identifier = Self._extensionToIdentifier[needle] else { return nil }
    let type = UTType(unchecked: identifier)
    guard type.conforms(to: parentType) else { return nil }
    self = type
  }

  public init(importedAs identifier: String, conformingTo parentType: UTType? = nil) {
    self.init(unchecked: identifier, parent: parentType?.identifier)
  }

  public static let data = UTType(unchecked: "public.data")
  public static let image = UTType(unchecked: "public.image")
  public static let jpeg = UTType(unchecked: "public.jpeg")
  public static let png = UTType(unchecked: "public.png")
  public static let pdf = UTType(unchecked: "com.adobe.pdf")
  public static let text = UTType(unchecked: "public.text")
  public static let plainText = UTType(unchecked: "public.plain-text")
  public static let html = UTType(unchecked: "public.html")
  public static let rtf = UTType(unchecked: "public.rtf")
  public static let commaSeparatedText = UTType(unchecked: "public.comma-separated-values-text")
  public static let presentation = UTType(unchecked: "public.presentation")
  public static let spreadsheet = UTType(unchecked: "public.spreadsheet")
  public static let audiovisualContent = UTType(unchecked: "public.audiovisual-content")
  public static let movie = UTType(unchecked: "public.movie")
  public static let audio = UTType(unchecked: "public.audio")
  public static let archive = UTType(unchecked: "public.archive")
  public static let zip = UTType(unchecked: "public.zip-archive")
  public static let threeDContent = UTType(unchecked: "public.3d-content")
  public static let usdz = UTType(unchecked: "com.pixar.universal-scene-description-mobile")

  public func conforms(to otherType: UTType) -> Bool {
    if identifier == otherType.identifier { return true }
    var pending = Self._parents[identifier] ?? []
    if let declaredParent { pending.append(declaredParent) }
    var visited: Set<String> = []
    while let candidate = pending.popLast() {
      if candidate == otherType.identifier { return true }
      guard visited.insert(candidate).inserted else { continue }
      pending.append(contentsOf: Self._parents[candidate] ?? [])
    }
    return false
  }

  private static let _extensionToIdentifier: [String: String] = [
    "txt": "public.plain-text",
    "text": "public.plain-text",
    "csv": "public.comma-separated-values-text",
    "tsv": "public.tab-separated-values-text",
    "rtf": "public.rtf",
    "html": "public.html",
    "htm": "public.html",
    "xml": "public.xml",
    "json": "public.json",
    "pdf": "com.adobe.pdf",
    "jpeg": "public.jpeg",
    "jpg": "public.jpeg",
    "jpe": "public.jpeg",
    "png": "public.png",
    "gif": "com.compuserve.gif",
    "tif": "public.tiff",
    "tiff": "public.tiff",
    "bmp": "com.microsoft.bmp",
    "heic": "public.heic",
    "heif": "public.heif",
    "webp": "org.webmproject.webp",
    "svg": "public.svg-image",
    "mp4": "public.mpeg-4",
    "m4v": "com.apple.m4v-video",
    "mov": "com.apple.quicktime-movie",
    "m4a": "public.mpeg-4-audio",
    "mp3": "public.mp3",
    "wav": "com.microsoft.waveform-audio",
    "zip": "public.zip-archive",
    "usdz": "com.pixar.universal-scene-description-mobile",
    "usd": "com.pixar.universal-scene-description",
  ]

  private static let _parents: [String: [String]] = [
    "public.plain-text": ["public.text"],
    "public.comma-separated-values-text": ["public.delimited-values-text"],
    "public.tab-separated-values-text": ["public.delimited-values-text"],
    "public.delimited-values-text": ["public.text"],
    "public.rtf": ["public.text"],
    "public.html": ["public.text"],
    "public.xml": ["public.text"],
    "public.json": ["public.text"],
    "public.text": ["public.data", "public.content"],
    "com.adobe.pdf": ["public.data", "public.composite-content"],
    "public.jpeg": ["public.image"],
    "public.png": ["public.image"],
    "com.compuserve.gif": ["public.image"],
    "public.tiff": ["public.image"],
    "com.microsoft.bmp": ["public.image"],
    "public.heic": ["public.heif"],
    "public.heif": ["public.image"],
    "org.webmproject.webp": ["public.image"],
    "public.svg-image": ["public.image", "public.xml"],
    "public.image": ["public.data", "public.content"],
    "public.mpeg-4": ["public.movie"],
    "com.apple.m4v-video": ["public.movie"],
    "com.apple.quicktime-movie": ["public.movie"],
    "public.movie": ["public.audiovisual-content"],
    "public.mpeg-4-audio": ["public.audio"],
    "public.mp3": ["public.audio"],
    "com.microsoft.waveform-audio": ["public.audio"],
    "public.audio": ["public.audiovisual-content"],
    "public.audiovisual-content": ["public.content"],
    "public.zip-archive": ["public.archive", "public.data"],
    "public.archive": ["public.data"],
    "com.pixar.universal-scene-description-mobile": [
      "com.pixar.universal-scene-description"
    ],
    "com.pixar.universal-scene-description": ["public.3d-content", "public.data"],
    "public.3d-content": ["public.content"],
    "public.composite-content": ["public.content"],
    "public.data": ["public.item"],
  ]
}
#endif

#if !canImport(CoreGraphics)
public final class CGContext: NSObject, @unchecked Sendable {}
#endif

#if !canImport(PDFKit)
open class PDFDocument: NSObject, @unchecked Sendable {}
#endif

#if !canImport(UIKit)
open class UIView: NSObject, @unchecked Sendable {}

open class UIImage: NSObject, @unchecked Sendable {
  public override init() {
    super.init()
  }
}
#endif

/// Documented built-in Quick Look families from Apple's QLPreviewController
/// page plus the WWDC 2018 preview list: images, PDF, public.text (including
/// RTF/HTML), CSV, iWork/Office, audiovisual, ZIP, and USDZ. Third-party
/// generators are not claimed.
enum _QLPreviewKind: String, Equatable {
  case empty
  case image
  case pdf
  case text
  case other
  case unsupported
}

enum _QLPreviewableContent {
  /// Office/iWork extensions documented for Quick Look but not registered
  /// in the current UniformTypeIdentifiers port.
  static let documentedOfficeAndIWorkExtensions: Set<String> = [
    "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pps", "ppsx",
    "pages", "numbers", "key",
  ]

  static func utType(for url: URL) -> UTType? {
    let ext = url.pathExtension
    guard !ext.isEmpty else { return nil }
    return UTType(filenameExtension: ext)
  }

  static func isPreviewable(url: URL) -> Bool {
    switch kind(for: url) {
    case .image, .pdf, .text, .other:
      return true
    case .empty, .unsupported:
      return false
    }
  }

  static func kind(for url: URL?) -> _QLPreviewKind {
    guard let url, url.isFileURL else { return .empty }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    else {
      return .unsupported
    }
    let ext = url.pathExtension.lowercased()
    if isDirectory.boolValue {
      guard documentedOfficeAndIWorkExtensions.contains(ext) else {
        return .unsupported
      }
      return .other
    }
    if documentedOfficeAndIWorkExtensions.contains(ext) {
      return .other
    }
    guard let type = utType(for: url) else { return .unsupported }
    if type.conforms(to: .image) { return .image }
    if type.conforms(to: .pdf) { return .pdf }
    if type.conforms(to: .text) { return .text }
    if type.conforms(to: .audiovisualContent)
      || type.conforms(to: .archive)
      || type.conforms(to: .threeDContent)
      || type.conforms(to: .presentation)
      || type.conforms(to: .spreadsheet)
    {
      return .other
    }
    return .unsupported
  }
}
