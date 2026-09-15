import Foundation
import ReplayKit

func testReplayKitStringConstants() {
    precondition(RPRecordingErrorDomain == "RPRecordingErrorDomain")
    precondition(!RPRecordingErrorDomain.isEmpty)
    precondition(RPApplicationInfoBundleIdentifierKey == "RPApplicationInfoBundleIdentifierKey")
    precondition(!RPApplicationInfoBundleIdentifierKey.isEmpty)
    precondition(RPVideoSampleOrientationKey == "RPVideoSampleOrientationKey")
    precondition(!RPVideoSampleOrientationKey.isEmpty)
    precondition(SCStreamErrorDomain == "SCStreamErrorDomain")
    precondition(!SCStreamErrorDomain.isEmpty)
    precondition(RPRecordingErrorDomain != SCStreamErrorDomain)
    precondition(RPApplicationInfoBundleIdentifierKey != RPVideoSampleOrientationKey)
    precondition(RPRecordingErrorDomain != RPApplicationInfoBundleIdentifierKey)
    let domains = [RPRecordingErrorDomain, SCStreamErrorDomain]
    precondition(Set(domains).count == 2)
    let keys = [RPApplicationInfoBundleIdentifierKey, RPVideoSampleOrientationKey]
    precondition(Set(keys).count == 2)
}
