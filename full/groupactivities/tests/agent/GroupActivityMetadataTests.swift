@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testActivityTypeCatalog() {
    let types: [GroupActivityMetadata.ActivityType] = [
        .generic,
        .listenTogether,
        .watchTogether,
        .readTogether,
        .shopTogether,
        .learnTogether,
        .createTogether,
        .exploreTogether,
        .workoutTogether,
    ]
    gaRequire(Set(types).count == 9, "nine distinct types")
    gaRequire(GroupActivityMetadata.ActivityType.generic == .generic, "generic ==")
    gaRequire(
        GroupActivityMetadata.ActivityType.watchTogether != .listenTogether,
        "type !="
    )
    var hasher = Hasher()
    GroupActivityMetadata.ActivityType.generic.hash(into: &hasher)
    gaRequire(
        GroupActivityMetadata.ActivityType.generic.hashValue
            == GroupActivityMetadata.ActivityType.generic.hashValue,
        "hashValue"
    )
}

func testLifetimePolicyValues() {
    gaRequire(
        GroupActivityMetadata.LifetimePolicy.automatic == .automatic,
        "automatic"
    )
    gaRequire(
        GroupActivityMetadata.LifetimePolicy.endsWhenInitiatorLeaves
            == .endsWhenInitiatorLeaves,
        "endsWhenInitiatorLeaves"
    )
    gaRequire(
        GroupActivityMetadata.LifetimePolicy.automatic != .endsWhenInitiatorLeaves,
        "policy !="
    )
    var hasher = Hasher()
    GroupActivityMetadata.LifetimePolicy.automatic.hash(into: &hasher)
    gaRequire(
        GroupActivityMetadata.LifetimePolicy.automatic.hashValue
            == GroupActivityMetadata.LifetimePolicy.automatic.hashValue,
        "hashValue"
    )
}

func testExperienceRawValues() {
    gaRequire(GroupActivityMetadata.Experience.watchTogether.rawValue == 0, "watch=0")
    gaRequire(GroupActivityMetadata.Experience.listenTogether.rawValue == 1, "listen=1")
    gaRequire(GroupActivityMetadata.Experience(rawValue: 0) == .watchTogether, "init 0")
    gaRequire(GroupActivityMetadata.Experience(rawValue: 1) == .listenTogether, "init 1")
    gaRequire(GroupActivityMetadata.Experience(rawValue: 2) == nil, "unknown nil")
    gaRequire(GroupActivityMetadata.Experience.RawValue.self == Int.self, "RawValue")
    gaRequire(
        GroupActivityMetadata.Experience.watchTogether != .listenTogether,
        "experience !="
    )
    var hasher = Hasher()
    GroupActivityMetadata.Experience.watchTogether.hash(into: &hasher)
    gaRequire(
        GroupActivityMetadata.Experience.watchTogether.hashValue
            == GroupActivityMetadata.Experience.watchTogether.hashValue,
        "hashValue"
    )
}

func testExperienceCodable() {
    do {
        let encoded = try JSONEncoder().encode(GroupActivityMetadata.Experience.watchTogether)
        let decoded = try JSONDecoder().decode(
            GroupActivityMetadata.Experience.self,
            from: encoded
        )
        gaRequire(decoded == .watchTogether, "experience round-trip")
        let reencoded = try JSONEncoder().encode(decoded)
        let again = try JSONDecoder().decode(
            GroupActivityMetadata.Experience.self,
            from: reencoded
        )
        gaRequire(again == .watchTogether, "encode(to:) round-trip")
    } catch {
        fatalError("Experience Codable failed: \(error)")
    }
}

func testMetadataDefaults() {
    let metadata = GroupActivityMetadata()
    gaRequire(metadata.title == nil, "title")
    gaRequire(metadata.subtitle == nil, "subtitle")
    gaRequire(metadata.localizedTitle == nil, "localizedTitle")
    gaRequire(metadata.localizedSubtitle == nil, "localizedSubtitle")
    gaRequire(metadata.fallbackURL == nil, "fallbackURL")
    gaRequire(metadata.type == .generic, "type")
    gaRequire(metadata.experience == nil, "experience")
    gaRequire(metadata.lifetimePolicy == .automatic, "lifetime")
    gaRequire(metadata.sceneAssociationBehavior == .default, "scene")
    gaRequire(!metadata.supportsContinuationOnTV, "tv")
    gaRequire(metadata.preferredBroadcastOptions.isEmpty, "broadcast")
}

func testMetadataMutationAndEquality() {
    var metadata = GroupActivityMetadata()
    metadata.title = "Title"
    metadata.subtitle = "Subtitle"
    metadata.localizedTitle = "Localized Title"
    metadata.localizedSubtitle = "Localized Subtitle"
    metadata.fallbackURL = URL(string: "https://example.invalid/fallback")
    metadata.type = .watchTogether
    metadata.experience = .watchTogether
    metadata.lifetimePolicy = .endsWhenInitiatorLeaves
    metadata.sceneAssociationBehavior = .content("scene-a")
    metadata.supportsContinuationOnTV = true
    metadata.preferredBroadcastOptions = .mirroredVideo

    gaRequire(metadata.title == "Title", "title set")
    gaRequire(metadata.subtitle == "Subtitle", "subtitle set")
    gaRequire(metadata.localizedTitle == "Localized Title", "localizedTitle")
    gaRequire(metadata.localizedSubtitle == "Localized Subtitle", "localizedSubtitle")
    gaRequire(metadata.fallbackURL?.absoluteString == "https://example.invalid/fallback", "url")
    gaRequire(metadata.type == .watchTogether, "type set")
    gaRequire(metadata.experience == .watchTogether, "experience set")
    gaRequire(metadata.lifetimePolicy == .endsWhenInitiatorLeaves, "lifetime set")
    gaRequire(metadata.sceneAssociationBehavior == .content("scene-a"), "scene set")
    gaRequire(metadata.supportsContinuationOnTV, "tv set")
    gaRequire(metadata.preferredBroadcastOptions == .mirroredVideo, "broadcast set")

    var other = metadata
    gaRequire(metadata == other, "equal")
    other.title = "Other"
    gaRequire(metadata != other, "metadata !=")
}

func testMetadataHashable() {
    var hasher = Hasher()
    GroupActivityMetadata().hash(into: &hasher)
    gaRequire(GroupActivityMetadata().hashValue == GroupActivityMetadata().hashValue, "hash")
}

func testMetadataCodableRoundTrip() {
    var metadata = GroupActivityMetadata()
    metadata.title = "Watch"
    metadata.fallbackURL = URL(string: "https://example.invalid/watch")
    metadata.type = .listenTogether
    metadata.experience = .listenTogether
    metadata.preferredBroadcastOptions = .mirroredVideo
    do {
        let encoded = try JSONEncoder().encode(metadata)
        let decoded = try JSONDecoder().decode(GroupActivityMetadata.self, from: encoded)
        gaRequire(decoded == metadata, "metadata JSON")
        let reencoded = try JSONEncoder().encode(decoded)
        let again = try JSONDecoder().decode(GroupActivityMetadata.self, from: reencoded)
        gaRequire(again.title == "Watch", "encode(to:)")
        gaRequire(again.fallbackURL == metadata.fallbackURL, "url round-trip")
    } catch {
        fatalError("GroupActivityMetadata Codable failed: \(error)")
    }
}

func testMetadataInitFromDecoderMissingKeys() {
    let data = Data("{}".utf8)
    do {
        let decoded = try JSONDecoder().decode(GroupActivityMetadata.self, from: data)
        gaRequire(decoded.type == .generic, "default type")
        gaRequire(decoded.lifetimePolicy == .automatic, "default lifetime")
    } catch {
        fatalError("empty object should decode: \(error)")
    }
}
