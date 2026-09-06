@_spi(OpenUIKitHost) import SensitiveContentAnalysis

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testStreamDirectionRawValues() {
    let rows: [(SCVideoStreamAnalyzer.StreamDirection, Int)] = [
        (.outgoing, 1),
        (.incoming, 2),
    ]
    scExpect(rows.count == 2, "stream direction has two documented cases")
    for (direction, raw) in rows {
        scExpect(direction.rawValue == raw, "raw value \(raw)")
        scExpect(
            SCVideoStreamAnalyzer.StreamDirection(rawValue: raw) == direction,
            "init(rawValue:) \(raw)"
        )
    }
    scExpect(SCVideoStreamAnalyzer.StreamDirection(rawValue: 0) == nil, "raw 0 is nil")
    scExpect(SCVideoStreamAnalyzer.StreamDirection(rawValue: 3) == nil, "raw 3 is nil")
}

func testStreamDirectionInequality() {
    scExpect(
        SCVideoStreamAnalyzer.StreamDirection.incoming != .outgoing,
        "incoming != outgoing"
    )
    scExpect(
        !(SCVideoStreamAnalyzer.StreamDirection.incoming != .incoming),
        "incoming == incoming"
    )
}

func testStreamDirectionHashValue() {
    scExpect(
        SCVideoStreamAnalyzer.StreamDirection.incoming.hashValue
            == SCVideoStreamAnalyzer.StreamDirection.incoming.hashValue,
        "same case hashes equal"
    )
    scExpect(
        SCVideoStreamAnalyzer.StreamDirection.incoming.hashValue
            != SCVideoStreamAnalyzer.StreamDirection.outgoing.hashValue,
        "distinct cases hash distinctly"
    )
}

func testStreamDirectionHashInto() {
    var hasher = Hasher()
    SCVideoStreamAnalyzer.StreamDirection.outgoing.hash(into: &hasher)
    _ = hasher.finalize()
    var left = Hasher()
    var right = Hasher()
    SCVideoStreamAnalyzer.StreamDirection.incoming.hash(into: &left)
    SCVideoStreamAnalyzer.StreamDirection.incoming.hash(into: &right)
    scExpect(left.finalize() == right.finalize(), "hash(into:) is stable for the same case")
}
