import Speech
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif
import Foundation

// Future EC2 probe: pass real AVFoundation/CoreMedia values through Speech
// once those guest modules are on the search path. The isolated host gate
// does not compile or run this file.
enum SpeechDependencyIdentity {
    static let marker = "SPEECH_DEPENDENCY_IDENTITY_OK"
}
