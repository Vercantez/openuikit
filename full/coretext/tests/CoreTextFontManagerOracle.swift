import CoreText
import Foundation

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: CoreTextFontManagerOracle FONT TEMP_DIRECTORY")
}

let source = URL(fileURLWithPath: CommandLine.arguments[1])
let root = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let fileManager = FileManager.default
try? fileManager.removeItem(at: root)
try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? fileManager.removeItem(at: root) }

let first = root.appendingPathComponent("first.ttf")
let second = root.appendingPathComponent("second.ttf")
let invalid = root.appendingPathComponent("invalid.ttf")
let missing = root.appendingPathComponent("missing.ttf")
try fileManager.copyItem(at: source, to: first)
try fileManager.copyItem(at: source, to: second)
try Data("not a font".utf8).write(to: invalid)

func register(_ url: URL) -> (Bool, NSError?) {
    var unmanaged: Unmanaged<CFError>?
    let success = CTFontManagerRegisterFontsForURL(
        url as CFURL,
        .process,
        &unmanaged
    )
    let error = unmanaged?.takeRetainedValue() as Error? as NSError?
    return (success, error)
}

func printResult(_ label: String, _ result: (Bool, NSError?)) {
    if let error = result.1 {
        print("\(label)=\(result.0),domain:\(error.domain),code:\(error.code)")
    } else {
        print("\(label)=\(result.0),domain:nil,code:nil")
    }
}

print("domain=\(kCTFontManagerErrorDomain)")
print("codes=already:\(CTFontManagerError.alreadyRegistered.rawValue),duplicate:\(CTFontManagerError.duplicatedName.rawValue)")
printResult("first", register(first))
printResult("repeat", register(first))
printResult("duplicate", register(second))
printResult("invalid", register(invalid))
printResult("missing", register(missing))
