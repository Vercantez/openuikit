import Foundation
@_spi(OpenUIKitHost) import ThreadNetwork

private func thExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testTHCredentialsType() {
    let credentials = THCredentials.hostCredentials(networkName: "OpenThread-Net")
    thExpect(type(of: credentials) == THCredentials.self, "THCredentials metatype")
    let object: NSObject = credentials
    thExpect(object === credentials, "THCredentials is an NSObject")
    thExpect(THCredentials.supportsSecureCoding, "NSSecureCoding")
    let other = THCredentials.hostCredentials(networkName: "OpenThread-Net")
    thExpect(credentials != other, "NSObject identity equality, not value equality")
}

func testTHCredentialsNetworkName() {
    let named = THCredentials.hostCredentials(networkName: "HomeThread")
    thExpect(named.networkName == "HomeThread", "stored networkName")
    let empty = THCredentials.hostCredentials()
    thExpect(empty.networkName == nil, "nil networkName default")
}

func testTHCredentialsExtendedPANID() {
    let pan = Data([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88])
    let credentials = THCredentials.hostCredentials(extendedPANID: pan)
    thExpect(credentials.extendedPANID == pan, "stored 8-byte extended PAN ID")
    thExpect(THCredentials.hostCredentials().extendedPANID == nil, "nil default")
}

func testTHCredentialsBorderAgentID() {
    let agent = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    let credentials = THCredentials.hostCredentials(borderAgentID: agent)
    thExpect(credentials.borderAgentID == agent, "stored border agent ID")
    thExpect(THCredentials.hostCredentials().borderAgentID == nil, "nil default")
}

func testTHCredentialsActiveOperationalDataSet() {
    let dataset = Data([0x00, 0x03, 0x00, 0x00, 0x12])
    let credentials = THCredentials.hostCredentials(activeOperationalDataSet: dataset)
    thExpect(
        credentials.activeOperationalDataSet == dataset,
        "stored operational dataset bytes"
    )
    thExpect(
        THCredentials.hostCredentials().activeOperationalDataSet == nil,
        "nil default"
    )
}

func testTHCredentialsNetworkKey() {
    let key = Data(repeating: 0xAB, count: 16)
    let credentials = THCredentials.hostCredentials(networkKey: key)
    thExpect(credentials.networkKey == key, "stored 16-byte network key")
    thExpect(THCredentials.hostCredentials().networkKey == nil, "nil default")
}

func testTHCredentialsPSKC() {
    let pskc = Data(repeating: 0xCD, count: 16)
    let credentials = THCredentials.hostCredentials(pskc: pskc)
    thExpect(credentials.pskc == pskc, "stored PSKc")
    thExpect(THCredentials.hostCredentials().pskc == nil, "nil default")
}

func testTHCredentialsChannel() {
    let credentials = THCredentials.hostCredentials(channel: 15)
    thExpect(credentials.channel == 15, "initial channel")
    credentials.channel = 25
    thExpect(credentials.channel == 25, "channel setter stores UInt8")
    credentials.channel = 0
    thExpect(credentials.channel == 0, "channel 0 is stored, not rejected")
    credentials.channel = 255
    thExpect(credentials.channel == 255, "no invented 11...26 clamp")
}

func testTHCredentialsPANID() {
    let pan = Data([0xDE, 0xAD])
    let credentials = THCredentials.hostCredentials(panID: pan)
    thExpect(credentials.panID == pan, "stored 2-byte PAN ID")
    thExpect(THCredentials.hostCredentials().panID == nil, "nil default")
}

func testTHCredentialsCreationDate() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let credentials = THCredentials.hostCredentials(creationDate: date)
    thExpect(credentials.creationDate == date, "stored creationDate")
    thExpect(THCredentials.hostCredentials().creationDate == nil, "nil default")
}

func testTHCredentialsLastModificationDate() {
    let date = Date(timeIntervalSince1970: 1_700_000_100)
    let credentials = THCredentials.hostCredentials(lastModificationDate: date)
    thExpect(credentials.lastModificationDate == date, "stored lastModificationDate")
    let mutated = THCredentials.hostCredentials(
        channel: 11,
        lastModificationDate: date
    )
    mutated.channel = 20
    thExpect(
        mutated.lastModificationDate == date,
        "channel set does not invent a new modification date"
    )
}

func testTHCredentialsInitCoder() {
    let created = Date(timeIntervalSince1970: 100)
    let modified = Date(timeIntervalSince1970: 200)
    let original = THCredentials.hostCredentials(
        networkName: "RoundTrip",
        extendedPANID: Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]),
        borderAgentID: Data([0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8]),
        activeOperationalDataSet: Data([0x0E, 0x08, 0x00]),
        networkKey: Data(repeating: 0x11, count: 16),
        pskc: Data(repeating: 0x22, count: 16),
        channel: 20,
        panID: Data([0x12, 0x34]),
        creationDate: created,
        lastModificationDate: modified
    )
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(
            withRootObject: original,
            requiringSecureCoding: true
        )
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    let restored: THCredentials
    do {
        guard let value = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: THCredentials.self,
            from: data
        ) else {
            preconditionFailure("expected restored THCredentials")
        }
        restored = value
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
    thExpect(restored !== original, "unarchive produces a new instance")
    thExpect(restored.networkName == "RoundTrip", "networkName round-trip")
    thExpect(restored.extendedPANID == original.extendedPANID, "extendedPANID round-trip")
    thExpect(restored.borderAgentID == original.borderAgentID, "borderAgentID round-trip")
    thExpect(
        restored.activeOperationalDataSet == original.activeOperationalDataSet,
        "activeOperationalDataSet round-trip"
    )
    thExpect(restored.networkKey == original.networkKey, "networkKey round-trip")
    thExpect(restored.pskc == original.pskc, "pskc round-trip")
    thExpect(restored.channel == 20, "channel round-trip")
    thExpect(restored.panID == original.panID, "panID round-trip")
    thExpect(restored.creationDate == created, "creationDate round-trip")
    thExpect(restored.lastModificationDate == modified, "lastModificationDate round-trip")

    let blank = THCredentials.hostCredentials()
    let blankData: Data
    do {
        blankData = try NSKeyedArchiver.archivedData(
            withRootObject: blank,
            requiringSecureCoding: true
        )
    } catch {
        preconditionFailure("empty archive failed: \(error)")
    }
    let blankRestored: THCredentials
    do {
        guard let value = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: THCredentials.self,
            from: blankData
        ) else {
            preconditionFailure("expected restored empty THCredentials")
        }
        blankRestored = value
    } catch {
        preconditionFailure("empty unarchive failed: \(error)")
    }
    thExpect(blankRestored.networkName == nil, "nil fields round-trip")
    thExpect(blankRestored.channel == 0, "default channel 0 round-trips")
}
