import Foundation
@_spi(OpenUIKitHost) import LockedCameraCapture

private func makeSession() -> LockedCameraCaptureSession {
    do {
        return try LockedCameraCaptureSession.hostMakeSession()
    } catch {
        preconditionFailure("session directory unavailable")
    }
}

func testLockedCameraCaptureSessionClass() {
    let session = makeSession()
    precondition(type(of: session) == LockedCameraCaptureSession.self)
    let asObject: AnyObject = session
    precondition(asObject === session)
}

func testSessionContentURL() {
    let session = makeSession()
    let url = session.sessionContentURL
    precondition(url.isFileURL)
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    precondition(exists)
    precondition(isDirectory.boolValue)
    precondition(url.lastPathComponent.hasPrefix("LockedCameraCapture-"))
}

func testSessionInvalidateSessionContent() {
    let session = makeSession()
    let marker = session.sessionContentURL.appendingPathComponent("capture.bin")
    do {
        try Data([0x01, 0x02, 0x03]).write(to: marker)
        precondition(FileManager.default.fileExists(atPath: marker.path))
        try session.invalidateSessionContent()
        precondition(!FileManager.default.fileExists(atPath: marker.path))
        var isDirectory: ObjCBool = false
        let dirExists = FileManager.default.fileExists(
            atPath: session.sessionContentURL.path,
            isDirectory: &isDirectory
        )
        precondition(dirExists)
        precondition(isDirectory.boolValue)
        let leftovers = try FileManager.default.contentsOfDirectory(
            at: session.sessionContentURL,
            includingPropertiesForKeys: nil
        )
        precondition(leftovers.isEmpty)
    } catch {
        preconditionFailure("invalidateSessionContent filesystem failure")
    }
}

func testSessionOpenApplication() {
    let session = makeSession()
    let activity = NSUserActivity(activityType: NSUserActivityTypeLockedCameraCapture)
    activity.userInfo = ["probe": "open"]
    var caught: LockedCameraCaptureSession.ApplicationLaunchError?
    do {
        try session.openApplication(for: activity)
        preconditionFailure("openApplication must fail closed")
    } catch let error as LockedCameraCaptureSession.ApplicationLaunchError {
        caught = error
    } catch {
        preconditionFailure("unexpected error")
    }
    precondition(caught == .unknown)
    precondition(session.hostLastOpenActivityType == NSUserActivityTypeLockedCameraCapture)
    let nsError = caught.map { $0 as NSError }
    precondition(nsError?.domain == LockedCameraCaptureSession.ApplicationLaunchError.errorDomain)
    precondition(nsError?.code == 0)
}
