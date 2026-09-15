import Foundation
import Intents

func testWave15IntentParameterImages() {
    let intent = INSearchCallHistoryIntent()
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)

    let base: INIntent = intent
    precondition(base.image(forParameterNamed: \INIntent.identifier) == nil)

    let badge = INImage(named: "wave15-badge")
    base.setImage(badge, forParameterNamed: \INIntent.identifier)
    precondition(base.image(forParameterNamed: \INIntent.identifier) === badge)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)

    let flagImage = INImage(named: "wave15-flag")
    intent.setImage(flagImage, forParameterNamed: \INSearchCallHistoryIntent.unseen)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) === flagImage)
    precondition(base.image(forParameterNamed: \INIntent.identifier) === badge)

    base.setImage(nil, forParameterNamed: \INIntent.identifier)
    precondition(base.image(forParameterNamed: \INIntent.identifier) == nil)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) === flagImage)

    let fresh = INSearchCallHistoryIntent()
    precondition(fresh.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) == nil)
    precondition((fresh as INIntent).image(forParameterNamed: \INIntent.identifier) == nil)
}

func testWave15IntentSetImageKeyPathConformances() {
    let intent = INSearchCallHistoryIntent()
    let keyed: any INIntentSetImageKeyPath = intent
    precondition((keyed as? INSearchCallHistoryIntent) === intent)

    let base = INIntent()
    let baseKeyed: any INIntentSetImageKeyPath = base
    precondition((baseKeyed as? INIntent) === base)

    let mark = INImage(named: "wave15-keypath-mark")
    intent.setImage(mark, forParameterNamed: \INSearchCallHistoryIntent.unseen)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen) === mark)
    precondition(intent.image(forParameterNamed: \INSearchCallHistoryIntent.unseen)?.namedImage == "wave15-keypath-mark")
    precondition(base.image(forParameterNamed: \INIntent.identifier) == nil)
}
