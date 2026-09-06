import Foundation
import Network

private func txtExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNWTXTRecordRFC6763RoundTrip() {
    let record = NWTXTRecord(["txtvers": "1", "path": "/"])
    txtExpect(record.dictionary["txtvers"] == "1", "dictionary txtvers")
    txtExpect(record.dictionary["path"] == "/", "dictionary path")
    let wire = record.data
    // RFC 6763: length-prefixed "path=/" and "txtvers=1" (sorted keys from init)
    txtExpect(!wire.isEmpty, "nonempty wire")
    txtExpect(wire.first != 0, "no empty first string")
    let decoded = NWTXTRecord(wire)
    txtExpect(decoded["txtvers"] == "1", "decode txtvers")
    txtExpect(decoded["path"] == "/", "decode path")
    txtExpect(decoded.data == wire, "encode decode identity")
}

func testNWTXTRecordRFC6763EmptyAndBinary() {
    var record = NWTXTRecord()
    txtExpect(record.setEntry(.empty, for: "flag"), "empty set")
    txtExpect(record.setEntry(.string("A4"), for: "paper"), "string set")
    txtExpect(record.setEntry(.data(Data([0xff, 0x00])), for: "bin"), "binary set")
    txtExpect(record.setEntry(.none, for: "") == false, "empty key rejected")
    let encoded = record.data
    let decoded = NWTXTRecord(encoded)
    if case .empty = decoded.getEntry(for: "flag")! {
        // RFC 6763 boolean true: key with no "="
    } else {
        preconditionFailure("flag should be empty")
    }
    txtExpect(decoded["paper"] == "A4", "paper")
    if case .data(let value) = decoded.getEntry(for: "bin")! {
        txtExpect(value == Data([0xff, 0x00]), "binary payload")
    } else {
        preconditionFailure("bin should be data")
    }
    txtExpect(decoded.getEntry(for: "missing") == nil, "missing")
}

func testNWTXTRecordRemoveAndEntryNone() {
    var record = NWTXTRecord(["a": "1", "b": "2"])
    txtExpect(record.removeEntry(key: "a"), "removed a")
    txtExpect(record["a"] == nil, "a gone")
    txtExpect(record.removeEntry(key: "a") == false, "second remove false")
    record["b"] = nil
    txtExpect(record.dictionary.isEmpty, "cleared")
    let none = NWTXTRecord.Entry(nil)
    if case .none = none {
        txtExpect(none.data == nil, "none data")
    } else {
        preconditionFailure("nil Data? is none")
    }
    let empty = NWTXTRecord.Entry(Data())
    if case .empty = empty {
        txtExpect(empty.data == Data(), "empty data")
    } else {
        preconditionFailure("empty Data is empty")
    }
    let fromBytes = NWTXTRecord.Entry(Data([1, 2, 3]))
    txtExpect(fromBytes.data == Data([1, 2, 3]), "bytes")
    txtExpect(NWTXTRecord.Entry.none != .empty, "none vs empty")
    txtExpect(NWTXTRecord.Entry.empty.debugDescription == "empty", "debug empty")
    txtExpect(NWTXTRecord.Entry.string("x").debugDescription.contains("x"), "debug string")
    _ = NWTXTRecord.Entry.data(Data([1])).hashValue
    txtExpect(record.setEntry(.string("ok"), for: "k"), "set after clear")
}

func testNWTXTRecordKnownVector() {
    // "path=/" is 6 octets; RFC 6763 length prefix 0x06.
    let pathEquals = Array("path=/".utf8)
    var wire = Data([UInt8(pathEquals.count)])
    wire.append(contentsOf: pathEquals)
    let record = NWTXTRecord(wire)
    txtExpect(record["path"] == "/", "known vector")
    txtExpect(record.data == wire, "re-encode")
    // Boolean key "flag" with no value.
    let flag = Array("flag".utf8)
    var boolean = Data([UInt8(flag.count)])
    boolean.append(contentsOf: flag)
    let flagRecord = NWTXTRecord(boolean)
    if case .empty = flagRecord.getEntry(for: "flag")! {
        txtExpect(flagRecord["flag"] == "", "empty string get")
    } else {
        preconditionFailure("boolean key")
    }
}
