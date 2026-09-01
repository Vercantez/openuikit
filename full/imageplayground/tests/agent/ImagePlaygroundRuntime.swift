import ImagePlayground
import Foundation

enum ImagePlaygroundRuntime {
    static func main() async {
        exerciseStyles()
        exercisePolicy()
        exerciseConcepts()
        exerciseErrors()
        await exerciseCreator()
        print("IMAGEPLAYGROUND_AGENT_RUNTIME_OK")
    }

    static func require(_ condition: Bool, _ message: String) {
        guard condition else {
            fatalError(message)
        }
    }

    static func exerciseStyles() {
        require(
            ImagePlaygroundStyle.illustration != ImagePlaygroundStyle.sketch,
            "illustration and sketch must be distinct"
        )
        require(
            ImagePlaygroundStyle.animation != ImagePlaygroundStyle.externalProvider,
            "animation and externalProvider must be distinct"
        )
        let all = Set(ImagePlaygroundStyle.all)
        require(all.contains(.illustration), "all contains illustration")
        require(all.contains(.sketch), "all contains sketch")
        require(all.contains(.animation), "all contains animation")
        require(all.contains(.externalProvider), "all contains externalProvider")
        require(all.count == 4, "four public styles")
        _ = ImagePlaygroundStyle.illustration.hashValue
        let _: ImagePlaygroundStyle.ID = ImagePlaygroundStyle.sketch.id
    }

    static func exercisePolicy() {
        require(
            ImagePlaygroundPersonalizationPolicy.automatic
                != ImagePlaygroundPersonalizationPolicy.enabled,
            "automatic and enabled are distinct cases"
        )
        require(
            ImagePlaygroundPersonalizationPolicy.enabled
                != ImagePlaygroundPersonalizationPolicy.disabled,
            "enabled and disabled are distinct cases"
        )
        let enabled = ImagePlaygroundPersonalizationPolicy.enabled
        require(
            ImagePlaygroundPersonalizationPolicy(rawValue: enabled.rawValue) == .enabled,
            "rawValue round-trip for enabled"
        )
        require(
            ImagePlaygroundPersonalizationPolicy(rawValue: Int.max) == nil,
            "unknown rawValue is nil"
        )
        var hasher = Hasher()
        ImagePlaygroundPersonalizationPolicy.disabled.hash(into: &hasher)
        _ = hasher.finalize()
        _ = ImagePlaygroundPersonalizationPolicy.automatic.hashValue
        let _: ImagePlaygroundPersonalizationPolicy.RawValue = enabled.rawValue
    }

    static func exerciseConcepts() {
        _ = ImagePlaygroundConcept.text("a red sailboat")
        _ = ImagePlaygroundConcept.extracted(
            from: "Long-form notes about a harbor at dusk.",
            title: "Harbor"
        )
        _ = ImagePlaygroundConcept.extracted(from: "untitled source")
        let url = URL(fileURLWithPath: "/tmp/imageplayground-isolated-unvalidated.png")
        _ = ImagePlaygroundConcept.image(url)
    }

    static func exerciseErrors() {
        let all = Set(ImageCreator.Error.allCases)
        require(all.count == 9, "nine public error cases")
        require(all.contains(.notSupported), "notSupported")
        require(all.contains(.unavailable), "unavailable")
        require(all.contains(.creationCancelled), "creationCancelled")
        require(all.contains(.faceInImageTooSmall), "faceInImageTooSmall")
        require(all.contains(.unsupportedLanguage), "unsupportedLanguage")
        require(all.contains(.unsupportedInputImage), "unsupportedInputImage")
        require(all.contains(.backgroundCreationForbidden), "backgroundCreationForbidden")
        require(all.contains(.creationFailed), "creationFailed")
        require(all.contains(.conceptsRequirePersonIdentity), "conceptsRequirePersonIdentity")
        require(ImageCreator.Error.notSupported == .notSupported, "error equality")
        require(ImageCreator.Error.notSupported != .unavailable, "error inequality")
        _ = ImageCreator.Error.notSupported.hashValue
        let _: ImageCreator.Error.AllCases = ImageCreator.Error.allCases
        _ = ImageCreator.Error.errorDomain
        _ = ImageCreator.Error.notSupported.errorCode
        _ = ImageCreator.Error.notSupported.errorUserInfo
        _ = ImageCreator.Error.notSupported.errorDescription
        _ = ImageCreator.Error.notSupported.failureReason
        _ = ImageCreator.Error.notSupported.recoverySuggestion
        _ = ImageCreator.Error.notSupported.helpAnchor
        _ = ImageCreator.Error.notSupported.localizedDescription
    }

    static func exerciseCreator() async {
        do {
            _ = try await ImageCreator()
            fatalError("ImageCreator() must throw on Linux")
        } catch let error as ImageCreator.Error {
            require(error == .notSupported, "init throws notSupported")
        } catch {
            fatalError("expected ImageCreator.Error, got \(error)")
        }
        let _: ImageCreator.CreatedImage.Type = ImageCreator.CreatedImage.self
    }
}

await ImagePlaygroundRuntime.main()
