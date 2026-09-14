import Foundation
import Intents

func testWave14PersonRelationshipUnlabeledInit() {
    let relationship = INPersonRelationship("friend")
    precondition(relationship.rawValue == "friend")
    precondition(relationship == INPersonRelationship(rawValue: "friend"))
    precondition(INPersonRelationship("friend") != INPersonRelationship("family"))
}

func testWave14RideOptionMeteredFare() {
    let option = INRideOption(name: "Standard", estimatedPickupDate: Date())
    precondition(option.usesMeteredFare == nil)
    option.usesMeteredFare = true
    precondition(option.usesMeteredFare == true)
    option.usesMeteredFare = false
    precondition(option.usesMeteredFare == false)
}

func testWave14SearchCallHistoryUnseen() {
    let intent = INSearchCallHistoryIntent()
    precondition(intent.unseen == nil)
    intent.unseen = true
    precondition(intent.unseen == true)
}

func testWave14PhotoResponseSearchResultsCount() {
    let search = INSearchForPhotosIntentResponse(code: .continueInApp, userActivity: nil)
    precondition(search.searchResultsCount == nil)
    search.searchResultsCount = 7
    precondition(search.searchResultsCount == 7)
    let playback = INStartPhotoPlaybackIntentResponse(code: .continueInApp, userActivity: nil)
    playback.searchResultsCount = 3
    precondition(playback.searchResultsCount == 3)
}

func testWave14CarPowerMinutesToFull() {
    let response = INGetCarPowerLevelStatusIntentResponse(code: .success, userActivity: nil)
    precondition(response.minutesToFull == nil)
    response.minutesToFull = 42
    precondition(response.minutesToFull == 42)
}

func testWave14MediaUserContextLibraryCount() {
    let context = INMediaUserContext()
    precondition(context.numberOfLibraryItems == nil)
    context.numberOfLibraryItems = 128
    precondition(context.numberOfLibraryItems == 128)
}

func testWave14ReservationPartySizes() {
    let ride = INRequestRideIntent()
    precondition(ride.partySize == nil)
    ride.partySize = 2
    precondition(ride.partySize == 2)
    let lodging = INLodgingReservation()
    lodging.numberOfAdults = 2
    lodging.numberOfChildren = 1
    precondition(lodging.numberOfAdults == 2)
    precondition(lodging.numberOfChildren == 1)
    let restaurant = INRestaurantReservation()
    restaurant.partySize = 4
    precondition(restaurant.partySize == 4)
}

func testWave14ObjectCollectionAllItems() {
    let flat = INObjectCollection<String>(items: ["a", "b"])
    precondition(flat.allItems == ["a", "b"])
    let section = INObjectSection<String>(title: "s", items: ["c"])
    let grouped = INObjectCollection<String>(sections: [section])
    precondition(grouped.allItems == ["c"])
}

func testWave14AvailableBareInits() {
    let rideStatus = INGetRideStatusIntent()
    precondition(type(of: rideStatus) == INGetRideStatusIntent.self)
    let listCars = INListCarsIntent()
    precondition(type(of: listCars) == INListCarsIntent.self)
    let mediaContext = INMediaUserContext()
    precondition(mediaContext.subscriptionStatus == nil)
}
