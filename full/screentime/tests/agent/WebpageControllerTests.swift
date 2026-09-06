import Foundation
@_spi(OpenUIKitHost) import ScreenTime

private func stMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated {
            try body()
        }
    } catch {
        fatalError("ScreenTime webpage test failed: \(error)")
    }
}

func testWebpageControllerType() {
    stMain {
        let controller = STWebpageController()
        precondition(type(of: controller) == STWebpageController.self)
        precondition(controller is NSObject)
    }
}

func testWebpageControllerSetBundleIdentifier() {
    stMain {
        let controller = STWebpageController()
        try controller.setBundleIdentifier("com.example.browser")
        precondition(controller.bundleIdentifier == "com.example.browser")
        do {
            try controller.setBundleIdentifier("")
            preconditionFailure("empty bundle identifier must throw")
        } catch let error as STScreenTimeError {
            precondition(error == .invalidBundleIdentifier)
        }
        precondition(controller.bundleIdentifier == "com.example.browser")
    }
}

func testWebpageControllerURL() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.url == nil)
        let url = URL(string: "https://example.invalid/article")!
        controller.url = url
        precondition(controller.url == url)
        controller.url = nil
        precondition(controller.url == nil)
    }
}

func testWebpageControllerURLIsBlocked() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.urlIsBlocked == false)
        controller.url = URL(string: "https://blocked.example.invalid/")
        precondition(controller.urlIsBlocked == false)
    }
}

func testWebpageControllerURLIsPictureInPicture() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.urlIsPictureInPicture == false)
        controller.urlIsPictureInPicture = true
        precondition(controller.urlIsPictureInPicture)
        controller.urlIsPictureInPicture = false
        precondition(controller.urlIsPictureInPicture == false)
    }
}

func testWebpageControllerURLIsPlayingVideo() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.urlIsPlayingVideo == false)
        controller.urlIsPlayingVideo = true
        precondition(controller.urlIsPlayingVideo)
        controller.urlIsPlayingVideo = false
        precondition(controller.urlIsPlayingVideo == false)
    }
}

func testWebpageControllerProfileIdentifier() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.profileIdentifier == nil)
        let profile = STWebHistory.ProfileIdentifier("Profile.Shopping")
        controller.profileIdentifier = profile
        precondition(controller.profileIdentifier == profile)
        controller.profileIdentifier = nil
        precondition(controller.profileIdentifier == nil)
    }
}

func testWebpageControllerSuppressUsageRecording() {
    stMain {
        let controller = STWebpageController()
        precondition(controller.suppressUsageRecording == false)
        controller.suppressUsageRecording = true
        precondition(controller.suppressUsageRecording)
        controller.suppressUsageRecording = false
        precondition(controller.suppressUsageRecording == false)
    }
}
