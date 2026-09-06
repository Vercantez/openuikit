import Foundation
import LightweightCodeRequirements

func testTeamIdentifierInit() {
    let identifier = TeamIdentifier("8XCUU22SN2")
    precondition(identifier.values == ["8XCUU22SN2"])
    let _: TeamIdentifier.OutType = identifier
    let _: TeamIdentifier.DataType = "8XCUU22SN2"
}

func testTeamIdentifierInVariadic() {
    let identifier = TeamIdentifier.in("AAAAA11111", "BBBBB22222")
    precondition(identifier.values == ["AAAAA11111", "BBBBB22222"])
}

func testTeamIdentifierInArray() {
    let identifier = TeamIdentifier.in(["CCCCC33333", "DDDDD44444"])
    precondition(identifier.values == ["CCCCC33333", "DDDDD44444"])
}

func testTeamIdentifierCodable() {
    let single = try! lcrRoundTrip(TeamIdentifier("8XCUU22SN2"))
    precondition(single.values == ["8XCUU22SN2"])
    let many = try! lcrRoundTrip(TeamIdentifier.in("A", "B"))
    precondition(many.values == ["A", "B"])
}

func testSigningIdentifierInit() {
    let identifier = SigningIdentifier("com.example.tool")
    precondition(identifier.values == ["com.example.tool"])
    let _: SigningIdentifier.OutType = identifier
    let _: SigningIdentifier.DataType = "com.example.tool"
}

func testSigningIdentifierInVariadic() {
    let identifier = SigningIdentifier.in("com.foo", "com.bar")
    precondition(identifier.values == ["com.foo", "com.bar"])
}

func testSigningIdentifierInArray() {
    let identifier = SigningIdentifier.in(["com.baz", "com.qux"])
    precondition(identifier.values == ["com.baz", "com.qux"])
}

func testSigningIdentifierCodable() {
    let decoded = try! lcrRoundTrip(SigningIdentifier.in("com.foo", "com.bar"))
    precondition(decoded.values == ["com.foo", "com.bar"])
}

func testCodeDirectoryHashInit() {
    let digest = Data([0x01, 0x02, 0x03, 0x04])
    let hash = CodeDirectoryHash(digest)
    precondition(hash.values == [digest])
    let _: CodeDirectoryHash.OutType = hash
    let _: CodeDirectoryHash.DataType = digest
}

func testCodeDirectoryHashInVariadic() {
    let a = Data([0x0A])
    let b = Data([0x0B])
    let hash = CodeDirectoryHash.in(a, b)
    precondition(hash.values == [a, b])
}

func testCodeDirectoryHashInArray() {
    let values = [Data([0x11]), Data([0x22])]
    let hash = CodeDirectoryHash.in(values)
    precondition(hash.values == values)
}

func testCodeDirectoryHashCodable() {
    let original = CodeDirectoryHash.in(Data([0xDE, 0xAD]), Data([0xBE, 0xEF]))
    let decoded = try! lcrRoundTrip(original)
    precondition(decoded.values == original.values)
}

func testInfoPlistHashInit() {
    let digest = Data([0xAA, 0xBB])
    let hash = InfoPlistHash(digest)
    precondition(hash.values == [digest])
    let _: InfoPlistHash.OutType = hash
    let _: InfoPlistHash.DataType = digest
}

func testInfoPlistHashInVariadic() {
    let hash = InfoPlistHash.in(Data([0x01]), Data([0x02]))
    precondition(hash.values.count == 2)
}

func testInfoPlistHashInArray() {
    let values = [Data([0x33]), Data([0x44])]
    precondition(InfoPlistHash.in(values).values == values)
}

func testInfoPlistHashCodable() {
    let original = InfoPlistHash(Data([0x99]))
    precondition(try! lcrRoundTrip(original).values == original.values)
}

func testIsMainBinary() {
    precondition(IsMainBinary().value)
    precondition(IsMainBinary(true).value)
    precondition(!IsMainBinary(false).value)
    let decoded = try! lcrRoundTrip(IsMainBinary(false))
    precondition(!decoded.value)
}

func testIsInitProcess() {
    precondition(IsInitProcess().value)
    precondition(IsInitProcess(true).value)
    precondition(!IsInitProcess(false).value)
    precondition(try! lcrRoundTrip(IsInitProcess(true)).value)
}

func testIsSIPProtected() {
    precondition(IsSIPProtected().value)
    precondition(IsSIPProtected(true).value)
    precondition(!IsSIPProtected(false).value)
    precondition(try! lcrRoundTrip(IsSIPProtected(false)).value == false)
}

func testTeamIdentifierMatchesCurrentProcess() {
    precondition(TeamIdentifierMatchesCurrentProcess().value)
    precondition(TeamIdentifierMatchesCurrentProcess(true).value)
    precondition(!TeamIdentifierMatchesCurrentProcess(false).value)
    precondition(try! lcrRoundTrip(TeamIdentifierMatchesCurrentProcess(true)).value)
}
