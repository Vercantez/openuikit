@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testClassifierIdentifierVersion1() {
    snExpect(
        SNClassifierIdentifier.version1.rawValue == "SNClassifierIdentifierVersion1",
        "version1 raw value is the exported C symbol name"
    )
    let copied = SNClassifierIdentifier(rawValue: "SNClassifierIdentifierVersion1")
    snExpect(copied == .version1, "init(rawValue:) round-trip")
    let unknown = SNClassifierIdentifier(rawValue: "version2")
    snExpect(unknown.rawValue == "version2", "unknown identifiers stay constructible")
}

func testClassifierIdentifierHashable() {
    let version1 = SNClassifierIdentifier.version1
    let same = SNClassifierIdentifier(rawValue: version1.rawValue)
    let other = SNClassifierIdentifier(rawValue: "other")
    snExpect(version1 == same, "equality")
    snExpect(version1 != other, "inequality")
    snExpect(version1.hashValue == same.hashValue, "hashValue")
    var hasher = Hasher()
    version1.hash(into: &hasher)
    _ = hasher.finalize()
}
