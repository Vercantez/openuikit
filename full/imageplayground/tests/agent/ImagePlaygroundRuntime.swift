import Foundation
@_spi(OpenUIKitHost) import ImagePlayground

func waitFor(_ body: @escaping () async -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        await body()
        lock.signal()
    }
    precondition(lock.wait(timeout: .now() + 10) == .success, "async probe timed out")
}

// MARK: Styles

let styles = [
    ImagePlaygroundStyle.animation,
    ImagePlaygroundStyle.illustration,
    ImagePlaygroundStyle.sketch,
    ImagePlaygroundStyle.externalProvider,
]
precondition(styles[0] != styles[1])
precondition(styles[0] == ImagePlaygroundStyle.animation)
precondition(ImagePlaygroundStyle.animation.id == "animation")
precondition(ImagePlaygroundStyle.illustration.id == "illustration")
precondition(ImagePlaygroundStyle.sketch.id == "sketch")
precondition(ImagePlaygroundStyle.externalProvider.id == "externalProvider")

let all = ImagePlaygroundStyle.all
precondition(all.count == 4)
precondition(Set(all.map(\.id)) == Set(styles.map(\.id)))

var hasherA = Hasher()
var hasherB = Hasher()
ImagePlaygroundStyle.sketch.hash(into: &hasherA)
ImagePlaygroundStyle.sketch.hash(into: &hasherB)
precondition(hasherA.finalize() == hasherB.finalize())
precondition(ImagePlaygroundStyle.sketch.hashValue == ImagePlaygroundStyle.sketch.hashValue)

let encoded = try JSONEncoder().encode(ImagePlaygroundStyle.illustration)
let decoded = try JSONDecoder().decode(ImagePlaygroundStyle.self, from: encoded)
precondition(decoded == .illustration)

// MARK: Personalization policy

precondition(ImagePlaygroundPersonalizationPolicy.automatic != .enabled)
precondition(ImagePlaygroundPersonalizationPolicy.disabled != .automatic)
precondition(ImagePlaygroundPersonalizationPolicy.automatic.rawValue == 0)
precondition(ImagePlaygroundPersonalizationPolicy.enabled.rawValue == 1)
precondition(ImagePlaygroundPersonalizationPolicy.disabled.rawValue == 2)
precondition(ImagePlaygroundPersonalizationPolicy(rawValue: 1) == .enabled)
precondition(ImagePlaygroundPersonalizationPolicy(rawValue: 99) == nil)

var policyHasher = Hasher()
ImagePlaygroundPersonalizationPolicy.enabled.hash(into: &policyHasher)
_ = policyHasher.finalize()
_ = ImagePlaygroundPersonalizationPolicy.enabled.hashValue

// MARK: Concepts

let text = ImagePlaygroundConcept.text("a red bicycle")
precondition(ImagePlaygroundHostControl.conceptKind(text) == "text")
precondition(ImagePlaygroundHostControl.conceptText(text) == "a red bicycle")

let extracted = ImagePlaygroundConcept.extracted(from: "sunset over water", title: "caption")
precondition(ImagePlaygroundHostControl.conceptKind(extracted) == "extracted")
precondition(ImagePlaygroundHostControl.conceptText(extracted) == "sunset over water")
precondition(ImagePlaygroundHostControl.conceptTitle(extracted) == "caption")

let untitled = ImagePlaygroundConcept.extracted(from: "plain")
precondition(ImagePlaygroundHostControl.conceptTitle(untitled) == nil)

let fileURL = URL(fileURLWithPath: "/tmp/imageplayground-probe.png")
let fromURL = ImagePlaygroundConcept.image(fileURL)
precondition(fromURL != nil)
precondition(ImagePlaygroundHostControl.conceptKind(fromURL!) == "imageURL")
precondition(ImagePlaygroundHostControl.conceptImageURL(fromURL!) == fileURL)

// MARK: Creator fail-closed

waitFor {
    do {
        _ = try await ImageCreator()
        preconditionFailure("ImageCreator.init must not succeed on this Linux host")
    } catch let error as ImageCreator.Error {
        precondition(error == .unavailable)
        precondition(error != .creationFailed)
        precondition(error.errorCode == ImageCreator.Error.allCases.firstIndex(of: .unavailable)!)
        precondition(ImageCreator.Error.errorDomain == "ImagePlayground.ImageCreator.Error")
        precondition(error.errorUserInfo.isEmpty)
        precondition(error.errorDescription == nil)
        precondition(error.failureReason == nil)
        precondition(error.recoverySuggestion == nil)
        precondition(error.helpAnchor == nil)
        _ = error.localizedDescription
    } catch {
        preconditionFailure("ImageCreator.init threw unexpected \(error)")
    }
}

let hostCreator = ImagePlaygroundHostControl.makeImageCreator()
precondition(Set(hostCreator.availableStyles.map(\.id)) == Set(ImagePlaygroundStyle.all.map(\.id)))

let cases = ImageCreator.Error.allCases
precondition(Set(cases) == [
    .unsupportedInputImage,
    .faceInImageTooSmall,
    .unavailable,
    .notSupported,
    .creationFailed,
    .creationCancelled,
    .unsupportedLanguage,
    .backgroundCreationForbidden,
    .conceptsRequirePersonIdentity,
])
precondition(ImageCreator.Error.AllCases.self == [ImageCreator.Error].self)

print("IMAGEPLAYGROUND_AGENT_RUNTIME_OK")
