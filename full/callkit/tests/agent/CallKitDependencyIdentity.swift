import Foundation
import AVFoundation
@_spi(OpenUIKitHost) import CallKit

#if os(Linux)
import Glibc
#endif

/// Future EC2 integration client.
///
/// Isolated `test_host.sh` does not compile or run this file. A later EC2 run
/// must build the real guest Foundation and AVFoundation modules and dylibs
/// first, compile CallKit with those `-I`/`-L` paths, then link this client
/// against `libCallKit.dylib` plus the dependency dylibs and run it with
/// `LD_LIBRARY_PATH`. It must not be taken as success of the isolated gate.

private final class AudioSessionDelegateProbe: NSObject, CXProviderDelegate {
    var activated: AVAudioSession?
    var deactivated: AVAudioSession?

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        _ = provider
        activated = audioSession
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        _ = provider
        deactivated = audioSession
    }
}

private func moduleName<T>(_ type: T.Type) -> String {
    String(reflecting: type)
}

private func libCallKitIsLoaded() -> Bool {
    if let maps = try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8),
       maps.contains("libCallKit.dylib")
    {
        return true
    }
    return dlopen("libCallKit.dylib", RTLD_NOW | RTLD_NOLOAD) != nil
}

precondition(moduleName(AVAudioSession.self).contains("AVFoundation"))
precondition(!moduleName(AVAudioSession.self).contains("CallKit."))

let session = AVAudioSession.sharedInstance()
let provider = CXProvider(configuration: CXProviderConfiguration())
let probe = AudioSessionDelegateProbe()
let existential: any CXProviderDelegate = probe
provider.setDelegate(existential, queue: nil)

existential.provider(provider, didActivate: session)
existential.provider(provider, didDeactivate: session)
precondition(probe.activated === session)
precondition(probe.deactivated === session)
precondition(moduleName(type(of: probe.activated!)).contains("AVFoundation"))

probe.activated = nil
probe.deactivated = nil
provider._portableDeliverAudioSessionActivation(session)
provider._portableDeliverAudioSessionDeactivation(session)

let deadline = Date().addingTimeInterval(5)
while Date() < deadline, probe.activated == nil || probe.deactivated == nil {
    RunLoop.current.run(until: Date().addingTimeInterval(0.01))
}
precondition(probe.activated === session)
precondition(probe.deactivated === session)
precondition(libCallKitIsLoaded())

print("CALLKIT_DEPENDENCY_IDENTITY_OK")
