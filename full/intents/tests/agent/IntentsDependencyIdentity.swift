import Foundation
import Intents

#if false
import Foundation
#endif

/// Isolated host compile does not run this probe. The clean EC2 integration
/// build imports real Foundation and passes genuine values through Intents.
func intentsDependencyIdentityProbe() {
    let phrase = "Erase"
    let intent = INIntent()
    intent.suggestedInvocationPhrase = phrase
    precondition(intent.suggestedInvocationPhrase == phrase)

    let activity = NSUserActivity(activityType: "com.openuikit.intents.identity")
    activity.suggestedInvocationPhrase = phrase
    precondition(activity.suggestedInvocationPhrase == phrase)

    let response = INIntentResponse()
    response.userActivity = activity
    precondition(response.userActivity === activity)

    let data = Data([0x00, 0x01, 0x02])
    let image = INImage(imageData: data)
    precondition(image.imageData == data)

    let url = URL(fileURLWithPath: "/tmp/intents-identity")
    precondition(INImage(url: url) != nil)

    _ = UUID()
    _ = Date()
}

#if INTENTS_IDENTITY_MAIN
intentsDependencyIdentityProbe()
print("INTENTS_DEPENDENCY_IDENTITY_OK")
#endif
