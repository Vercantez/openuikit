#if canImport(AVFoundation)
import AVFoundation
#endif
import CallKit
import Foundation

/// Future EC2 dependency-identity probe. The isolated host gate does not
/// compile this file. A cold integrated run must import real guest Foundation
/// and AVFoundation, pass an `AVAudioSession` through the provider audio
/// session callbacks when those methods exist, link `libCallKit.dylib`, and
/// print `CALLKIT_DEPENDENCY_IDENTITY_OK`.
public enum CallKitDependencyIdentity {
    public static let marker = "CALLKIT_DEPENDENCY_IDENTITY_OK"
}
