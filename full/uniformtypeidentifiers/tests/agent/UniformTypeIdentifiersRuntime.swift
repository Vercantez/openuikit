import Foundation
import UniformTypeIdentifiers

// Standalone host probe (schema-v2 sealed gate compiles tests/agent/*Tests.swift).
// Exercises the portable registry and fail-closed Foundation overlays.

precondition(UTType.png.identifier == "public.png")
precondition(UTType.png.preferredFilenameExtension == "png")
precondition(UTType.jpeg.preferredMIMEType == "image/jpeg")
precondition(UTType("not.registered") == nil)
precondition(UTType.gif.conforms(to: .image))
precondition(UTType.jpeg.isSubtype(of: .image))
precondition(UTType.image.isSupertype(of: .jpeg))
precondition(UTType(filenameExtension: "JPG") == .jpeg)
precondition(UTType.tarArchive.identifier == "public.tar-archive")

let exported = UTType(exportedAs: "com.example.runtime", conformingTo: .data)
precondition(exported.conforms(to: .item))
precondition(!exported.isDeclared)

let reference = UTTypeReference(filenameExtension: "png")
precondition(reference?.identifier == "public.png")
precondition(UTTypeReference(coder: NSCoder()).map { _ in false } ?? true)

var url = URL(fileURLWithPath: "/tmp/runtime")
url.appendPathExtension(for: .jpeg)
precondition(url.pathExtension == "jpeg")
precondition(URLResourceValues().contentType == nil)

print("UNIFORMTYPEIDENTIFIERS_AGENT_RUNTIME_OK")
