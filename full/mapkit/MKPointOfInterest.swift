import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Linux `MKPointOfInterestCategory` values use the exported C identifier as
/// the string payload. That is not an Apple-oracle NSString observation.
public struct MKPointOfInterestCategory: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // Darwin macOS 26.1 raw values are `MKPOICategory…`, not the C identifier
    // `MKPointOfInterestCategory…` (measured 2026-09-05).
    public static let atm = MKPointOfInterestCategory(rawValue: "MKPOICategoryATM")
    public static let airport = MKPointOfInterestCategory(rawValue: "MKPOICategoryAirport")
    public static let amusementPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryAmusementPark")
    public static let animalService = MKPointOfInterestCategory(rawValue: "MKPOICategoryAnimalService")
    public static let aquarium = MKPointOfInterestCategory(rawValue: "MKPOICategoryAquarium")
    public static let automotiveRepair = MKPointOfInterestCategory(rawValue: "MKPOICategoryAutomotiveRepair")
    public static let bakery = MKPointOfInterestCategory(rawValue: "MKPOICategoryBakery")
    public static let bank = MKPointOfInterestCategory(rawValue: "MKPOICategoryBank")
    public static let baseball = MKPointOfInterestCategory(rawValue: "MKPOICategoryBaseball")
    public static let basketball = MKPointOfInterestCategory(rawValue: "MKPOICategoryBasketball")
    public static let beach = MKPointOfInterestCategory(rawValue: "MKPOICategoryBeach")
    public static let beauty = MKPointOfInterestCategory(rawValue: "MKPOICategoryBeauty")
    public static let bowling = MKPointOfInterestCategory(rawValue: "MKPOICategoryBowling")
    public static let brewery = MKPointOfInterestCategory(rawValue: "MKPOICategoryBrewery")
    public static let cafe = MKPointOfInterestCategory(rawValue: "MKPOICategoryCafe")
    public static let campground = MKPointOfInterestCategory(rawValue: "MKPOICategoryCampground")
    public static let carRental = MKPointOfInterestCategory(rawValue: "MKPOICategoryCarRental")
    public static let castle = MKPointOfInterestCategory(rawValue: "MKPOICategoryCastle")
    public static let conventionCenter = MKPointOfInterestCategory(rawValue: "MKPOICategoryConventionCenter")
    public static let distillery = MKPointOfInterestCategory(rawValue: "MKPOICategoryDistillery")
    public static let evCharger = MKPointOfInterestCategory(rawValue: "MKPOICategoryEVCharger")
    public static let fairground = MKPointOfInterestCategory(rawValue: "MKPOICategoryFairground")
    public static let fireStation = MKPointOfInterestCategory(rawValue: "MKPOICategoryFireStation")
    public static let fishing = MKPointOfInterestCategory(rawValue: "MKPOICategoryFishing")
    public static let fitnessCenter = MKPointOfInterestCategory(rawValue: "MKPOICategoryFitnessCenter")
    public static let foodMarket = MKPointOfInterestCategory(rawValue: "MKPOICategoryFoodMarket")
    public static let fortress = MKPointOfInterestCategory(rawValue: "MKPOICategoryFortress")
    public static let gasStation = MKPointOfInterestCategory(rawValue: "MKPOICategoryGasStation")
    public static let goKart = MKPointOfInterestCategory(rawValue: "MKPOICategoryGoKart")
    public static let golf = MKPointOfInterestCategory(rawValue: "MKPOICategoryGolf")
    public static let hiking = MKPointOfInterestCategory(rawValue: "MKPOICategoryHiking")
    public static let hospital = MKPointOfInterestCategory(rawValue: "MKPOICategoryHospital")
    public static let hotel = MKPointOfInterestCategory(rawValue: "MKPOICategoryHotel")
    public static let kayaking = MKPointOfInterestCategory(rawValue: "MKPOICategoryKayaking")
    public static let landmark = MKPointOfInterestCategory(rawValue: "MKPOICategoryLandmark")
    public static let laundry = MKPointOfInterestCategory(rawValue: "MKPOICategoryLaundry")
    public static let library = MKPointOfInterestCategory(rawValue: "MKPOICategoryLibrary")
    public static let mailbox = MKPointOfInterestCategory(rawValue: "MKPOICategoryMailbox")
    public static let marina = MKPointOfInterestCategory(rawValue: "MKPOICategoryMarina")
    public static let miniGolf = MKPointOfInterestCategory(rawValue: "MKPOICategoryMiniGolf")
    public static let movieTheater = MKPointOfInterestCategory(rawValue: "MKPOICategoryMovieTheater")
    public static let museum = MKPointOfInterestCategory(rawValue: "MKPOICategoryMuseum")
    public static let musicVenue = MKPointOfInterestCategory(rawValue: "MKPOICategoryMusicVenue")
    public static let nationalMonument = MKPointOfInterestCategory(rawValue: "MKPOICategoryNationalMonument")
    public static let nationalPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryNationalPark")
    public static let nightlife = MKPointOfInterestCategory(rawValue: "MKPOICategoryNightlife")
    public static let park = MKPointOfInterestCategory(rawValue: "MKPOICategoryPark")
    public static let parking = MKPointOfInterestCategory(rawValue: "MKPOICategoryParking")
    public static let pharmacy = MKPointOfInterestCategory(rawValue: "MKPOICategoryPharmacy")
    public static let planetarium = MKPointOfInterestCategory(rawValue: "MKPOICategoryPlanetarium")
    public static let police = MKPointOfInterestCategory(rawValue: "MKPOICategoryPolice")
    public static let postOffice = MKPointOfInterestCategory(rawValue: "MKPOICategoryPostOffice")
    public static let publicTransport = MKPointOfInterestCategory(rawValue: "MKPOICategoryPublicTransport")
    public static let rvPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryRVPark")
    public static let restaurant = MKPointOfInterestCategory(rawValue: "MKPOICategoryRestaurant")
    public static let restroom = MKPointOfInterestCategory(rawValue: "MKPOICategoryRestroom")
    public static let rockClimbing = MKPointOfInterestCategory(rawValue: "MKPOICategoryRockClimbing")
    public static let school = MKPointOfInterestCategory(rawValue: "MKPOICategorySchool")
    public static let skatePark = MKPointOfInterestCategory(rawValue: "MKPOICategorySkatePark")
    public static let skating = MKPointOfInterestCategory(rawValue: "MKPOICategorySkating")
    public static let skiing = MKPointOfInterestCategory(rawValue: "MKPOICategorySkiing")
    public static let soccer = MKPointOfInterestCategory(rawValue: "MKPOICategorySoccer")
    public static let spa = MKPointOfInterestCategory(rawValue: "MKPOICategorySpa")
    public static let stadium = MKPointOfInterestCategory(rawValue: "MKPOICategoryStadium")
    public static let store = MKPointOfInterestCategory(rawValue: "MKPOICategoryStore")
    public static let surfing = MKPointOfInterestCategory(rawValue: "MKPOICategorySurfing")
    public static let swimming = MKPointOfInterestCategory(rawValue: "MKPOICategorySwimming")
    public static let tennis = MKPointOfInterestCategory(rawValue: "MKPOICategoryTennis")
    public static let theater = MKPointOfInterestCategory(rawValue: "MKPOICategoryTheater")
    public static let university = MKPointOfInterestCategory(rawValue: "MKPOICategoryUniversity")
    public static let volleyball = MKPointOfInterestCategory(rawValue: "MKPOICategoryVolleyball")
    public static let winery = MKPointOfInterestCategory(rawValue: "MKPOICategoryWinery")
    public static let zoo = MKPointOfInterestCategory(rawValue: "MKPOICategoryZoo")
}

public final class MKPointOfInterestFilter: NSObject, NSCopying {
    private enum Mode {
        case includingAll
        case excludingAll
        case including(Set<MKPointOfInterestCategory>)
        case excluding(Set<MKPointOfInterestCategory>)
    }

    private let mode: Mode

    public static var includingAll: MKPointOfInterestFilter {
        MKPointOfInterestFilter(mode: .includingAll)
    }

    public static var excludingAll: MKPointOfInterestFilter {
        MKPointOfInterestFilter(mode: .excludingAll)
    }

    public init(including categories: [MKPointOfInterestCategory]) {
        mode = .including(Set(categories))
        super.init()
    }

    public init(includingCategories categories: [MKPointOfInterestCategory]) {
        mode = .including(Set(categories))
        super.init()
    }

    public init(excluding categories: [MKPointOfInterestCategory]) {
        mode = .excluding(Set(categories))
        super.init()
    }

    public init(excludingCategories categories: [MKPointOfInterestCategory]) {
        mode = .excluding(Set(categories))
        super.init()
    }

    private init(mode: Mode) {
        self.mode = mode
        super.init()
    }

    public func includes(_ category: MKPointOfInterestCategory) -> Bool {
        switch mode {
        case .includingAll:
            return true
        case .excludingAll:
            return false
        case .including(let included):
            return included.contains(category)
        case .excluding(let excluded):
            return !excluded.contains(category)
        }
    }

    public func excludes(_ category: MKPointOfInterestCategory) -> Bool {
        !includes(category)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MKPointOfInterestFilter(mode: mode)
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}
