import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKBERTLVRecordRoundTrip() {
    let value = Data([0xAA, 0xBB])
    let record = TKBERTLVRecord(tag: 0x5A, value: value)
    tkMust(record.tag == 0x5A, "tag")
    tkMust(record.value == value, "value")
    tkMust(record.data == Data([0x5A, 0x02, 0xAA, 0xBB]), "data")
    guard let parsed = TKTLVRecord(from: record.data) else {
        preconditionFailure("parse")
    }
    tkMust(parsed.tag == 0x5A, "parsed tag")
    tkMust(parsed.value == value, "parsed value")
}

func testTKBERTLVRecordFromData() {
    let encoded = Data([0x01, 0x01, 0xFF])
    guard let parsed = TKTLVRecord(fromData: encoded) else {
        preconditionFailure("fromData")
    }
    tkMust(parsed.tag == 0x01, "tag")
    tkMust(parsed.value == Data([0xFF]), "value")
}

func testTKBERTLVRecordDataForTag() {
    tkMust(TKBERTLVRecord.data(forTag: 0x01) == Data([0x01]), "short")
    tkMust(TKBERTLVRecord.data(forTag: 0x7F21) == Data([0x7F, 0x21]), "long")
    tkMust(TKBERTLVRecord.data(forTag: 0) == Data([0]), "zero")
}

func testTKBERTLVRecordNestedRecords() {
    let inner = TKBERTLVRecord(tag: 0x01, value: Data([0x11]))
    let outer = TKBERTLVRecord(tag: 0x30, records: [inner])
    tkMust(outer.tag == 0x30, "outer tag")
    tkMust(outer.value == inner.data, "nested value")
    guard let sequence = TKTLVRecord.sequenceOfRecords(from: outer.value) else {
        preconditionFailure("sequence")
    }
    tkMust(sequence.count == 1, "count")
    tkMust(sequence[0].tag == 0x01, "inner tag")
}

func testTKTLVRecordSequence() {
    let first = TKBERTLVRecord(tag: 0x01, value: Data([0xAA]))
    let second = TKBERTLVRecord(tag: 0x02, value: Data([0xBB, 0xCC]))
    var blob = Data()
    blob.append(first.data)
    blob.append(second.data)
    guard let sequence = TKTLVRecord.sequenceOfRecords(from: blob) else {
        preconditionFailure("sequence")
    }
    tkMust(sequence.count == 2, "count")
    tkMust(sequence[0].tag == 0x01 && sequence[0].value == Data([0xAA]), "first")
    tkMust(sequence[1].tag == 0x02 && sequence[1].value == Data([0xBB, 0xCC]), "second")
    let empty = TKTLVRecord.sequenceOfRecords(from: Data())
    tkMust(empty?.isEmpty == true, "empty")
    tkMust(TKTLVRecord.sequenceOfRecords(from: Data([0x01, 0x02])) == nil, "truncated")
}

func testTKCompactTLVRecord() {
    let record = TKCompactTLVRecord(tag: 0x05, value: Data([0x11, 0x22]))
    tkMust(record.tag == 0x05, "tag")
    tkMust(record.value == Data([0x11, 0x22]), "value")
    tkMust(record.data == Data([0x52, 0x11, 0x22]), "data header 5|2")
}

func testTKSimpleTLVRecord() {
    let record = TKSimpleTLVRecord(tag: 0x81, value: Data([0x01, 0x02, 0x03]))
    tkMust(record.tag == 0x81, "tag")
    tkMust(record.value == Data([0x01, 0x02, 0x03]), "value")
    tkMust(record.data == Data([0x81, 0x03, 0x01, 0x02, 0x03]), "simple encoding")
}

func testTKTLVRecordRejectsInvalidBER() {
    tkMust(TKTLVRecord(from: Data()) == nil, "empty")
    tkMust(TKTLVRecord(from: Data([0x01])) == nil, "tag only")
    tkMust(TKTLVRecord(from: Data([0x01, 0x81])) == nil, "truncated long length")
}
