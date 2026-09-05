import Foundation

open class HMCameraControl: NSObject {
    public override init() {
        super.init()
    }
}

open class HMCameraSource: NSObject {
    public override init() {
        super.init()
    }
}

open class HMCameraStream: HMCameraSource {
    public private(set) var audioStreamSetting: HMCameraAudioStreamSetting = .muted

    public func updateAudioStreamSetting(_ audioStreamSetting: HMCameraAudioStreamSetting) async throws {
        _ = audioStreamSetting
        throw HMFailClosed(.operationNotSupported)
    }
}

open class HMCameraSnapshot: HMCameraSource {
    public private(set) var captureDate: Date = Date(timeIntervalSince1970: 0)
}

open class HMCameraStreamControl: HMCameraControl {
    public weak var delegate: (any HMCameraStreamControlDelegate)?
    public private(set) var streamState: HMCameraStreamState = .notStreaming
    public private(set) var cameraStream: HMCameraStream?

    public func startStream() {
        // No RTP / HAP camera session exists. Stay notStreaming; do not invent success.
        streamState = .notStreaming
        cameraStream = nil
    }

    public func stopStream() {
        streamState = .notStreaming
        cameraStream = nil
    }

    public static func host_make() -> HMCameraStreamControl {
        HMCameraStreamControl()
    }
}

open class HMCameraSnapshotControl: HMCameraControl {
    public weak var delegate: (any HMCameraSnapshotControlDelegate)?
    public private(set) var mostRecentSnapshot: HMCameraSnapshot?

    public func takeSnapshot() {
        mostRecentSnapshot = nil
    }

    public static func host_make() -> HMCameraSnapshotControl {
        HMCameraSnapshotControl()
    }
}

open class HMCameraSettingsControl: HMCameraControl {
    public private(set) var nightVision: HMCharacteristic?
    public private(set) var currentHorizontalTilt: HMCharacteristic?
    public private(set) var targetHorizontalTilt: HMCharacteristic?
    public private(set) var currentVerticalTilt: HMCharacteristic?
    public private(set) var targetVerticalTilt: HMCharacteristic?
    public private(set) var opticalZoom: HMCharacteristic?
    public private(set) var digitalZoom: HMCharacteristic?
    public private(set) var imageRotation: HMCharacteristic?
    public private(set) var imageMirroring: HMCharacteristic?
}

open class HMCameraAudioControl: HMCameraControl {
    public private(set) var mute: HMCharacteristic?
    public private(set) var volume: HMCharacteristic?
}

open class HMCameraProfile: HMAccessoryProfile {
    public private(set) var streamControl: HMCameraStreamControl?
    public private(set) var snapshotControl: HMCameraSnapshotControl?
    public private(set) var settingsControl: HMCameraSettingsControl?
    public private(set) var speakerControl: HMCameraAudioControl?
    public private(set) var microphoneControl: HMCameraAudioControl?
}

@MainActor
open class HMCameraView: NSObject {
    public var cameraSource: HMCameraSource?

    public override init() {
        super.init()
    }
}
