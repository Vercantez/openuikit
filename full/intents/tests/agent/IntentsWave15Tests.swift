import Foundation
import Intents

func testWave15IntentParameterImages() {
    let intent = INSearchCallHistoryIntent()
    precondition(intent.image(forParameterNamed: \INIntent.identifier) == nil)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)

    let badge = INImage(named: "wave15-badge")
    intent.setImage(badge, forParameterNamed: \INIntent.identifier)
    precondition(intent.image(forParameterNamed: \INIntent.identifier) === badge)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)

    let flagImage = INImage(named: "wave15-flag")
    intent.setImage(flagImage, forParameterNamed: \INSearchCallHistoryIntent.unseen)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) === flagImage)
    precondition(intent.image(forParameterNamed: \INIntent.identifier) === badge)

    intent.setImage(nil, forParameterNamed: \INIntent.identifier)
    precondition(intent.image(forParameterNamed: \INIntent.identifier) == nil)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) === flagImage)

    let fresh = INSearchCallHistoryIntent()
    precondition(fresh.image(forParameterNamed: \INIntent.identifier) == nil)
    precondition(fresh.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)
}
