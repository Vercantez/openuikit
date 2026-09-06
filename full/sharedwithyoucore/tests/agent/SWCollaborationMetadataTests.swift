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

func testSWCollaborationMetadataClass() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("meta.class")
    )
    swcRequireType(metadata, as: SWCollaborationMetadata.self)
}

func testSWCollaborationMetadataInitCollaborationIdentifier() {
    let identifier = SWCollaborationIdentifier("cloud.collab")
    let metadata = SWCollaborationMetadata(collaborationIdentifier: identifier)
    precondition(metadata.collaborationIdentifier == identifier)
    precondition(metadata.localIdentifier.rawValue.isEmpty)
}

func testSWCollaborationMetadataInitLocalIdentifier() {
    let identifier = SWLocalCollaborationIdentifier("local.meta")
    let metadata = SWCollaborationMetadata(localIdentifier: identifier)
    precondition(metadata.localIdentifier == identifier)
    precondition(metadata.collaborationIdentifier.rawValue.isEmpty)
}

func testSWCollaborationMetadataCollaborationIdentifier() {
    let identifier = SWCollaborationIdentifier("read.collab")
    let metadata = SWCollaborationMetadata(collaborationIdentifier: identifier)
    precondition(metadata.collaborationIdentifier.rawValue == "read.collab")
}

func testSWCollaborationMetadataLocalIdentifier() {
    let identifier = SWLocalCollaborationIdentifier("read.local")
    let metadata = SWCollaborationMetadata(localIdentifier: identifier)
    precondition(metadata.localIdentifier.rawValue == "read.local")
}

func testSWCollaborationMetadataTitle() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("title.meta")
    )
    precondition(metadata.title == nil)
    metadata.title = "Design Doc"
    precondition(metadata.title == "Design Doc")
    metadata.title = nil
    precondition(metadata.title == nil)
}

func testSWCollaborationMetadataInitiatorHandle() {
    let metadata = SWCollaborationMetadata(
        localIdentifier: SWLocalCollaborationIdentifier("handle.meta")
    )
    precondition(metadata.initiatorHandle == nil)
    metadata.initiatorHandle = "ada@example.invalid"
    precondition(metadata.initiatorHandle == "ada@example.invalid")
}

func testSWCollaborationMetadataInitiatorNameComponents() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("name.meta")
    )
    precondition(metadata.initiatorNameComponents == nil)
    var components = PersonNameComponents()
    components.givenName = "Ada"
    components.familyName = "Lovelace"
    metadata.initiatorNameComponents = components
    precondition(metadata.initiatorNameComponents?.givenName == "Ada")
    precondition(metadata.initiatorNameComponents?.familyName == "Lovelace")
}

func testSWCollaborationMetadataDefaultShareOptions() {
    let option = SWCollaborationOption(title: "Anyone", identifier: "anyone")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [group], summary: "Anyone can edit")
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("default.share")
    )
    precondition(metadata.defaultShareOptions == nil)
    metadata.defaultShareOptions = share
    precondition(metadata.defaultShareOptions?.summary == "Anyone can edit")
    metadata.defaultShareOptions?.summary = "mutated original copy"
    precondition(share.summary == "Anyone can edit")
}

func testSWCollaborationMetadataUserSelectedShareOptions() {
    let option = SWCollaborationOption(title: "Invite only", identifier: "invite")
    let group = SWCollaborationOptionsGroup(identifier: "perm", options: [option])
    let share = SWCollaborationShareOptions(optionsGroups: [group], summary: "Invite")
    let metadata = SWCollaborationMetadata(
        localIdentifier: SWLocalCollaborationIdentifier("user.share")
    )
    precondition(metadata.userSelectedShareOptions == nil)
    metadata.userSelectedShareOptions = share
    precondition(metadata.userSelectedShareOptions?.summary == "Invite")
}

func testSWCollaborationMetadataInitCoder() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("coded.collab")
    )
    metadata.title = "Archived"
    metadata.initiatorHandle = "ada@example.invalid"
    var components = PersonNameComponents()
    components.givenName = "Ada"
    metadata.initiatorNameComponents = components
    let restored = swcArchiveRoundTrip(metadata)
    precondition(restored.collaborationIdentifier.rawValue == "coded.collab")
    precondition(restored.title == "Archived")
    precondition(restored.initiatorHandle == "ada@example.invalid")
    precondition(restored.initiatorNameComponents?.givenName == "Ada")
    swcRejectsEmptyCoder(SWCollaborationMetadata.self)
}
