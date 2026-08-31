import Foundation

private func scalarKey(_ string: String) -> String {
    if string.isEmpty { return "EMPTY" }
    return string.unicodeScalars.map { scalar in
        var digits = String(scalar.value, radix: 16, uppercase: true)
        while digits.count < 4 { digits = "0" + digits }
        return "U+" + digits
    }.joined(separator: ",")
}

private func row(_ fields: Any...) {
    print(fields.map { String(describing: $0) }.joined(separator: "\t"))
}

private func characterSetRows() {
    var inventory: [String] = []
    for raw in UInt32(0)...UInt32(0x10_FFFF) {
        guard let scalar = Unicode.Scalar(raw) else { continue }
        if CharacterSet.whitespacesAndNewlines.contains(scalar) {
            inventory.append(scalarKey(String(scalar)))
        }
    }
    row("characters", inventory.count, inventory.joined(separator: ","))

    let custom = CharacterSet(charactersIn: "xe\u{301}")
    for scalar in "xyé\u{301}".unicodeScalars {
        row("contains", scalarKey(String(scalar)), custom.contains(scalar))
    }
    let supplementary = "💥".unicodeScalars.first!
    row(
        "contains-supplementary",
        scalarKey(String(supplementary)),
        CharacterSet(charactersIn: "💥").contains(supplementary)
    )
}

private func trimmingRows() {
    let whitespaceCases = [
        "",
        "plain",
        " \talpha\n",
        "\u{00A0}\u{200B}alpha\u{2028}\u{2029}",
        "\u{200B}",
        "a b",
        "\u{0085}\u{1680}\u{202F}\u{205F}\u{3000}",
    ]
    for input in whitespaceCases {
        row(
            "trim-ws",
            scalarKey(input),
            scalarKey(input.trimmingCharacters(in: .whitespacesAndNewlines))
        )
    }

    let custom = CharacterSet(charactersIn: "xy\u{301}")
    for input in ["xyhelloyx", "\u{301}e\u{301}", "xxx", "hello"] {
        row(
            "trim-custom",
            scalarKey(input),
            scalarKey(input.trimmingCharacters(in: custom))
        )
    }
}

private func componentsRows() {
    let cases: [(String, String)] = [
        ("", ""),
        ("", " "),
        ("plain", ""),
        ("plain", " "),
        (" alpha ", " "),
        ("a  b", " "),
        ("a\t b", " \t"),
        ("e\u{301}x\u{301}", "\u{301}"),
        ("a💥b💥", "💥"),
        ("\r\n", "\r\n"),
    ]
    for (input, separators) in cases {
        let components = input.components(
            separatedBy: CharacterSet(charactersIn: separators)
        )
        row(
            "components-set",
            scalarKey(input),
            scalarKey(separators),
            components.count,
            components.map(scalarKey).joined(separator: "|")
        )
    }
}

private func scannerRow(_ input: String, skip: CharacterSet? = .whitespacesAndNewlines) {
    let scanner = Scanner(string: input)
    scanner.charactersToBeSkipped = skip
    var value: UInt64 = 777
    let scanned = scanner.scanHexInt64(&value)
    row(
        "hex",
        scalarKey(input),
        scanned,
        value,
        scanner.currentIndex.utf16Offset(in: scanner.string),
        scanner.isAtEnd
    )
}

private func scannerRows() {
    for input in [
        "", " ", "ABCDEF", "abcdef", "  ABC", "0x10", "0X10",
        "+10", "-10", "G10", "1G", "FFFFFFFFFFFFFFFF",
        "10000000000000000", "FFFFFFFFFFFFFFFFF",
        "000000000000000000001", "0x", "0xG", "0x1G", "00x10",
        "_1", "1_2", "\t\nFF", "１２",
    ] {
        scannerRow(input)
    }
    scannerRow("  FF", skip: nil)
    scannerRow("xxFF", skip: CharacterSet(charactersIn: "x"))

    let scanner = Scanner(string: "FF")
    let scanned = scanner.scanHexInt64(nil)
    row(
        "hex-nil-result",
        scanned,
        scanner.currentIndex.utf16Offset(in: scanner.string),
        scanner.isAtEnd
    )

    for input in ["", " ", "  G", "  F", "F "] {
        let endScanner = Scanner(string: input)
        row("at-end", scalarKey(input), endScanner.isAtEnd)
    }
}

private struct DescriptionError: LocalizedError {
    var errorDescription: String? { "description" }
}

private struct ReasonError: LocalizedError {
    var failureReason: String? { "because" }
}

private struct EmptyDescriptionError: LocalizedError {
    var errorDescription: String? { "" }
}

private func errorRows() {
    let values: [(String, any Error)] = [
        ("description", DescriptionError()),
        ("reason", ReasonError()),
        ("empty", EmptyDescriptionError()),
    ]
    for (name, error) in values {
        row("error", name, scalarKey(error.localizedDescription))
    }
}

characterSetRows()
trimmingRows()
componentsRows()
scannerRows()
errorRows()
