import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testRemoveParticipantAlertInit() {
    let person = SharedWithYouHostControl.makePerson(displayName: "Ada")
    let highlight = swSampleCollaboration("remove")
    let alert = SWRemoveParticipantAlertController(
        participant: person,
        highlight: highlight
    )
    let asController: UIViewController = alert
    swRequire(asController === alert, "controller")
    swRequire(alert.participant.displayName == "Ada", "person")
    swRequire(alert.highlight.collaborationIdentifier == highlight.collaborationIdentifier, "hl")
}
