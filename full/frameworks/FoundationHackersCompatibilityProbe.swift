// This file intentionally imports only Foundation. It is compiled into the
// core-package runtime probe so these references prove Foundation's transitive
// CGFloat/os visibility independently of UIKit and the other probe imports.
import Foundation

@inline(never)
func runFoundationHackersCompatibilityProbe(resourceRoot: String) -> String {
    let scalar: CGFloat = 1.25
    precondition(scalar + 0.75 == 2)
    precondition(Int(ceil(CGFloat(11) / 10)) == 2)

    var unfairLock = os_unfair_lock()
    precondition(os_unfair_lock_trylock(&unfairLock))
    os_unfair_lock_unlock(&unfairLock)

    let lock = NSLock()
    lock.name = "core-foundation-probe"
    precondition(lock.name == "core-foundation-probe")
    precondition(lock.try())
    lock.unlock()
    precondition(lock.withLock { 40 + 2 } == 42)

    let uppercase = CharacterSet.uppercaseLetters
    let lowercase = CharacterSet.lowercaseLetters
    let letters = CharacterSet.letters
    let alphanumerics = CharacterSet.alphanumerics
    let symbols = CharacterSet.symbols
    let decimalDigits = CharacterSet.decimalDigits
    precondition(uppercase.contains("A".unicodeScalars.first!))
    precondition(uppercase.contains("ǅ".unicodeScalars.first!))
    precondition(!uppercase.contains("z".unicodeScalars.first!))
    precondition(lowercase.contains("z".unicodeScalars.first!))
    precondition(!lowercase.contains("A".unicodeScalars.first!))
    precondition(letters.contains("é".unicodeScalars.first!))
    precondition(letters.contains("\u{0301}".unicodeScalars.first!))
    precondition(!letters.contains("3".unicodeScalars.first!))
    precondition(alphanumerics.contains("Ⅷ".unicodeScalars.first!))
    precondition(alphanumerics.contains("²".unicodeScalars.first!))
    precondition(symbols.contains("€".unicodeScalars.first!))
    precondition(decimalDigits.contains("٣".unicodeScalars.first!))
    precondition(!decimalDigits.contains("²".unicodeScalars.first!))

    let normalized = "e\u{0301}".precomposedStringWithCanonicalMapping
    precondition(normalized.unicodeScalars.map { $0.value } == [0xE9])
    precondition("FOCUS".caseInsensitiveCompare("focus") == .orderedSame)
    let replacementSource = "abc"
    let replacementStart = replacementSource.index(after: replacementSource.startIndex)
    let replacementEnd = replacementSource.index(after: replacementStart)
    precondition(
        replacementSource.replacingCharacters(
            in: replacementStart..<replacementEnd,
            with: "Z"
        ) == "aZc"
    )
    precondition(
        "é".cString(using: .utf8)?.map { UInt8(bitPattern: $0) }
            == [0xC3, 0xA9, 0]
    )
    precondition("é".cString(using: .ascii) == nil)
    precondition(NSRange(2..<7) == NSRange(location: 2, length: 5))
    let firstRange = NSRange(location: 2, length: 5)
    let secondRange = NSRange(location: 5, length: 4)
    precondition(NSMaxRange(firstRange) == 7)
    precondition(NSLocationInRange(6, firstRange))
    precondition(!NSLocationInRange(7, firstRange))
    precondition(NSEqualRanges(firstRange, NSRange(location: 2, length: 5)))
    precondition(NSUnionRange(firstRange, secondRange) == NSRange(location: 2, length: 7))
    precondition(
        NSIntersectionRange(firstRange, secondRange) == NSRange(location: 5, length: 2)
    )
    precondition(
        NSIntersectionRange(firstRange, NSRange(location: 7, length: 1))
            == NSRange(location: 0, length: 0)
    )
    var attributed = AttributedString("portable")
    attributed.inlinePresentationIntent = [.emphasized, .code]
    precondition(attributed.inlinePresentationIntent == [.emphasized, .code])
    precondition(InlinePresentationIntent.stronglyEmphasized.rawValue == 2)
    precondition(
        AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.name
            == "NSInlinePresentationIntent"
    )
    precondition("  x  "[...].trimmingCharacters(in: .whitespaces) == "x")

    let colorsPath = resourceRoot + "/system_colors.json"
    guard let handle = FileHandle(forReadingAtPath: colorsPath) else {
        preconditionFailure("Foundation.FileHandle could not open packaged colors")
    }
    precondition(handle.readData(ofLength: 1) == Data([0x7B]))
    precondition(handle.offsetInFile == 1)
    try! handle.seek(toOffset: 0)
    precondition(try! handle.read(upToCount: 1) == Data([0x7B]))
    try! handle.seek(toOffset: 0)
    let modernColors = try! handle.readToEnd()
    precondition((modernColors?.count ?? 0) > 100)
    try! handle.seek(toOffset: 0)
    let colors = handle.readDataToEndOfFile()
    precondition(colors.count > 100)
    precondition(handle.offsetInFile == UInt64(colors.count))
    try! handle.close()
    precondition(handle.fileDescriptor == -1)

    let bytes = Data([1, 2, 3, 2, 3])
    let needle = Data([2, 3])
    precondition(bytes.range(of: needle) == 1..<3)
    precondition(bytes.range(of: needle, options: .backwards) == 3..<5)
    precondition(bytes.range(of: needle, options: .anchored) == nil)
    precondition(bytes.range(of: needle, in: 2..<5) == 3..<5)
    precondition(bytes.range(of: Data()) == nil)

    let cfURL = CFURLCreateWithString(
        nil,
        "https://example.invalid/?q=abc%20def[" as CFString,
        nil
    ) as URL?
    precondition(
        cfURL?.absoluteString ==
            "https://example.invalid/?q=abc%20def%5B"
    )
    let rejectedCFURL = CFURLCreateWithString(
        nil,
        "https://example.invalid/a b" as CFString,
        nil
    ) as URL?
    precondition(rejectedCFURL == nil)

    return "locks,filehandle,characters,strings,ranges,attributed,data-search,cfurl,reexports"
}
