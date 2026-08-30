import Foundation

private func row(_ fields: Any...) {
    print(fields.map { String(describing: $0) }.joined(separator: "\t"))
}

private func scalarInventory(_ set: CharacterSet) -> String {
    var values: [String] = []
    for raw in UInt32(0)...UInt32(0x10_FFFF) {
        guard let scalar = Unicode.Scalar(raw), set.contains(scalar) else { continue }
        values.append(String(format: "%04X", raw))
    }
    return values.joined(separator: ",")
}

private func asciiInventory(_ set: CharacterSet) -> String {
    String((0x20...0x7E).compactMap { raw -> Character? in
        guard let scalar = Unicode.Scalar(raw), set.contains(scalar) else { return nil }
        return Character(scalar)
    })
}

private func rangeKey(_ range: Range<String.Index>?, in value: String) -> String {
    guard let range else { return "nil" }
    return "\(range.lowerBound.utf16Offset(in: value))-\(range.upperBound.utf16Offset(in: value))"
}

private func characterSetRows() {
    row("whitespaces", scalarInventory(.whitespaces))
    for (name, set) in [
        ("user", CharacterSet.urlUserAllowed),
        ("password", .urlPasswordAllowed),
        ("host", .urlHostAllowed),
        ("path", .urlPathAllowed),
        ("query", .urlQueryAllowed),
        ("fragment", .urlFragmentAllowed),
    ] {
        row("url-set", name, asciiInventory(set))
    }

    let mutable = NSMutableCharacterSet()
    mutable.formUnion(with: .urlQueryAllowed)
    mutable.formUnion(with: CharacterSet(charactersIn: "{}"))
    mutable.removeCharacters(in: "?&")
    let snapshot = mutable as CharacterSet
    row(
        "mutable",
        snapshot.contains("{".unicodeScalars.first!),
        snapshot.contains("?".unicodeScalars.first!),
        snapshot.contains("&".unicodeScalars.first!),
        snapshot.contains("A".unicodeScalars.first!)
    )
}

private func stringRows() {
    for value in ["Focus Linux", "café/東京", "100%", "a+b&c=d"] {
        row(
            "percent-query",
            value,
            value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "nil"
        )
    }
    for value in ["caf%C3%A9", "%E6%9D%B1%E4%BA%AC", "%", "%GG", "%C3%28"] {
        row("percent-remove", value, value.removingPercentEncoding ?? "nil")
    }

    let search = "www.Example.example"
    row("range", "literal", rangeKey(search.range(of: "Example"), in: search))
    row(
        "range", "case-insensitive",
        rangeKey(search.range(of: "example", options: .caseInsensitive), in: search)
    )
    row(
        "range", "backwards",
        rangeKey(search.range(of: "example", options: [.caseInsensitive, .backwards]), in: search)
    )
    row(
        "range", "anchored-front",
        rangeKey(search.range(of: "www", options: .anchored), in: search)
    )
    row(
        "range", "anchored-back",
        rangeKey(search.range(of: "example", options: [.anchored, .backwards]), in: search)
    )
    row(
        "range", "regex",
        rangeKey(search.range(of: "^(www|mobile|m)\\.", options: .regularExpression), in: search)
    )

    row("replace", "literal", "a+b+a".replacingOccurrences(of: "a", with: "X"))
    row(
        "replace", "suffix",
        "www.example.com".replacingOccurrences(
            of: ".com", with: "", options: [.literal, .backwards], range: nil
        )
    )
    row(
        "compare", "same",
        "Focus".compare("focus", options: .caseInsensitive).rawValue
    )
    row(
        "character-range", "forward",
        rangeKey("abc.def".rangeOfCharacter(from: CharacterSet(charactersIn: ".")), in: "abc.def")
    )
    row(
        "character-range", "backwards",
        rangeKey(
            "a.b.c".rangeOfCharacter(
                from: CharacterSet(charactersIn: "."), options: .backwards
            ),
            in: "a.b.c"
        )
    )

    row("format", "one", String(format: "%@ browser", "Focus"))
    row("format", "two", String(format: "%@ blocked %@", "Focus", "12"))
    row("format", "position", String(format: "%2$@/%1$@", "one", "two"))
    row("format", "percent", String(format: "100%% %@", "private"))
    row("format", "zero", String(format: "constant"))

    row("nsstring", NSString(string: "/tmp/focus/file.txt").lastPathComponent)
    row("nsstring-path", ("/tmp/focus" as NSString).appendingPathComponent("file.txt"))
}

characterSetRows()
stringRows()
