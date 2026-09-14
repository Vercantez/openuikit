import Foundation
import AVFoundation

func testAVAssetDownloadConfigurationStoresArtworkTitleAndContent() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-download-config.mp4"))
    let configuration = AVAssetDownloadConfiguration(asset: asset, title: "Episode 1")
    precondition(configuration.asset === asset)
    precondition(configuration.title == "Episode 1")
    configuration.title = "Episode 1 (HDR)"
    precondition(configuration.title == "Episode 1 (HDR)")

    precondition(configuration.artworkData == nil)
    let artwork = Data([0x89, 0x50, 0x4E, 0x47])
    configuration.artworkData = artwork
    precondition(configuration.artworkData == artwork)

    let primary = configuration.primaryContentConfiguration
    precondition(primary === configuration.primaryContentConfiguration)
    precondition(configuration.auxiliaryContentConfigurations.isEmpty)
    let auxiliary = AVAssetDownloadContentConfiguration()
    configuration.auxiliaryContentConfigurations = [auxiliary]
    precondition(configuration.auxiliaryContentConfigurations.count == 1)
    precondition(configuration.auxiliaryContentConfigurations[0] === auxiliary)

    precondition(!configuration.optimizesAuxiliaryContentConfigurations)
    configuration.optimizesAuxiliaryContentConfigurations = true
    precondition(configuration.optimizesAuxiliaryContentConfigurations)

    let criteria = AVPlayerMediaSelectionCriteria(
        preferredLanguages: ["en"],
        preferredMediaCharacteristics: [.audible]
    )
    configuration.setInterstitialMediaSelectionCriteria([criteria], forMediaCharacteristic: .audible)
    let stored = configuration.interstitialMediaSelectionCriteria(forMediaCharacteristic: .audible)
    precondition(stored.count == 1)
    precondition(stored[0] === criteria)
    precondition(configuration.interstitialMediaSelectionCriteria(forMediaCharacteristic: .visual).isEmpty)
}

func testAVAssetDownloadContentConfigurationStoresSelectionsAndQualifiers() {
    let content = AVAssetDownloadContentConfiguration()
    precondition(content.mediaSelections.isEmpty)
    precondition(content.variantQualifiers.isEmpty)

    let selection = AVMediaSelection()
    content.mediaSelections = [selection]
    precondition(content.mediaSelections.count == 1)
    precondition(content.mediaSelections[0] === selection)

    let qualifier = AVAssetVariantQualifier(predicate: NSPredicate(value: true))
    content.variantQualifiers = [qualifier]
    precondition(content.variantQualifiers.count == 1)
    precondition(content.variantQualifiers[0] === qualifier)
}

func testAVAssetDownloadStorageManagerSharedPolicyStore() {
    let custom = AVAssetDownloadedAssetEvictionPriority(rawValue: "important")
    precondition(custom == .important)
    precondition(AVAssetDownloadedAssetEvictionPriority(rawValue: "default") == .default)

    let shared = AVAssetDownloadStorageManager.shared()
    precondition(shared === AVAssetDownloadStorageManager.shared())

    let policy = AVMutableAssetDownloadStorageManagementPolicy()
    precondition(policy.priority == .default)
    policy.priority = .important
    let expiration = Date(timeIntervalSince1970: 1_900_000_000)
    policy.expirationDate = expiration
    precondition(policy.priority == .important)
    precondition(policy.expirationDate == expiration)

    let immutable = AVAssetDownloadStorageManagementPolicy()
    _ = immutable.priority
    _ = immutable.expirationDate

    let url = URL(fileURLWithPath: "/tmp/openav-download-policy-\(UUID().uuidString)")
    precondition(shared.storageManagementPolicy(for: url) == nil)
    shared.setStorageManagementPolicy(policy, for: url)
    let stored = shared.storageManagementPolicy(for: url)
    precondition(stored === policy)
    precondition(stored?.priority == .important)
    precondition(stored?.expirationDate == expiration)
    precondition(shared.storageManagementPolicy(for: URL(fileURLWithPath: "/tmp/openav-missing-policy")) == nil)
}

func testAVAssetImageGeneratorCompletionHandlerInvokesSynchronously() {
    var stored: AVAssetImageGeneratorCompletionHandler?
    var seen = 0
    stored = { requested, image, actual, result, error in
        seen += 1
        precondition(requested == CMTime.zero)
        precondition(image == nil)
        precondition(actual == .invalid)
        precondition(result == .failed)
        precondition((error as? AVError)?.code == .noImageAtTime)
    }
    stored?(CMTime.zero, nil, .invalid, .failed, AVError(.noImageAtTime))
    precondition(seen == 1)

    let generator = AVAssetImageGenerator(
        asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-missing-handler.mp4"))
    )
    seen = 0
    let handler: AVAssetImageGeneratorCompletionHandler = { _, image, _, result, error in
        seen += 1
        precondition(image == nil)
        precondition(result == .failed)
        precondition((error as? AVError)?.code == .noImageAtTime)
    }
    generator.generateCGImagesAsynchronously(forTimes: [NSNumber(value: 0)], completionHandler: handler)
    precondition(seen == 1)
}

func testAVPlayerMediaSelectionCriteriaStoresLanguagesAndCharacteristics() {
    let preferred = AVPlayerMediaSelectionCriteria(
        preferredLanguages: ["en", "es"],
        preferredMediaCharacteristics: [.audible, .legible]
    )
    precondition(preferred.preferredLanguages == ["en", "es"])
    precondition(preferred.preferredMediaCharacteristics == [.audible, .legible])
    precondition(preferred.principalMediaCharacteristics == nil)

    let principal = AVPlayerMediaSelectionCriteria(
        principalMediaCharacteristics: [.visual],
        preferredLanguages: ["ja"],
        preferredMediaCharacteristics: [.containsOnlyForcedSubtitles]
    )
    precondition(principal.principalMediaCharacteristics == [.visual])
    precondition(principal.preferredLanguages == ["ja"])
    precondition(principal.preferredMediaCharacteristics == [.containsOnlyForcedSubtitles])
}

func testAVAssetPlaybackAssistantPassDescriptionAndRequestor() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-assistant.mp4"))
    let assistant = AVAssetPlaybackAssistant(asset: asset)
    precondition(assistant.asset === asset)

    let pass = AVAssetWriterInputPassDescription()
    precondition(pass.sourceTimeRanges.isEmpty)

    let requestor = AVAssetResourceLoadingRequestor()
    precondition(!requestor.providesExpiredSessionReports)

    let parameters = AVAudioMixInputParameters()
    precondition(parameters.audioTimePitchAlgorithm == nil)
    parameters.audioTimePitchAlgorithm = .spectral
    precondition(parameters.audioTimePitchAlgorithm == .spectral)
}
