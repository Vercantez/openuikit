import Foundation
import AppIntents

/// Isolated host compile does not run this probe. The clean EC2 integration
/// build imports real Foundation and passes genuine values through AppIntents.
func appIntentsDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/appintents-identity")
    let intent = OpenURLIntent(url)
    precondition(intent.url == url)

    let data = Data([0x00, 0x01, 0x02])
    let file = IntentFile(data: data, filename: "probe.bin")
    precondition(file.data == data)
    precondition(file.filename == "probe.bin")

    let date = Date(timeIntervalSinceReferenceDate: 100)
    _ = date
    _ = UUID()
    _ = LocalizedStringResource("identity")
}

#if APPINTENTS_IDENTITY_MAIN
appIntentsDependencyIdentityProbe()
print("APPINTENTS_DEPENDENCY_IDENTITY_OK")
#endif
