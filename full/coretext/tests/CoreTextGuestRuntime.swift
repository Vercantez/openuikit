import CoreText
import Foundation

@main
enum CoreTextGuestRuntime {
    static func register(_ url: URL) -> (Bool, NSError?) {
        var unmanaged: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(
            url as CFURL,
            .process,
            &unmanaged
        )
        let error = unmanaged?.takeRetainedValue() as Error? as NSError?
        return (success, error)
    }

    static func main() throws {
        precondition(CommandLine.arguments.count == 3)
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let root = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
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

        let initial = register(first)
        let repeated = register(first)
        let duplicate = register(second)
        let malformed = register(invalid)
        let absent = register(missing)
        precondition(initial.0 && initial.1 == nil)
        precondition(!repeated.0 && repeated.1?.code == CTFontManagerError.alreadyRegistered.rawValue)
        precondition(duplicate.0 && duplicate.1 == nil)
        precondition(!malformed.0 && malformed.1?.code == CTFontManagerError.unrecognizedFormat.rawValue)
        precondition(!absent.0 && absent.1?.code == CTFontManagerError.fileNotFound.rawValue)
        precondition(repeated.1?.domain == kCTFontManagerErrorDomain as String)
        print("CORETEXT_GUEST_OK font-register=process duplicate-url=apple-exact errors=domain,codes")
    }
}
