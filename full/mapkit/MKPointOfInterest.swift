import Foundation

/// Linux `MKPointOfInterestCategory` values use the exported C identifier as
/// the string payload. That is not an Apple-oracle NSString observation.
public struct MKPointOfInterestCategory: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let atm = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryATM")
    public static let airport = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryAirport")
    public static let amusementPark = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryAmusementPark")
    public static let animalService = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryAnimalService")
    public static let aquarium = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryAquarium")
    public static let automotiveRepair = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryAutomotiveRepair")
    public static let bakery = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBakery")
    public static let bank = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBank")
    public static let baseball = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBaseball")
    public static let basketball = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBasketball")
    public static let beach = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBeach")
    public static let beauty = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBeauty")
    public static let bowling = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBowling")
    public static let brewery = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryBrewery")
    public static let cafe = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryCafe")
    public static let campground = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryCampground")
    public static let carRental = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryCarRental")
    public static let castle = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryCastle")
    public static let conventionCenter = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryConventionCenter")
    public static let distillery = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryDistillery")
    public static let evCharger = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryEVCharger")
    public static let fairground = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFairground")
    public static let fireStation = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFireStation")
    public static let fishing = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFishing")
    public static let fitnessCenter = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFitnessCenter")
    public static let foodMarket = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFoodMarket")
    public static let fortress = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryFortress")
    public static let gasStation = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryGasStation")
    public static let goKart = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryGoKart")
    public static let golf = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryGolf")
    public static let hiking = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryHiking")
    public static let hospital = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryHospital")
    public static let hotel = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryHotel")
    public static let kayaking = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryKayaking")
    public static let landmark = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryLandmark")
    public static let laundry = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryLaundry")
    public static let library = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryLibrary")
    public static let mailbox = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMailbox")
    public static let marina = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMarina")
    public static let miniGolf = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMiniGolf")
    public static let movieTheater = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMovieTheater")
    public static let museum = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMuseum")
    public static let musicVenue = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryMusicVenue")
    public static let nationalMonument = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryNationalMonument")
    public static let nationalPark = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryNationalPark")
    public static let nightlife = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryNightlife")
    public static let park = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPark")
    public static let parking = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryParking")
    public static let pharmacy = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPharmacy")
    public static let planetarium = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPlanetarium")
    public static let police = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPolice")
    public static let postOffice = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPostOffice")
    public static let publicTransport = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryPublicTransport")
    public static let rvPark = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryRVPark")
    public static let restaurant = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryRestaurant")
    public static let restroom = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryRestroom")
    public static let rockClimbing = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryRockClimbing")
    public static let school = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySchool")
    public static let skatePark = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySkatePark")
    public static let skating = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySkating")
    public static let skiing = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySkiing")
    public static let soccer = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySoccer")
    public static let spa = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySpa")
    public static let stadium = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryStadium")
    public static let store = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryStore")
    public static let surfing = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySurfing")
    public static let swimming = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategorySwimming")
    public static let tennis = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryTennis")
    public static let theater = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryTheater")
    public static let university = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryUniversity")
    public static let volleyball = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryVolleyball")
    public static let winery = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryWinery")
    public static let zoo = MKPointOfInterestCategory(rawValue: "MKPointOfInterestCategoryZoo")
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
}
