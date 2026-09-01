import SwiftUI
import UIKit
import Foundation
import NaturalLanguage
import AuthenticationServices
import Accelerate
import Compression
import CoreText

private struct TrueIOSSwiftUIDylibView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("SwiftUI dynamic framework")
                .font(.headline)
            Button("Advance") {}
        }
        .padding(.all, 12)
    }
}

@MainActor
private func allDescendants(of root: UIView) -> [UIView] {
    root.subviews + root.subviews.flatMap(allDescendants)
}

private func proveAccelerate() {
    var source: [UInt8] = [
        10, 0, 1, 2,   20, 3, 4, 5,   30, 6, 7, 8,
        40, 9, 10, 11, 50, 12, 13, 14, 60, 15, 16, 17,
        70, 18, 19, 20, 80, 21, 22, 23, 90, 24, 25, 26
    ]
    var output = [UInt8](repeating: 0, count: source.count)
    let status = source.withUnsafeMutableBytes { sourceBytes in
        output.withUnsafeMutableBytes { outputBytes in
            var input = vImage_Buffer(
                data: sourceBytes.baseAddress,
                height: 3,
                width: 3,
                rowBytes: 12
            )
            var destination = vImage_Buffer(
                data: outputBytes.baseAddress,
                height: 3,
                width: 3,
                rowBytes: 12
            )
            return vImageBoxConvolve_ARGB8888(
                &input,
                &destination,
                nil,
                0,
                0,
                3,
                3,
                nil,
                vImage_Flags(kvImageEdgeExtend)
            )
        }
    }
    let expected: [UInt8] = [
        23, 4, 5, 6,   30, 6, 7, 8,   37, 8, 9, 10,
        43, 10, 11, 12, 50, 12, 13, 14, 57, 14, 15, 16,
        63, 16, 17, 18, 70, 18, 19, 20, 77, 20, 21, 22
    ]
    precondition(status == kvImageNoError)
    precondition(output == expected)
}

private func proveCompression() throws {
    let expected = Data(
        "IceCubes untouched RevenueCat Brotli response: portable Mach-O guests on Linux"
            .utf8
    )
    let appleEncoded = Data(base64Encoded:
        "iyaASWNlQ3ViZXMgdW50b3VjaGVkIFJldmVudWVDYXQgQnJvdGxpIHJlc3BvbnNlOiBwb3J0YWJsZSBNYWNoLU8gZ3Vlc3RzIG9uIExpbnV4Aw=="
    )!
    guard let algorithm = Algorithm(rawValue: COMPRESSION_BROTLI) else {
        fatalError("COMPRESSION_BROTLI unavailable")
    }
    var readOffset = 0
    let input = try InputFilter<Data>(.decompress, using: algorithm) { requested in
        guard readOffset < appleEncoded.count else { return nil }
        let end = min(readOffset + requested, appleEncoded.count)
        defer { readOffset = end }
        return appleEncoded.subdata(in: readOffset..<end)
    }
    var decoded = Data()
    while let chunk = try input.readData(ofLength: 7) {
        decoded.append(chunk)
    }
    precondition(decoded == expected)

    var encoded = Data()
    let output = try OutputFilter(.compress, using: algorithm) { chunk in
        if let chunk { encoded.append(chunk) }
    }
    try output.write(expected)
    try output.finalize()
    var encodedOffset = 0
    let replay = try InputFilter<Data>(.decompress, using: algorithm) { requested in
        guard encodedOffset < encoded.count else { return nil }
        let end = min(encodedOffset + requested, encoded.count)
        defer { encodedOffset = end }
        return encoded.subdata(in: encodedOffset..<end)
    }
    var roundTrip = Data()
    while let chunk = try replay.readData(ofLength: 11) {
        roundTrip.append(chunk)
    }
    precondition(roundTrip == expected)
}

private func registerFont(_ url: URL) -> (Bool, NSError?) {
    var unmanaged: Unmanaged<CFError>?
    let success = CTFontManagerRegisterFontsForURL(
        url as CFURL,
        .process,
        &unmanaged
    )
    let error = unmanaged?.takeRetainedValue() as Error? as NSError?
    return (success, error)
}

private func proveCoreText() throws {
    precondition(CommandLine.arguments.count == 3)
    let source = URL(fileURLWithPath: CommandLine.arguments[1])
    let root = URL(
        fileURLWithPath: CommandLine.arguments[2],
        isDirectory: true
    )
    let manager = FileManager.default
    try? manager.removeItem(at: root)
    try manager.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? manager.removeItem(at: root) }

    let first = root.appendingPathComponent("first.ttf")
    let second = root.appendingPathComponent("second.ttf")
    let invalid = root.appendingPathComponent("invalid.ttf")
    let missing = root.appendingPathComponent("missing.ttf")
    try manager.copyItem(at: source, to: first)
    try manager.copyItem(at: source, to: second)
    try Data("not a font".utf8).write(to: invalid)

    let initial = registerFont(first)
    let repeated = registerFont(first)
    let duplicate = registerFont(second)
    let malformed = registerFont(invalid)
    let absent = registerFont(missing)
    precondition(initial.0 && initial.1 == nil)
    precondition(
        !repeated.0
            && repeated.1?.code == CTFontManagerError.alreadyRegistered.rawValue
    )
    precondition(duplicate.0 && duplicate.1 == nil)
    precondition(
        !malformed.0
            && malformed.1?.code == CTFontManagerError.unrecognizedFormat.rawValue
    )
    precondition(
        !absent.0
            && absent.1?.code == CTFontManagerError.fileNotFound.rawValue
    )
    precondition(repeated.1?.domain == kCTFontManagerErrorDomain as String)
}

@main
private enum TrueIOSSwiftUIDylibProbe {
    @MainActor
    static func main() throws {
        let controller = UIHostingController(rootView: TrueIOSSwiftUIDylibView())
        let host = controller.view!
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 120)
        host.layoutIfNeeded()

        let descendants = allDescendants(of: host)
        let renderedText = descendants
            .compactMap { $0 as? UILabel }
            .contains { $0.text == "SwiftUI dynamic framework" }
        let renderedButton = descendants
            .contains { $0.accessibilityIdentifier == "SwiftUI.Button" }
        precondition(renderedText && renderedButton)

        let cfSourceNSError = NSError(
            domain: "Portable.Domain",
            code: 42,
            userInfo: ["k": "v"]
        )
        let cfError = unsafeBitCast(cfSourceNSError, to: CFError.self)
        let cfErrorAsError: any Error = cfError
        precondition(cfErrorAsError._domain == "Portable.Domain")
        precondition(cfErrorAsError._code == 42)
        precondition(
            (cfErrorAsError._userInfo as? [String: Any])?["k"] as? String
                == "v"
        )
        precondition(cfErrorAsError._getEmbeddedNSError() === cfError)
        let cfBridgedNSError = cfErrorAsError as NSError
        precondition(cfBridgedNSError.domain == "Portable.Domain")
        precondition(cfBridgedNSError.code == 42)
        precondition(cfBridgedNSError.userInfo["k"] as? String == "v")

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(
            "This application has excellent dark mode support and useful settings"
        )
        precondition(recognizer.dominantLanguage == .english)
        precondition(
            (recognizer.languageHypotheses(withMaximum: 1)[.english] ?? 0)
                >= 0.85
        )
        precondition(!AuthenticationServicesPortable.isHostConfigured)
        let session: WebAuthenticationSession =
            EnvironmentValues().webAuthenticationSession
        withExtendedLifetime(session) {}

        proveAccelerate()
        try proveCompression()
        try proveCoreText()

        print(
            "TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK " +
            "descendants=\(descendants.count) text=rendered button=rendered " +
            "naturallanguage=en authenticationservices=fail-closed " +
            "accelerate=vimage compression=brotli coretext=font-registration"
        )
    }
}
