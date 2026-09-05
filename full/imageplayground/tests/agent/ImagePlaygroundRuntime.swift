import Dispatch
import Foundation
@_spi(OpenUIKitHost) import ImagePlayground

/// Schema-v1 sealed gate compiles this file alone. Focused `*Tests.swift`
/// functions are the coverage evidence; this probe re-exercises the same
/// fail-closed Linux host behaviour and prints the runtime marker.

func waitForRuntime(_ body: @escaping () async -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        await body()
        lock.signal()
    }
    precondition(lock.wait(timeout: .now() + 10) == .success, "async probe timed out")
}

precondition(ImagePlaygroundStyle.animation.id == "animation")
precondition(ImagePlaygroundStyle.illustration.id == "illustration")
precondition(ImagePlaygroundStyle.sketch.id == "sketch")
precondition(ImagePlaygroundStyle.externalProvider.id == "externalProvider")
precondition(ImagePlaygroundStyle.all.count == 4)
precondition(ImagePlaygroundStyle.animation != .sketch)

let encoded = try JSONEncoder().encode(ImagePlaygroundStyle.illustration)
let decoded = try JSONDecoder().decode(ImagePlaygroundStyle.self, from: encoded)
precondition(decoded == .illustration)

precondition(ImagePlaygroundPersonalizationPolicy.automatic.rawValue == 0)
precondition(ImagePlaygroundPersonalizationPolicy.enabled.rawValue == 1)
precondition(ImagePlaygroundPersonalizationPolicy.disabled.rawValue == 2)
precondition(ImagePlaygroundPersonalizationPolicy(rawValue: 1) == .enabled)

let text = ImagePlaygroundConcept.text("a red bicycle")
precondition(ImagePlaygroundHostControl.conceptKind(text) == "text")
let extracted = ImagePlaygroundConcept.extracted(from: "sunset over water", title: "caption")
precondition(ImagePlaygroundHostControl.conceptTitle(extracted) == "caption")
let fileURL = URL(fileURLWithPath: "/tmp/imageplayground-probe.png")
precondition(ImagePlaygroundConcept.image(fileURL) != nil)
precondition(ImagePlaygroundConcept.image(URL(string: "https://example.com/x.png")!) == nil)

waitForRuntime {
    do {
        _ = try await ImageCreator()
        preconditionFailure("ImageCreator.init must not succeed on this Linux host")
    } catch let error as ImageCreator.Error {
        precondition(error == .unavailable)
        precondition(error.errorDescription == "Image creation is currently unavailable.")
        precondition(ImageCreator.Error.errorDomain == "ImagePlayground.ImageCreator.Error")
        precondition(error.errorUserInfo.isEmpty)
        precondition(error.errorCode == ImageCreator.Error.allCases.firstIndex(of: .unavailable)!)
        _ = error.localizedDescription
    } catch {
        preconditionFailure("ImageCreator.init threw unexpected \(error)")
    }
}

let hostCreator = ImagePlaygroundHostControl.makeImageCreator()
precondition(hostCreator.availableStyles.map(\.id) == ImagePlaygroundStyle.all.map(\.id))
precondition(ImageCreator.Error.allCases.count == 9)

print("IMAGEPLAYGROUND_AGENT_RUNTIME_OK")
