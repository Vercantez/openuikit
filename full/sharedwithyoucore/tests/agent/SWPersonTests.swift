@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

private func swcArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

private func swcRejectsEmptyCoder<T: NSObject & NSSecureCoding>(_ type: T.Type) {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "swc-malformed",
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(type.init(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }
}

func testSWPersonClass() {
    let person = SWPerson(
        handle: "ada@example.invalid",
        identity: nil,
        displayName: "Ada",
        thumbnailImageData: nil
    )
    swcRequireType(person, as: SWPerson.self)
}

func testSWPersonInitHandleIdentityDisplayNameThumbnail() {
    let hash = Data([0x11, 0x22])
    let identity = SWPerson.Identity(rootHash: hash)
    let thumbnail = Data([0x33])
    let person = SWPerson(
        handle: "ada@example.invalid",
        identity: identity,
        displayName: "Ada Lovelace",
        thumbnailImageData: thumbnail
    )
    precondition(SharedWithYouCoreHostControl.personHandle(person) == "ada@example.invalid")
    precondition(SharedWithYouCoreHostControl.personIdentity(person)?.rootHash == hash)
    precondition(SharedWithYouCoreHostControl.personDisplayName(person) == "Ada Lovelace")
    precondition(SharedWithYouCoreHostControl.personThumbnailImageData(person) == thumbnail)
}

func testSWPersonInitCoder() {
    let identity = SWPerson.Identity(rootHash: Data([0x01]))
    let person = SWPerson(
        handle: "ada@example.invalid",
        identity: identity,
        displayName: "Ada",
        thumbnailImageData: Data([0x02])
    )
    let restored = swcArchiveRoundTrip(person)
    precondition(SharedWithYouCoreHostControl.personHandle(restored) == "ada@example.invalid")
    precondition(SharedWithYouCoreHostControl.personIdentity(restored)?.rootHash == Data([0x01]))
    precondition(SharedWithYouCoreHostControl.personDisplayName(restored) == "Ada")
    precondition(SharedWithYouCoreHostControl.personThumbnailImageData(restored) == Data([0x02]))
    swcRejectsEmptyCoder(SWPerson.self)
}

func testSWPersonIdentityClass() {
    let identity = SWPerson.Identity(rootHash: Data([0x01, 0x02]))
    swcRequireType(identity, as: SWPerson.Identity.self)
}

func testSWPersonIdentityInitRootHash() {
    let hash = Data([0xaa, 0xbb, 0xcc])
    let identity = SWPerson.Identity(rootHash: hash)
    precondition(identity.rootHash == hash)
}

func testSWPersonIdentityRootHash() {
    let identity = SWPerson.Identity(rootHash: Data([0xde, 0xad]))
    precondition(identity.rootHash == Data([0xde, 0xad]))
    precondition(identity.rootHash != Data([0x00]))
}

func testSWPersonIdentityInitCoder() {
    let identity = SWPerson.Identity(rootHash: Data([0x10, 0x20]))
    let restored = swcArchiveRoundTrip(identity)
    precondition(restored.rootHash == Data([0x10, 0x20]))
    swcRejectsEmptyCoder(SWPerson.Identity.self)
}

func testSWPersonIdentityProofClass() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(
        inclusionHashes: [Data([0x01])],
        publicKey: Data([0x02]),
        publicKeyIndex: 3
    )
    swcRequireType(proof, as: SWPerson.IdentityProof.self)
}

func testSWPersonIdentityProofInclusionHashes() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(
        inclusionHashes: [Data([0x01]), Data([0x02])]
    )
    precondition(proof.inclusionHashes == [Data([0x01]), Data([0x02])])
}

func testSWPersonIdentityProofPublicKey() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(publicKey: Data([0x99]))
    precondition(proof.publicKey == Data([0x99]))
}

func testSWPersonIdentityProofPublicKeyIndex() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(publicKeyIndex: 7)
    precondition(proof.publicKeyIndex == 7)
}

func testSWPersonIdentityProofInitCoder() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(
        inclusionHashes: [Data([0x01])],
        publicKey: Data([0x02]),
        publicKeyIndex: 4
    )
    let restored = swcArchiveRoundTrip(proof)
    precondition(restored.inclusionHashes == [Data([0x01])])
    precondition(restored.publicKey == Data([0x02]))
    precondition(restored.publicKeyIndex == 4)
    swcRejectsEmptyCoder(SWPerson.IdentityProof.self)
}

func testSWPersonSignedIdentityProofClass() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(publicKey: Data([0x01]))
    let signed = SWPerson.SignedIdentityProof(
        personIdentityProof: proof,
        signatureData: Data([0xab])
    )
    swcRequireType(signed, as: SWPerson.SignedIdentityProof.self)
    swcRequireType(signed, as: SWPerson.IdentityProof.self)
}

func testSWPersonSignedIdentityProofInit() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof(
        inclusionHashes: [Data([0x01])],
        publicKey: Data([0x02]),
        publicKeyIndex: 5
    )
    let signed = SWPerson.SignedIdentityProof(
        personIdentityProof: proof,
        signatureData: Data([0xab, 0xcd])
    )
    precondition(signed.inclusionHashes == [Data([0x01])])
    precondition(signed.publicKey == Data([0x02]))
    precondition(signed.publicKeyIndex == 5)
    precondition(signed.signatureData == Data([0xab, 0xcd]))
}

func testSWPersonSignedIdentityProofSignatureData() {
    let proof = SharedWithYouCoreHostControl.makeIdentityProof()
    let signed = SWPerson.SignedIdentityProof(
        personIdentityProof: proof,
        signatureData: Data([0xfe, 0xed])
    )
    precondition(signed.signatureData == Data([0xfe, 0xed]))
}
