import ImagePlayground
import Foundation

enum ImagePlaygroundRuntime {
    @MainActor
    final class ProbeDelegate: ImagePlaygroundViewController.Delegate {
        func imagePlaygroundViewController(
            _ imagePlaygroundViewController: ImagePlaygroundViewController,
            didCreateImageAt imageURL: URL
        ) {
            _ = imagePlaygroundViewController
            _ = imageURL
        }
    }

    static func main() async {
        await MainActor.run {
            exerciseStyles()
            exercisePolicy()
            exerciseConcepts()
            exerciseViewController()
            exerciseErrors()
        }
        await exerciseCreator()
        print("IMAGEPLAYGROUND_AGENT_RUNTIME_OK")
    }

    static func require(_ condition: Bool, _ message: String) {
        guard condition else {
            fatalError(message)
        }
    }

    static func requireNotSupported(_ error: Error) {
        guard let typed = error as? ImageCreator.Error else {
            fatalError("expected ImageCreator.Error, got \(error)")
        }
        require(typed == .notSupported, "expected notSupported, got \(typed)")
        require(typed != .unavailable, "inequality failed for notSupported")
        require(typed.errorCode == 0, "notSupported errorCode")
        require(
            ImageCreator.Error.errorDomain == ImageCreator.Error.errorDomain,
            "errorDomain mismatch"
        )
        require(
            ImageCreator.Error.errorDomain == "ImagePlayground.ImageCreator.Error",
            "errorDomain string"
        )
    }

    @MainActor
    static func exerciseStyles() {
        require(ImagePlaygroundStyle.illustration.id == "illustration", "illustration id")
        require(ImagePlaygroundStyle.sketch.id == "sketch", "sketch id")
        require(ImagePlaygroundStyle.animation.id == "animation", "animation id")
        require(ImagePlaygroundStyle.externalProvider.id == "externalProvider", "externalProvider id")
        require(
            ImagePlaygroundStyle.all == [
                .illustration, .sketch, .animation, .externalProvider
            ],
            "Style.all contents"
        )
        require(ImagePlaygroundStyle.illustration == ImagePlaygroundStyle.illustration, "style equality")
        require(ImagePlaygroundStyle.illustration != ImagePlaygroundStyle.sketch, "style inequality")
        require(
            Set(ImagePlaygroundStyle.all).count == ImagePlaygroundStyle.all.count,
            "style hash uniqueness"
        )
        _ = ImagePlaygroundStyle.illustration.hashValue

        do {
            let data = try JSONEncoder().encode(ImagePlaygroundStyle.sketch)
            let decoded = try JSONDecoder().decode(ImagePlaygroundStyle.self, from: data)
            require(decoded == .sketch, "style round-trip")
            require(decoded.id == ImagePlaygroundStyle.ID("sketch"), "ID typealias")
        } catch {
            fatalError("style Codable failed: \(error)")
        }
    }

    @MainActor
    static func exercisePolicy() {
        require(ImagePlaygroundPersonalizationPolicy.automatic.rawValue == 0, "automatic rawValue")
        require(ImagePlaygroundPersonalizationPolicy.enabled.rawValue == 1, "enabled rawValue")
        require(ImagePlaygroundPersonalizationPolicy.disabled.rawValue == 2, "disabled rawValue")
        require(ImagePlaygroundPersonalizationPolicy(rawValue: 1) == .enabled, "init(rawValue:)")
        require(ImagePlaygroundPersonalizationPolicy(rawValue: 99) == nil, "unknown rawValue")
        require(
            ImagePlaygroundPersonalizationPolicy.automatic != .disabled,
            "policy inequality"
        )
        var hasher = Hasher()
        ImagePlaygroundPersonalizationPolicy.enabled.hash(into: &hasher)
        _ = hasher.finalize()
        _ = ImagePlaygroundPersonalizationPolicy.automatic.hashValue
        let _: ImagePlaygroundPersonalizationPolicy.RawValue =
            ImagePlaygroundPersonalizationPolicy.disabled.rawValue
    }

    @MainActor
    static func exerciseConcepts() {
        let text = ImagePlaygroundConcept.text("a red sailboat")
        let extracted = ImagePlaygroundConcept.extracted(
            from: "Long-form notes about a harbor at dusk.",
            title: "Harbor"
        )
        let untitled = ImagePlaygroundConcept.extracted(from: "untitled source")

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("imageplayground-runtime-probe.dat")
        do {
            try Data([0x89, 0x50, 0x4E, 0x47]).write(to: fileURL)
        } catch {
            fatalError("failed to write probe file: \(error)")
        }
        let existing = ImagePlaygroundConcept.image(fileURL)
        require(existing != nil, "existing file URL should wrap")

        let missing = ImagePlaygroundConcept.image(
            URL(fileURLWithPath: "/tmp/imageplayground-missing-\(UUID().uuidString).png")
        )
        require(missing == nil, "missing file URL should be nil")

        let remote = ImagePlaygroundConcept.image(URL(string: "https://example.invalid/image.png")!)
        require(remote == nil, "remote URL should be nil")

        _ = (text, extracted, untitled)
    }

    @MainActor
    static func exerciseViewController() {
        require(!ImagePlaygroundViewController.isAvailable, "isAvailable must be false")

        let controller = ImagePlaygroundViewController()
        require(controller.concepts.isEmpty, "default concepts")
        require(controller.allowedGenerationStyles == ImagePlaygroundStyle.all, "default allowed styles")
        require(controller.selectedGenerationStyle == .illustration, "default selected style")
        require(controller.personalizationPolicy == .automatic, "default policy")
        require(controller.preferredContentSize == .zero, "default preferredContentSize")
        require(controller.isModalInPresentation == false, "default isModalInPresentation")
        require(controller.delegate == nil, "default delegate")

        controller.concepts = [
            .text("lighthouse"),
            .extracted(from: "A paragraph about a lighthouse.", title: "Light")
        ]
        controller.allowedGenerationStyles = [.sketch]
        controller.selectedGenerationStyle = .sketch
        controller.personalizationPolicy = .disabled
        controller.preferredContentSize = CGSize(width: 320, height: 480)
        controller.isModalInPresentation = true

        let delegate = ProbeDelegate()
        controller.delegate = delegate
        require(controller.delegate != nil, "delegate retained weakly while alive")
        require(controller.concepts.count == 2, "concepts stored")
        require(controller.allowedGenerationStyles == [.sketch], "allowed styles stored")
        require(controller.selectedGenerationStyle == .sketch, "selected style stored")
        require(controller.personalizationPolicy == .disabled, "policy stored")
        require(controller.preferredContentSize.width == 320, "preferredContentSize stored")
        require(controller.isModalInPresentation, "isModalInPresentation stored")

        controller.viewDidLoad()
        controller.viewDidDisappear(true)
        _ = delegate
    }

    @MainActor
    static func exerciseErrors() {
        let all = ImageCreator.Error.allCases
        require(all.count == 9, "allCases count")
        require(
            all == [
                .notSupported,
                .unavailable,
                .creationCancelled,
                .faceInImageTooSmall,
                .unsupportedLanguage,
                .unsupportedInputImage,
                .backgroundCreationForbidden,
                .creationFailed,
                .conceptsRequirePersonIdentity
            ],
            "allCases order"
        )
        require(Set(all).count == all.count, "error hash uniqueness")
        _ = ImageCreator.Error.notSupported.hashValue
        let _: ImageCreator.Error.AllCases = ImageCreator.Error.allCases

        for error in all {
            require(
                ImageCreator.Error.errorDomain == "ImagePlayground.ImageCreator.Error",
                "domain"
            )
            require(error.errorUserInfo.isEmpty, "errorUserInfo empty")
            require(error.errorDescription != nil, "errorDescription")
            require(error.failureReason == error.errorDescription, "failureReason")
            require(error.recoverySuggestion != nil, "recoverySuggestion")
            require(error.helpAnchor == nil, "helpAnchor")
            require(!error.localizedDescription.isEmpty, "localizedDescription")
            let ns = error as NSError
            require(ns.domain == ImageCreator.Error.errorDomain, "NSError domain")
            require(ns.code == error.errorCode, "NSError code")
        }
        require(ImageCreator.Error.notSupported.errorCode == 0, "code 0")
        require(ImageCreator.Error.conceptsRequirePersonIdentity.errorCode == 8, "code 8")
    }

    static func exerciseCreator() async {
        do {
            _ = try await ImageCreator()
            fatalError("ImageCreator() must throw on Linux")
        } catch {
            requireNotSupported(error)
        }

        let _: ImageCreator.CreatedImage.Type = ImageCreator.CreatedImage.self
    }
}

await ImagePlaygroundRuntime.main()
