import Foundation
import UniformTypeIdentifiers

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build UniformTypeIdentifiers with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports UniformTypeIdentifiers and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `UNIFORMTYPEIDENTIFIERS_DEPENDENCY_IDENTITY_OK` and that
//    `libUniformTypeIdentifiers.dylib` was loaded.

private func assertNotUniformTypeIdentifiersType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("UniformTypeIdentifiers."))
}

/// Pass genuine Foundation values through public UniformTypeIdentifiers APIs.
func uniformTypeIdentifiersDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/identity-photo")
    assertNotUniformTypeIdentifiersType(url)
    precondition(type(of: url) == URL.self)

    let jpegURL = url.appendingPathExtension(for: .jpeg)
    precondition(jpegURL.pathExtension == "jpeg")
    assertNotUniformTypeIdentifiersType(jpegURL.pathExtension)

    let named = url.appendingPathComponent("shot", conformingTo: .png)
    precondition(named.lastPathComponent == "shot.png")

    var mutable = url
    mutable.appendPathExtension(for: .gif)
    precondition(mutable.pathExtension == "gif")
    mutable = url
    mutable.appendPathComponent("clip", conformingTo: .mpeg4Movie)
    precondition(mutable.lastPathComponent.hasPrefix("clip"))

    let nsName: NSString = "report"
    assertNotUniformTypeIdentifiersType(nsName)
    let pdfName = nsName.appendingPathExtension(for: .pdf)
    precondition(pdfName.hasSuffix(".pdf"))
    let csvName = nsName.appendingPathComponent("table", conformingTo: .commaSeparatedText)
    precondition(csvName.contains("table"))

    let nsURL = NSURL(fileURLWithPath: "/tmp/identity-doc")
    assertNotUniformTypeIdentifiersType(nsURL)
    let xmlURL = nsURL.appendingPathExtension(for: .xml)
    precondition(xmlURL.pathExtension == "xml")
    let folderURL = nsURL.appendingPathComponent("bundle", conformingTo: .applicationBundle)
    precondition(folderURL.lastPathComponent.contains("bundle"))

    let values = URLResourceValues()
    precondition(values.contentType == nil)

    let encoded = try! JSONEncoder().encode(UTType.png)
    let decoded = try! JSONDecoder().decode(UTType.self, from: encoded)
    precondition(decoded == .png)
    assertNotUniformTypeIdentifiersType(encoded)

    let fromString = UTType(filenameExtension: "JSON")
    precondition(fromString == .json)
}

#if UTI_IDENTITY_MAIN
uniformTypeIdentifiersDependencyIdentityProbe()
print("UNIFORMTYPEIDENTIFIERS_DEPENDENCY_IDENTITY_OK")
#endif
